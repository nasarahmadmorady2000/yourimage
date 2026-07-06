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

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late List<int> _imageIds;

  final Set<int> _favorites = {};

  @override
  void initState() {
    super.initState();
    _generateRandomImagesSync();
    _loadFavorites();
  }

  void _generateRandomImagesSync([int count = 30]) {
    final ids = <int>{};
    final random = Random();

    while (ids.length < count) {
      ids.add(random.nextInt(1000) + 1);
    }

    _imageIds = ids.toList();
  }

  Future<void> _refreshImages() async {
    final ids = <int>{};
    final random = Random();

    while (ids.length < 30) {
      ids.add(random.nextInt(1000) + 1);
    }

    setState(() {
      _imageIds = ids.toList();
    });
  }

  String imageUrl(int id) => 'https://picsum.photos/id/$id/600/600';

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final list = prefs.getStringList('favorites') ?? <String>[];

      setState(() {
        _favorites
          ..clear()
          ..addAll(list.map((e) => int.tryParse(e)).whereType<int>());
      });

      final serverFavorites = await _fetchFavoritesFromServer();

      if (serverFavorites.isNotEmpty) {
        setState(() {
          _favorites.addAll(serverFavorites);
        });

        await _saveFavorites();
      }
    } catch (_) {}
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setStringList(
        'favorites',
        _favorites.map((e) => e.toString()).toList(),
      );

      unawaited(_syncFavoritesToServer());
    } catch (_) {}
  }

  Future<List<int>> _fetchFavoritesFromServer() async {
    try {
      final response = await http.get(Uri.parse(kFavoritesEndpoint));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map && data['favorites'] is List) {
          return (data['favorites'] as List)
              .map((e) => int.tryParse(e.toString()))
              .whereType<int>()
              .toList();
        }
      }
    } catch (_) {}

    return [];
  }

  Future<void> _syncFavoritesToServer() async {
    try {
      await http.post(
        Uri.parse(kFavoritesEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'favorites': _favorites.toList()}),
      );
    } catch (_) {}
  }

  Future<void> _shareImage(int id) async {
    final directory = await getApplicationDocumentsDirectory();

    final file = File('${directory.path}/image_$id.jpg');

    if (!await file.exists()) {
      final response = await http.get(Uri.parse(imageUrl(id)));

      await file.writeAsBytes(response.bodyBytes);
    }

    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Check out this image from Picsum');
  }

  Future<void> _downloadImage(int id) async {
    // Download removed.
  }

  void _toggleFavorite(int id) {
    setState(() {
      if (_favorites.contains(id)) {
        _favorites.remove(id);
      } else {
        _favorites.add(id);
      }
    });

    _saveFavorites();
  }

  void _openFavorites() {
    final favoriteIds = _imageIds.where(_favorites.contains).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FavoritesPage(
          favoriteIds: favoriteIds,
          imageUrl: imageUrl,
          favorites: _favorites,
          onToggleFavorite: _toggleFavorite,
          onDownload: _downloadImage,
          onShare: _shareImage,
          onOpenFullScreen: _openFullScreen,
        ),
      ),
    );
  }

  void _openFullScreen(int id, {List<int>? imageIds}) {
    final ids = imageIds ?? _imageIds;
    final initialIndex = ids.indexOf(id);

    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, animation, secondaryAnimation) {
          return ImageFullscreenPage(
            imageIds: ids,
            initialIndex: initialIndex,
            imageUrl: imageUrl,
            isFavorite: (imageId) => _favorites.contains(imageId),
            onToggleFavorite: _toggleFavorite,
            onDownload: _downloadImage,
            onShare: _shareImage,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          );

          final scale = Tween<double>(begin: 0.95, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          );

          return FadeTransition(
            opacity: fade,
            child: ScaleTransition(scale: scale, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Favorites',
            onPressed: _openFavorites,
            icon: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.favorite, color: Colors.white),
                if (_favorites.isNotEmpty)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${_favorites.length}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshImages,
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
          physics: const AlwaysScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemCount: _imageIds.length,
          itemBuilder: (context, index) {
            final id = _imageIds[index];

            return GestureDetector(
              onTap: () => _openFullScreen(id),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: ImageCard(
                    id: id,
                    imageUrl: imageUrl,
                    isFavorite: _favorites.contains(id),
                    isDownloading: false,
                    onDownload: _downloadImage,
                    onToggleFavorite: _toggleFavorite,
                    onShare: _shareImage,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
