import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'widgets/image_card.dart';
import '../../pages/favorites_page.dart';
import '../../pages/fullscreen_page.dart';

const String kFavoritesEndpoint = 'http://localhost:3000/api/favorites';
const String kCacheKeyImages = 'cached_image_ids';
const String kCacheKeyFavorites = 'cached_favorites';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<int> _imageIds = [];
  final Set<int> _favorites = {};
  final Set<int> _brokenImages = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  // =========================
  // INIT
  // =========================
  Future<void> _initApp() async {
    await _loadCache();
    setState(() => _isLoading = false);
  }

  Future<void> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();

    final cachedImages = prefs.getStringList(kCacheKeyImages);
    _imageIds = cachedImages?.map(int.parse).toList() ?? _generateRandomIds();

    final cachedFav = prefs.getStringList(kCacheKeyFavorites);
    if (cachedFav != null) {
      _favorites.addAll(cachedFav.map(int.parse));
    }
  }

  List<int> _generateRandomIds([int count = 30]) {
    final set = <int>{};
    final rand = Random();

    while (set.length < count) {
      set.add(rand.nextInt(1000) + 1);
    }
    return set.toList();
  }

  String imageUrl(int id) => 'https://picsum.photos/id/$id/600/600';

  // =========================
  // BROKEN IMAGE HANDLING
  // =========================
  void _markImageBroken(int id) {
    if (_brokenImages.contains(id)) return;

    setState(() {
      _brokenImages.add(id);
    });

    _saveCache();
  }

  // =========================
  // CACHE
  // =========================
  Future<void> _saveCache() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      kCacheKeyImages,
      _imageIds.map((e) => e.toString()).toList(),
    );

    await prefs.setStringList(
      kCacheKeyFavorites,
      _favorites.map((e) => e.toString()).toList(),
    );

    unawaited(_syncFavoritesToServer());
  }

  Future<void> _refreshImages() async {
    setState(() {
      _imageIds = _generateRandomIds();
      _brokenImages.clear();
    });

    await _saveCache();
  }

  // =========================
  // FAVORITES
  // =========================
  void _toggleFavorite(int id) {
    setState(() {
      if (_favorites.contains(id)) {
        _favorites.remove(id);
      } else {
        _favorites.add(id);
      }
    });

    _saveCache();
  }

  // =========================
  // SHARE
  // =========================
  Future<void> _shareImage(int id) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/image_$id.jpg');

    if (!await file.exists()) {
      final res = await http.get(Uri.parse(imageUrl(id)));
      await file.writeAsBytes(res.bodyBytes);
    }

    await Share.shareXFiles([XFile(file.path)]);
  }

  // =========================
  // SERVER SYNC
  // =========================
  Future<void> _syncFavoritesToServer() async {
    try {
      await http.post(
        Uri.parse(kFavoritesEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'favorites': _favorites.toList()}),
      );
    } catch (_) {}
  }

  // =========================
  // NAVIGATION
  // =========================
  void _openFullScreen(int id, {List<int>? imageIds}) {
    final ids = (imageIds ?? _imageIds)
        .where((id) => !_brokenImages.contains(id))
        .toList();
    final index = ids.indexOf(id);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImageFullscreenPage(
          imageIds: ids,
          initialIndex: index,
          imageUrl: imageUrl,
          isFavorite: (i) => _favorites.contains(i),
          onToggleFavorite: _toggleFavorite,
          onDownload: (_) async {},
          onShare: _shareImage,
        ),
      ),
    );
  }

  void _openFavorites() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FavoritesPage(
          favoriteIds: _imageIds
              .where(_favorites.contains)
              .where((id) => !_brokenImages.contains(id))
              .toList(),
          imageUrl: imageUrl,
          favorites: _favorites,
          onToggleFavorite: _toggleFavorite,
          onDownload: (_) async {},
          onShare: _shareImage,
          onOpenFullScreen: (id, ids) {
            _openFullScreen(id, imageIds: ids);
          },
        ),
      ),
    );
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: _openFavorites,
            icon: const Icon(Icons.favorite),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _refreshImages,
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _imageIds.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final id = _imageIds[index];

            // ❌ skip broken images safely
            if (_brokenImages.contains(id)) {
              return const SizedBox.shrink();
            }

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _openFullScreen(id),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: ImageCard(
                  id: id,
                  imageUrl: imageUrl,
                  isFavorite: _favorites.contains(id),
                  isDownloading: false,
                  onDownload: (_) async {},
                  onToggleFavorite: _toggleFavorite,
                  onShare: _shareImage,

                  // ✅ IMPORTANT CONNECTION
                  onImageFailed: _markImageBroken,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
