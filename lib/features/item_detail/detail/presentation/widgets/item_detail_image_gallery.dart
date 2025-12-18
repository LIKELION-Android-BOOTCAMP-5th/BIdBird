import 'dart:async';

import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/managers/item_image_cache_manager.dart';
import 'package:bidbird/core/widgets/item/dialogs/full_screen_image_gallery_viewer.dart';
import 'package:bidbird/core/widgets/full_screen_video_viewer.dart';
import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart';
import 'package:bidbird/core/utils/item/trade_status_codes.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:bidbird/core/utils/item/item_time_utils.dart';
import 'package:bidbird/core/utils/item/item_media_utils.dart';

class ItemDetailImageGallery extends StatefulWidget {
  const ItemDetailImageGallery({required this.item, super.key});

  final ItemDetail item;

  @override
  State<ItemDetailImageGallery> createState() => _ItemDetailImageGalleryState();
}

class _ItemDetailImageGalleryState extends State<ItemDetailImageGallery> with WidgetsBindingObserver {
  int _currentPage = 0;
  final PageController _pageController = PageController();
  Timer? _timer;
  bool _isAppInForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _isAppInForeground = true;
      _startTimer();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _isAppInForeground = false;
      _stopTimer();
    }
  }

  void _startTimer() {
    _stopTimer(); // 기존 타이머가 있으면 정리
    if (DateTime.now().isAfter(widget.item.finishTime)) {
      return; // 이미 종료된 경우 타이머 시작 안 함
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isAppInForeground) {
        timer.cancel();
        return;
      }
      if (DateTime.now().isAfter(widget.item.finishTime)) {
        timer.cancel();
      }
      setState(() {});
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasImages = widget.item.itemImages.isNotEmpty;
    final images = hasImages ? widget.item.itemImages : <String>[];
    final screenWidth = MediaQuery.of(context).size.width;
    final topPadding = MediaQuery.of(context).padding.top;
    final appBarHeight = 56.0;
    final imageHeight = screenWidth + topPadding + appBarHeight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 이미지가 AppBar 아래까지 확장되도록 높이 조정
        SizedBox(
          height: imageHeight,
          child: Stack(
            children: [
              // 이미지 영역 - AppBar 포함 전체 영역
              Positioned.fill(
                child: hasImages && images.isNotEmpty
                    ? PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          final imageUrl = images[index];
                          final bool isVideo = isVideoFile(imageUrl);
                          final thumbnailUrl = isVideo ? getVideoThumbnailUrl(imageUrl) : imageUrl;

                          return GestureDetector(
                            onTap: () {
                              if (isVideo) {
                                FullScreenVideoViewer.show(context, imageUrl);
                              } else {
                                final imageOnlyUrls = images
                                    .where((url) => !isVideoFile(url))
                                    .toList();
                                final imageIndex = imageOnlyUrls.indexOf(imageUrl);
                                
                                if (imageIndex >= 0) {
                                  FullScreenImageGalleryViewer.show(
                                    context,
                                    imageOnlyUrls,
                                    initialIndex: imageIndex,
                                  );
                                }
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: ImageBackgroundColor,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: CachedNetworkImage(
                                      imageUrl: thumbnailUrl,
                                      cacheManager: ItemImageCacheManager.instance,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const Center(
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        color: ImageBackgroundColor,
                                      ),
                                    ),
                                  ),
                                  if (isVideo)
                                    Positioned.fill(
                                      child: Container(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        child: const Center(
                                          child: Icon(
                                            Icons.play_circle_filled,
                                            color: Colors.white,
                                            size: 64,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        width: double.infinity,
                        color: ImageBackgroundColor,
                      ),
              ),
              // 타이머 오버레이 - 좌하단 (항상 표시, 박스에서 띄움)
              Positioned(
                bottom: 40,
                left: 16,
                child: _RemainingTimeOverlay(finishTime: widget.item.finishTime),
              ),
              // 입찰 카운트 오버레이 - 우하단 (왼쪽)
              Positioned(
                bottom: 40,
                right: 48,
                child: _BidCountOverlay(bidCount: widget.item.biddingCount),
              ),
              // 이미지 개수 표시 오버레이 - 우하단 (오른쪽)
              if (hasImages && images.isNotEmpty)
                Positioned(
                  bottom: 40,
                  right: 16,
                  child: _ImageCountOverlay(
                    currentIndex: _currentPage,
                    totalCount: images.length,
                  ),
                ),
            ],
          ),
        ),
        if (hasImages && images.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              images.length,
              (index) => _buildDot(isActive: index == _currentPage),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDot({required bool isActive}) {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Colors.black : Colors.transparent,
        border: Border.all(
          color: isActive ? Colors.black : const Color(0xFFBDBDBD),
          width: isActive ? 1.5 : 1,
        ),
      ),
    );
  }
}

class _RemainingTimeOverlay extends StatefulWidget {
  const _RemainingTimeOverlay({required this.finishTime});

  final DateTime finishTime;

  @override
  State<_RemainingTimeOverlay> createState() => _RemainingTimeOverlayState();
}

class _RemainingTimeOverlayState extends State<_RemainingTimeOverlay> with WidgetsBindingObserver {
  Timer? _timer;
  bool _isAppInForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _isAppInForeground = true;
      _startTimer();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _isAppInForeground = false;
      _stopTimer();
    }
  }

  void _startTimer() {
    _stopTimer(); // 기존 타이머가 있으면 정리
    if (DateTime.now().isAfter(widget.finishTime)) {
      return; // 이미 종료된 경우 타이머 시작 안 함
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isAppInForeground) {
        timer.cancel();
        return;
      }
      if (DateTime.now().isAfter(widget.finishTime)) {
        timer.cancel();
      }
      setState(() {});
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFinished = DateTime.now().isAfter(widget.finishTime);
    final remainingTime = isFinished
        ? '00:00:00'
        : formatRemainingTime(widget.finishTime);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.access_time,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            isFinished ? '경매 종료' : '$remainingTime 남음',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageCountOverlay extends StatelessWidget {
  const _ImageCountOverlay({
    required this.currentIndex,
    required this.totalCount,
  });

  final int currentIndex;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${currentIndex + 1}/$totalCount',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _BidCountOverlay extends StatelessWidget {
  const _BidCountOverlay({required this.bidCount});

  final int bidCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.gavel,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            '$bidCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

