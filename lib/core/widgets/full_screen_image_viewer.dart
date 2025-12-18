import 'package:bidbird/core/managers/item_image_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 전체 화면 이미지 뷰어
class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
  });

  static void show(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            FullScreenImageViewer(imageUrl: imageUrl),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            cacheManager: ItemImageCacheManager.instance,
            fit: BoxFit.contain,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            errorWidget: (context, url, error) => const Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
