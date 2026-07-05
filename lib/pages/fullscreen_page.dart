import 'package:flutter/material.dart';

class ImageFullscreenPage extends StatefulWidget {
  const ImageFullscreenPage({
    super.key,
    required this.imageIds,
    required this.initialIndex,
    required this.imageUrl,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onDownload,
    required this.onShare,
  });

  final List<int> imageIds;
  final int initialIndex;
  final String Function(int) imageUrl;
  final bool Function(int) isFavorite;
  final void Function(int) onToggleFavorite;
  final Future<void> Function(int) onDownload;
  final Future<void> Function(int) onShare;

  @override
  State<ImageFullscreenPage> createState() => _ImageFullscreenPageState();
}

class _ImageFullscreenPageState extends State<ImageFullscreenPage> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int get _currentImageId => widget.imageIds[_currentIndex];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Viewer'),
        actions: [
          IconButton(
            icon: Icon(
              widget.isFavorite(_currentImageId)
                  ? Icons.favorite
                  : Icons.favorite_border,
            ),
            color: widget.isFavorite(_currentImageId) ? Colors.redAccent : null,
            onPressed: () {
              setState(() {
                widget.onToggleFavorite(_currentImageId);
              });
            },
            tooltip: 'Favorite',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => widget.onDownload(_currentImageId),
            tooltip: 'Download',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => widget.onShare(_currentImageId),
            tooltip: 'Share',
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageIds.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final id = widget.imageIds[index];

          return Center(
            child: Hero(
              tag: 'image_$id',
              child: InteractiveViewer(
                child: Image.network(
                  widget.imageUrl(id),
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;

                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.broken_image, size: 72),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
