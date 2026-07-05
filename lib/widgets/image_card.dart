import 'package:flutter/material.dart';

typedef ImageUrlBuilder = String Function(int id);
typedef ImageActionCallback = void Function(int id);
typedef ImageAsyncActionCallback = Future<void> Function(int id);

class ImageCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Hero(
                    tag: 'image_$id',
                    child: Image.network(
                      imageUrl(id),
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.broken_image, size: 48),
                        );
                      },
                    ),
                  ),
                ),

                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.black54,
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.redAccent : Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: isDownloading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download),
                  onPressed: isDownloading ? null : () => onDownload(id),
                  tooltip: 'Download',
                ),

                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.redAccent : null,
                  ),
                  onPressed: () => onToggleFavorite(id),
                  tooltip: 'Favorite',
                ),

                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => onShare(id),
                  tooltip: 'Share',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
