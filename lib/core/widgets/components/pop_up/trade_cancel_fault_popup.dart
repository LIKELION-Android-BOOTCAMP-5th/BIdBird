import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/fonts_style.dart';
import 'package:flutter/material.dart';

/// 거래 취소 귀책 사유 선택 팝업
/// 판매자 귀책인지 구매자 귀책인지 선택하는 결정 다이얼로그
class TradeCancelFaultPopup extends StatefulWidget {
  final void Function(bool isSellerFault) onSelected;

  const TradeCancelFaultPopup({
    super.key,
    required this.onSelected,
  });

  @override
  State<TradeCancelFaultPopup> createState() => _TradeCancelFaultPopupState();

  /// 팝업을 표시하는 헬퍼 메서드
  static void show(
    BuildContext context, {
    required void Function(bool isSellerFault) onSelected,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => TradeCancelFaultPopup(
        onSelected: (isSellerFault) {
          Navigator.of(dialogContext).pop();
          onSelected(isSellerFault);
        },
      ),
    );
  }
}

class _TradeCancelFaultPopupState extends State<TradeCancelFaultPopup> {
  bool? _selectedFault; // null: 미선택, true: 판매자 귀책, false: 구매자 귀책

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: defaultBorder),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SafeArea(
        minimum: const EdgeInsets.all(0),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 타이틀
              Text(
                '거래 취소 사유 선택',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 24),
              // Option Card 1: 판매자 귀책 (Primary)
              _buildOptionCard(
                label: '판매자 귀책',
                description: '상품 하자, 미발송, 설명 불일치 등',
                resultSummary: '구매자에게 불이익 없음\n결제 취소, 판매자 패널티 적용 가능',
                isSelected: _selectedFault == true,
                isPrimary: true,
                onTap: () {
                  setState(() {
                    _selectedFault = true;
                  });
                },
              ),
              const SizedBox(height: 12),
              // Option Card 2: 구매자 귀책 (Secondary)
              _buildOptionCard(
                label: '구매자 귀책',
                description: '단순 변심, 구매 실수 등',
                resultSummary: '환불 제한 또는 수수료 발생 가능',
                isSelected: _selectedFault == false,
                isPrimary: false,
                onTap: () {
                  setState(() {
                    _selectedFault = false;
                  });
                },
              ),
              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 16),
              // 하단 버튼 영역
              Row(
                children: [
                  // 취소 버튼 (2차 액션)
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 진행 버튼 (선택 시에만 활성화)
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _selectedFault != null ? blueColor : Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _selectedFault != null
                          ? () {
                              widget.onSelected(_selectedFault!);
                            }
                          : null,
                      child: Text(
                        _selectedFault == true
                            ? '판매자 귀책으로 진행'
                            : _selectedFault == false
                                ? '구매자 귀책으로 진행'
                                : '선택해주세요',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
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

  /// Option Card 위젯 빌드
  Widget _buildOptionCard({
    required String label,
    required String description,
    required String resultSummary,
    required bool isSelected,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isPrimary ? blueColor.withOpacity(0.1) : const Color(0xFFF3F4F6))
              : Colors.white,
          border: Border.all(
            color: isSelected
                ? (isPrimary ? blueColor : const Color(0xFF9CA3AF))
                : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 라벨
            Row(
              children: [
                // 선택 표시 (라디오 버튼 스타일)
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? (isPrimary ? blueColor : const Color(0xFF6B7280))
                          : const Color(0xFFD1D5DB),
                      width: 2,
                    ),
                    color: isSelected
                        ? (isPrimary ? blueColor : const Color(0xFF6B7280))
                        : Colors.white,
                  ),
                  child: isSelected
                      ? const Center(
                          child: Icon(
                            Icons.check,
                            size: 12,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? (isPrimary ? blueColor : const Color(0xFF111827))
                          : const Color(0xFF111827),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 설명
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF374151),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 결과 요약
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Text(
                resultSummary,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
