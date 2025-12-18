import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:flutter/material.dart';

class TradeReviewPopup extends StatefulWidget {
  final Future<void> Function(double rating, String review) onSubmit;
  final VoidCallback? onCancel;

  const TradeReviewPopup({
    super.key,
    required this.onSubmit,
    this.onCancel,
  });

  static void show(
    BuildContext context, {
    required Future<void> Function(double rating, String review) onSubmit,
    VoidCallback? onCancel,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TradeReviewPopup(
        onSubmit: onSubmit,
        onCancel: onCancel,
      ),
    );
  }

  @override
  State<TradeReviewPopup> createState() => _TradeReviewPopupState();
}

class _TradeReviewPopupState extends State<TradeReviewPopup> {
  double _rating = 5.0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;
  final GlobalKey _starRowKey = GlobalKey();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 제목
              const Text(
                '거래 평가',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 24),

              // 별점 선택
              Column(
                children: [
                  // 별점 표시 (드래그 가능)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onPanUpdate: (details) {
                          // 별 영역의 실제 크기 측정
                          final RenderBox? starBox = _starRowKey.currentContext?.findRenderObject() as RenderBox?;
                          if (starBox == null) return;
                          
                          // 별 영역 내에서의 상대 위치 계산
                          final Offset localPosition = starBox.globalToLocal(details.globalPosition);
                          final double starAreaWidth = starBox.size.width;
                          
                          // 별 영역 내에서의 위치 (0 ~ starAreaWidth)
                          double localX = localPosition.dx;
                          if (localX < 0) localX = 0;
                          if (localX > starAreaWidth) localX = starAreaWidth;
                          
                          // 0.0 ~ 5.0 범위로 변환
                          double newRating = (localX / starAreaWidth) * 5.0;
                          
                          // 범위 제한
                          if (newRating < 0.0) newRating = 0.0;
                          if (newRating > 5.0) newRating = 5.0;
                          
                          // 0.5 단위로 반올림
                          newRating = (newRating * 2).round() / 2.0;
                          
                          setState(() {
                            _rating = newRating;
                          });
                        },
                        onTapDown: (details) {
                          // 탭 위치에 따라 별점 설정
                          final RenderBox? starBox = _starRowKey.currentContext?.findRenderObject() as RenderBox?;
                          if (starBox == null) return;
                          
                          final Offset localPosition = starBox.globalToLocal(details.globalPosition);
                          final double starAreaWidth = starBox.size.width;
                          
                          double localX = localPosition.dx;
                          if (localX < 0) localX = 0;
                          if (localX > starAreaWidth) localX = starAreaWidth;
                          
                          double newRating = (localX / starAreaWidth) * 5.0;
                          if (newRating < 0.0) newRating = 0.0;
                          if (newRating > 5.0) newRating = 5.0;
                          newRating = (newRating * 2).round() / 2.0;
                          
                          setState(() {
                            _rating = newRating;
                          });
                        },
                        child: Row(
                          key: _starRowKey,
                          children: List.generate(5, (index) {
                            final starValue = index + 1;
                            IconData icon;
                            Color color;
                            if (starValue <= _rating.floor()) {
                              icon = Icons.star;
                              color = yellowColor;
                            } else if (starValue == _rating.ceil() &&
                                _rating % 1 >= 0.5) {
                              icon = Icons.star_half;
                              color = yellowColor;
                            } else {
                              icon = Icons.star_border;
                              color = BorderColor;
                            }
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                icon,
                                size: 32,
                                color: color,
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 평가 입력 필드
              TextField(
                controller: _reviewController,
                maxLength: 100,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: '거래에 대한 평가를 작성해주세요',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: BorderColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: BorderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: BorderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: blueColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                  counterText: '${_reviewController.text.length}/100',
                  counterStyle: TextStyle(
                    color: _reviewController.text.length > 100
                        ? RedColor
                        : BorderColor,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  color: textColor,
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 24),

              // 버튼 영역
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.onCancel != null) ...[
                    Expanded(
                      child: FilledButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(
                            Colors.grey.shade100,
                          ),
                        ),
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                widget.onCancel?.call();
                                Navigator.pop(context);
                              },
                        child: const Text(
                          '취소',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(blueColor),
                      ),
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              setState(() {
                                _isSubmitting = true;
                              });
                              try {
                                await widget.onSubmit(
                                  _rating,
                                  _reviewController.text.trim(),
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('평가 작성 중 오류가 발생했습니다: ${e.toString()}'),
                                      backgroundColor: RedColor,
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isSubmitting = false;
                                  });
                                }
                              }
                            },
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('확인'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

