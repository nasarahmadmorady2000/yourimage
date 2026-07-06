import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

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
  bool _isProcessing = false;

  // ✅ PLATFORM CHANNEL (Flutter → Android)
  static const MethodChannel _wallpaperChannel = MethodChannel(
    'com.imagesapp.wallpaper',
  );

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

  // =========================
  // IMAGE DOWNLOAD (TEMP FILE)
  // =========================
  Future<File> _downloadToTempFile(int id) async {
    final dio = Dio();

    final response = await dio.get(
      widget.imageUrl(id),
      options: Options(responseType: ResponseType.bytes),
      onReceiveProgress: (received, total) {
        if (total != -1 && mounted) {
          setState(() {
            _progress = received / total;
          });
        }
      },
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/wallpaper_$id.jpg');

    await file.writeAsBytes(Uint8List.fromList(response.data));

    return file;
  }

  // =========================
  // WALLPAPER APPLY (ANDROID)
  // =========================
  Future<void> _applyWallpaper(int id, String type) async {
    try {
      setState(() {
        _isProcessing = true;
        _progress = 0;
      });

      final file = await _downloadToTempFile(id);

      await _wallpaperChannel.invokeMethod('setWallpaper', {
        'imagePath': file.path,
        'type': type, // home / lock / both
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Wallpaper applied ($type screen)")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _progress = 0;
        });
      }
    }
  }

  // =========================
  // WALLPAPER OPTIONS SHEET
  // =========================
  void _showWallpaperOptions(int id) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home Screen"),
              onTap: () {
                Navigator.pop(context);
                _applyWallpaper(id, "home");
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text("Lock Screen"),
              onTap: () {
                Navigator.pop(context);
                _applyWallpaper(id, "lock");
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone_android),
              title: const Text("Both"),
              onTap: () {
                Navigator.pop(context);
                _applyWallpaper(id, "both");
              },
            ),
          ],
        );
      },
    );
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Image Viewer"),
        actions: [
          IconButton(
            icon: Icon(
              widget.isFavorite(_currentImageId)
                  ? Icons.favorite
                  : Icons.favorite_border,
            ),
            onPressed: () {
              widget.onToggleFavorite(_currentImageId);
              setState(() {});
            },
          ),

          // 📊 progress
          if (_isProcessing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: SizedBox(
                width: 80,
                child: LinearProgressIndicator(value: _progress),
              ),
            ),

          // ⬇ wallpaper button
          IconButton(
            icon: const Icon(Icons.wallpaper),
            onPressed: _isProcessing
                ? null
                : () => _showWallpaperOptions(_currentImageId),
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
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (context, index) {
          final id = widget.imageIds[index];

          return Center(
            child: Hero(
              tag: 'image_$id',
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Image.network(widget.imageUrl(id), fit: BoxFit.contain),
              ),
            ),
          );
        },
      ),
    );
  }
}
