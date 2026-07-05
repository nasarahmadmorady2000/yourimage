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
    final rand = Random();

    while (ids.length < count) {
      ids.add(rand.nextInt(1000) + 1);
    }

    _imageIds = ids.toList();
  }

  Future<void> _refreshImages() async {
    final ids = <int>{};
    final rand = Random();

    while (ids.length < 30) {
      ids.add(rand.nextInt(1000) + 1);
    }

    setState(() {
      _imageIds = ids.toList();
    });
  }

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

  String imageUrl(int id) => 'https://picsum.photos/id/$id/600/600';

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
          onDownload: (_) async {},
          onShare: _shareImage,
          onOpenFullScreen: _openFullScreen,
        ),
      ),
    );
  }

  void _openFullScreen(int id, {List<int>? imageIds}) {
    final ids = imageIds ?? _imageIds;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImageFullscreenPage(
          imageIds: ids,
          initialIndex: ids.indexOf(id),
          imageUrl: imageUrl,
          isFavorite: (id) => _favorites.contains(id),
          onToggleFavorite: _toggleFavorite,
          onDownload: (_) async {},
          onShare: _shareImage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Favorites',
            onPressed: _openFavorites,
            icon: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.favorite),
                if (_favorites.isNotEmpty)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: _imageIds.length,
          itemBuilder: (context, index) {
            final id = _imageIds[index];

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _openFullScreen(id),
              child: ImageCard(
                id: id,
                imageUrl: imageUrl,
                isFavorite: _favorites.contains(id),
                isDownloading: false,
                onDownload: (_) async {},
                onToggleFavorite: _toggleFavorite,
                onShare: _shareImage,
              ),
            );
          },
        ),
      ),
    );
  }
}
