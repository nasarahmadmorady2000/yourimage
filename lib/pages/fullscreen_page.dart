import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:photo_manager/photo_manager.dart';

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

  double _progress = 0.0;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    requestGalleryPermission();
  }

  Future<void> requestGalleryPermission() async {
    await PhotoManager.requestPermissionExtend();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int get _currentImageId => widget.imageIds[_currentIndex];

  // =========================
  // 🚀 DIO DOWNLOAD SYSTEM
  // =========================
  Future<void> _downloadImage(int id) async {
    try {
      setState(() {
        _isDownloading = true;
        _progress = 0.0;
      });

      final dio = Dio();

      final response = await dio.get(
        widget.imageUrl(id),
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progress = received / total;
            });
          }
        },
      );

      final Uint8List bytes = Uint8List.fromList(response.data);

      final asset = await PhotoManager.editor.saveImage(
        bytes,
        filename: "MyApp_Images_$id.jpg",
      );

      setState(() {
        _isDownloading = false;
        _progress = 0.0;
      });

      if (asset != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Saved to Gallery")));
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _progress = 0.0;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Download failed: $e")));
      }
    }
  }

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
          ),

          // 📊 PROGRESS BAR (ONLY WHEN DOWNLOADING)
          if (_isDownloading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: SizedBox(
                width: 80,
                child: LinearProgressIndicator(value: _progress),
              ),
            ),

          // ⬇ DOWNLOAD BUTTON
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _isDownloading
                ? null
                : () => _downloadImage(_currentImageId),
          ),

          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => widget.onShare(_currentImageId),
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
                minScale: 1,
                maxScale: 5,
                child: Image.network(
                  widget.imageUrl(id),
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
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
