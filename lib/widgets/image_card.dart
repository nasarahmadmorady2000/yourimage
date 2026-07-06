import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

typedef ImageUrlBuilder = String Function(int id);
typedef ImageActionCallback = void Function(int id);
typedef ImageAsyncActionCallback = Future<void> Function(int id);

class ImageCard extends StatefulWidget {
  const ImageCard({
    super.key,
    required this.id,
    required this.imageUrl,
    required this.isFavorite,
    required this.isDownloading,
    required this.onDownload,
    required this.onToggleFavorite,
    required this.onShare,
  });

  final int id;
  final ImageUrlBuilder imageUrl;
  final bool isFavorite;
  final bool isDownloading;
  final ImageAsyncActionCallback onDownload;
  final ImageActionCallback onToggleFavorite;
  final ImageAsyncActionCallback onShare;

  @override
  State<ImageCard> createState() => _ImageCardState();
}

class _ImageCardState extends State<ImageCard> {
  bool _showHeart = false;

  void _onDoubleTap() {
    widget.onToggleFavorite(widget.id);

    setState(() => _showHeart = true);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _onDoubleTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // IMAGE (FULL COVER - NO WHITE SPACE)
            Hero(
              tag: 'image_${widget.id}',
              child: Image.network(
                widget.imageUrl(widget.id),
                fit: BoxFit.cover, // IMPORTANT
                alignment: Alignment.center,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;

                  return Shimmer.fromColors(
                    baseColor: Colors.grey.shade800,
                    highlightColor: Colors.grey.shade600,
                    child: Container(color: Colors.grey),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.broken_image, size: 48),
                  );
                },
              ),
            ),

            // HEART ANIMATION
            Center(
              child: AnimatedOpacity(
                opacity: _showHeart ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(
                  Icons.favorite,
                  size: 90,
                  color: Colors.redAccent,
                ),
              ),
            ),

            // FAVORITE ICON TOP RIGHT
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.black54,
                child: Icon(
                  widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: widget.isFavorite ? Colors.redAccent : Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
