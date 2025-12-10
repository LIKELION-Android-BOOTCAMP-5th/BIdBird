import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:flutter/material.dart';

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: 실제 결제 내역 데이터를 연동하세요.
    final List<_PaymentHistoryItem> payments = [
      _PaymentHistoryItem(
        title: '맥북 프로 16인치 2023',
        date: DateTime(2023, 10, 26),
        amount: 2350000,
        status: PaymentStatus.completed,
      ),
      _PaymentHistoryItem(
        title: '에어팟 맥스',
        date: DateTime(2023, 10, 24),
        amount: 769000,
        status: PaymentStatus.completed,
      ),
      _PaymentHistoryItem(
        title: '애플 매직 마우스',
        date: DateTime(2023, 10, 22),
        amount: 119000,
        status: PaymentStatus.canceled,
      ),
      _PaymentHistoryItem(
        title: '아이패드 프로 12.9인치',
        date: DateTime(2023, 9, 15),
        amount: 1520000,
        status: PaymentStatus.completed,
      ),
    ];

    return Scaffold(
      backgroundColor: BackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: BackgroundColor,
        foregroundColor: Colors.black,
        title: const Text(
          '결제 내역',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: payments.isEmpty
          ? _EmptyPaymentHistory()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemBuilder: (context, index) {
                final item = payments[index];
                return _PaymentHistoryCard(item: item);
              },
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemCount: payments.length,
            ),
    );
  }
}

class _PaymentHistoryCard extends StatelessWidget {
  const _PaymentHistoryCard({required this.item});

  final _PaymentHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = item.status == PaymentStatus.completed;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: shadowLow,
            offset: Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(item.date),
                  style: const TextStyle(
                    fontSize: 12,
                    color: iconColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_formatAmount(item.amount)}원',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFFE6F7EC)
                      : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isCompleted ? '결제 완료' : '결제 취소',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isCompleted
                        ? const Color(0xFF27AE60)
                        : const Color(0xFFFF5252),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyPaymentHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.receipt_long,
            size: 48,
            color: iconColor,
          ),
          SizedBox(height: 16),
          Text(
            '결제 내역이 없습니다.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '새로운 거래를 시작해보세요.',
            style: TextStyle(
              fontSize: 12,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }
}

enum PaymentStatus { completed, canceled }

class _PaymentHistoryItem {
  _PaymentHistoryItem({
    required this.title,
    required this.date,
    required this.amount,
    required this.status,
  });

  final String title;
  final DateTime date;
  final int amount;
  final PaymentStatus status;
}

String _formatDate(DateTime date) {
  return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
}

String _formatAmount(int amount) {
  final buffer = StringBuffer();
  final str = amount.toString();
  for (int i = 0; i < str.length; i++) {
    final reverseIndex = str.length - i - 1;
    buffer.write(str[i]);
    if (reverseIndex % 3 == 0 && i != str.length - 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}
