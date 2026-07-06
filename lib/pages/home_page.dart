import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/image_card.dart';
import 'favorites_page.dart';
import 'fullscreen_page.dart';

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
  late List<int> _imageIds = [];
  final Set<int> _favorites = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  /// 🚀 FAST INIT: load cache first, then optionally refresh
  Future<void> _initApp() async {
    await _loadCache();
    _isLoading = false;
    setState(() {});
  }

  /// 💾 LOAD FROM LOCAL CACHE (NO NETWORK)
  Future<void> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();

    // cached images
    final cachedImages = prefs.getStringList(kCacheKeyImages);
    if (cachedImages != null && cachedImages.isNotEmpty) {
      _imageIds = cachedImages.map(int.parse).toList();
    } else {
      _imageIds = _generateRandomIds();
      await prefs.setStringList(
        kCacheKeyImages,
        _imageIds.map((e) => e.toString()).toList(),
      );
    }

    // cached favorites
    final cachedFav = prefs.getStringList(kCacheKeyFavorites);
    if (cachedFav != null) {
      _favorites.addAll(cachedFav.map(int.parse));
    }
  }

  /// 🎲 FAST ID GENERATOR
  List<int> _generateRandomIds([int count = 30]) {
    final set = <int>{};
    final rand = Random();

    while (set.length < count) {
      set.add(rand.nextInt(1000) + 1);
    }
    return set.toList();
  }

  String imageUrl(int id) => 'https://picsum.photos/id/$id/600/600';

  /// 💾 SAVE CACHE (LOCAL ONLY — FAST)
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

    // async server sync (NO UI BLOCK)
    unawaited(_syncFavoritesToServer());
  }

  Future<void> _refreshImages() async {
    _imageIds = _generateRandomIds();

    await _saveCache();
    setState(() {});
  }

  /// ❤️ FAVORITES
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

  /// 📤 SHARE IMAGE (OPTIMIZED)
  Future<void> _shareImage(int id) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/image_$id.jpg');

    if (!await file.exists()) {
      final res = await http.get(Uri.parse(imageUrl(id)));
      await file.writeAsBytes(res.bodyBytes);
    }

    await Share.shareXFiles([XFile(file.path)], text: 'Check this image');
  }

  /// 🌐 SERVER SYNC (NON-BLOCKING)
  Future<void> _syncFavoritesToServer() async {
    try {
      await http.post(
        Uri.parse(kFavoritesEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'favorites': _favorites.toList()}),
      );
    } catch (_) {}
  }

  void _openFullScreen(int id, {List<int>? imageIds}) {
    final ids = imageIds ?? _imageIds;
    final index = ids.indexOf(id);

    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => ImageFullscreenPage(
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
          favoriteIds: _imageIds.where(_favorites.contains).toList(),
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

            return GestureDetector(
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
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
