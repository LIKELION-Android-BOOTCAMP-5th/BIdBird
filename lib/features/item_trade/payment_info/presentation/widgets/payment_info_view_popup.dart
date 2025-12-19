import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/fonts_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 구매자가 판매자의 결제 정보(은행 정보 또는 직거래)를 확인하는 팝업
class PaymentInfoViewPopup extends StatelessWidget {
  const PaymentInfoViewPopup({
    super.key,
    required this.paymentType,
    this.bankName,
    this.accountNumber,
    this.accountHolder,
  });

  final String paymentType;
  final String? bankName;
  final String? accountNumber;
  final String? accountHolder;

  bool get isDirectTrade => paymentType == 'direct_trade';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목
            Text(
              isDirectTrade ? '직거래 안내' : '결제 정보',
              style: contentFontStyle.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),

            if (isDirectTrade) ...[
              // 직거래 안내
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: blueColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: blueColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.handshake, color: blueColor, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '직거래로 진행됩니다',
                            style: contentFontStyle.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '판매자와 채팅으로 만남 장소와 시간을 조율해주세요.',
                            style: contentFontStyle.copyWith(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // 계좌 정보
              Text(
                '아래 계좌로 입금해주세요.',
                style: contentFontStyle.copyWith(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),

              // 은행명
              _buildInfoRow('은행명', bankName ?? '-'),
              const SizedBox(height: 12),

              // 계좌번호
              _buildInfoRow('계좌번호', accountNumber ?? '-', showCopy: true, context: context),
              const SizedBox(height: 12),

              // 예금주
              _buildInfoRow('예금주', accountHolder ?? '-'),
            ],

            const SizedBox(height: 24),

            // 닫기 버튼
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(blueColor),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('확인'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool showCopy = false, BuildContext? context}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: contentFontStyle.copyWith(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: contentFontStyle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (showCopy && context != null)
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('계좌번호가 복사되었습니다')),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '복사',
                style: contentFontStyle.copyWith(
                  fontSize: 12,
                  color: blueColor,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
