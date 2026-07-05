import 'package:flutter/material.dart';

import '../widgets/image_card.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({
    super.key,
    required this.favoriteIds,
    required this.imageUrl,
    required this.favorites,
    required this.onToggleFavorite,
    required this.onDownload,
    required this.onShare,
    required this.onOpenFullScreen,
  });

  final List<int> favoriteIds;
  final String Function(int) imageUrl;
  final Set<int> favorites;
  final void Function(int) onToggleFavorite;
  final Future<void> Function(int) onDownload;
  final Future<void> Function(int) onShare;
  final void Function(int, {List<int>? imageIds}) onOpenFullScreen;

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late List<int> _favoriteIds;

  @override
  void initState() {
    super.initState();
    _favoriteIds = List<int>.from(widget.favoriteIds);
  }

  void _removeFavorite(int id) {
    widget.onToggleFavorite(id);

    setState(() {
      _favoriteIds.remove(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: _favoriteIds.isEmpty
          ? const Center(child: Text('No favorites yet.'))
          : GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: _favoriteIds.length,
              itemBuilder: (context, index) {
                final id = _favoriteIds[index];

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () =>
                      widget.onOpenFullScreen(id, imageIds: _favoriteIds),
                  child: ImageCard(
                    id: id,
                    imageUrl: widget.imageUrl,
                    isFavorite: widget.favorites.contains(id),
                    isDownloading: false,
                    onDownload: widget.onDownload,
                    onToggleFavorite: _removeFavorite,
                    onShare: widget.onShare,
                  ),
                );
              },
            ),
    );
  }
}
