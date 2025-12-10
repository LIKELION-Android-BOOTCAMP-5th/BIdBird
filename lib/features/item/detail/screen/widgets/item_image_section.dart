import 'dart:async';

import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/features/item/detail/model/item_detail_entity.dart';
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
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      // 경매 종료 이후에는 타이머 중단
      if (DateTime.now().isAfter(widget.item.finishTime)) {
        timer.cancel();
        setState(() {});
        return;
      }

      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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
                    return Container(
                      width: double.infinity,
                      color: ImageBackgroundColor,
                      child: Image.network(
                        images[index],
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Text(
                              '상품 사진',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        },
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
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: DateTime.now().isAfter(widget.item.finishTime)
                        ? Colors.black
                        : RedColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    DateTime.now().isAfter(widget.item.finishTime)
                        ? '경매 종료'
                        : '${formatRemainingTime(widget.item.finishTime)} 남음',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
