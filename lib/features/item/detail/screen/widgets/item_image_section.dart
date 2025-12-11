import 'dart:async';

import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/managers/item_image_cache_manager.dart';
import 'package:bidbird/features/item/detail/model/item_detail_entity.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../item_detail_utils.dart';

class ItemImageSection extends StatefulWidget {
  const ItemImageSection({required this.item, super.key});

  final ItemDetail item;

  @override
  State<ItemImageSection> createState() => _ItemImageSectionState();
}

class _ItemImageSectionState extends State<ItemImageSection> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasImages = widget.item.itemImages.isNotEmpty;
    final images = hasImages ? widget.item.itemImages : <String>[];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Stack(
            children: [
              if (hasImages && images.isNotEmpty)
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    final imageUrl = images[index];

                    return Container(
                      width: double.infinity,
                      color: ImageBackgroundColor,
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        cacheManager: ItemImageCacheManager.instance,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Text(
                            '상품 사진',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    );
                  },
                )
              else
                Container(
                  width: double.infinity,
                  color: ImageBackgroundColor,
                  child: const Center(
                    child: Text('상품 사진', style: TextStyle(color: iconColor)),
                  ),
                ),
              Positioned(
                top: 16,
                left: 16,
                child: _RemainingTimeBadge(finishTime: widget.item.finishTime),
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

class _RemainingTimeBadge extends StatefulWidget {
  const _RemainingTimeBadge({required this.finishTime});

  final DateTime finishTime;

  @override
  State<_RemainingTimeBadge> createState() => _RemainingTimeBadgeState();
}

class _RemainingTimeBadgeState extends State<_RemainingTimeBadge> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (DateTime.now().isAfter(widget.finishTime)) {
        timer.cancel();
      }

      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFinished = DateTime.now().isAfter(widget.finishTime);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: isFinished ? Colors.black : RedColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isFinished
            ? '경매 종료'
            : '${formatRemainingTime(widget.finishTime)} 남음',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
