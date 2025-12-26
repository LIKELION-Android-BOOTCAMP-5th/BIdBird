import 'package:bidbird/core/managers/item_image_cache_manager.dart';
import 'package:bidbird/core/utils/item/item_media_utils.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 고정 비율 썸네일 위젯
/// 세로로 긴 이미지 문제를 해결하기 위한 공통 컴포넌트
class FixedRatioThumbnail extends StatelessWidget {
  const FixedRatioThumbnail({
    super.key,
    required this.imageUrl,
    this.aspectRatio = 1.0,
    this.borderRadius,
    this.width,
    this.height,
    this.showVerticalIndicator = false,
    this.onTap,
    this.overlay,
  });

  /// 이미지 URL
  final String? imageUrl;

  /// 썸네일 비율 (기본값: 1:1)
  final double aspectRatio;

  /// 모서리 둥글기
  final BorderRadius? borderRadius;

  /// 고정 너비 (null이면 aspectRatio에 따라 계산)
  final double? width;

  /// 고정 높이 (null이면 aspectRatio에 따라 계산)
  final double? height;

  /// 세로 이미지일 때 하단 그라데이션 표시 여부
  final bool showVerticalIndicator;

  /// 탭 콜백
  final VoidCallback? onTap;

  /// 오버레이 위젯 (상태 배지, 정보 등)
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final bool isVideo = imageUrl != null && isVideoFile(imageUrl!);
    final String? displayUrl = isVideo && imageUrl != null
      ? getVideoThumbnailUrl(imageUrl!)
      : imageUrl;

    final defaultBorderRadius = borderRadius ?? BorderRadius.circular(8);

    Widget imageWidget = Container(
      decoration: BoxDecoration(
        color: ImageBackgroundColor,
        borderRadius: defaultBorderRadius,
      ),
      clipBehavior: Clip.hardEdge,
      child: displayUrl != null && displayUrl.isNotEmpty
          ? Stack(
              children: [
                // 이미지
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final dpr = MediaQuery.of(context).devicePixelRatio;
                      final memWidth = (constraints.maxWidth.isFinite
                              ? constraints.maxWidth * dpr
                              : 0)
                          .round();
                      final memHeight = (constraints.maxHeight.isFinite
                              ? constraints.maxHeight * dpr
                              : 0)
                          .round();

                      // 서버 사이즈 변환(Cloudinary) + 디코드 다운스케일 동시 적용
                      final transformedUrl = resizeCloudinaryUrl(
                        displayUrl,
                        width: memWidth > 0 ? memWidth : null,
                        height: memHeight > 0 ? memHeight : null,
                        cropFill: true,
                      );

                      return CachedNetworkImage(
                        imageUrl: transformedUrl,
                        cacheManager: ItemImageCacheManager.instance,
                        fit: BoxFit.cover, // center crop
                        memCacheWidth: memWidth > 0 ? memWidth : null,
                        memCacheHeight: memHeight > 0 ? memHeight : null,
                        placeholder: (context, url) => Container(color: shadowHigh),
                        errorWidget: (context, url, error) => Container(
                          color: ImageBackgroundColor,
                          child: const Icon(
                            Icons.image_outlined,
                            color: iconColor,
                            size: 32,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // 세로 이미지 하단 그라데이션 (선택적)
                if (showVerticalIndicator)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                // 커스텀 오버레이
                if (overlay != null) Positioned.fill(child: overlay!),
              ],
            )
          : Container(
              color: ImageBackgroundColor,
              child: const Icon(
                Icons.image_outlined,
                color: iconColor,
                size: 32,
              ),
            ),
    );

    // 크기 지정
    if (width != null && height != null) {
      imageWidget = SizedBox(width: width, height: height, child: imageWidget);
    } else if (width != null) {
      final w = width!;
      imageWidget = SizedBox(
        width: w,
        height: w / aspectRatio,
        child: imageWidget,
      );
    } else if (height != null) {
      final h = height!;
      imageWidget = SizedBox(
        width: h * aspectRatio,
        height: h,
        child: imageWidget,
      );
    } else {
      imageWidget = AspectRatio(aspectRatio: aspectRatio, child: imageWidget);
    }

    // 탭 핸들러
    if (onTap != null) {
      imageWidget = GestureDetector(onTap: onTap, child: imageWidget);
    }

    return imageWidget;
  }
}
