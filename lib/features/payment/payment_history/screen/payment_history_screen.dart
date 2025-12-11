import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/features/payment/payment_history/data/payment_history_repository.dart';
import 'package:flutter/material.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key, this.itemId});

  final String? itemId;

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final PaymentHistoryRepository _repository = PaymentHistoryRepository();

  bool _loading = true;
  List<PaymentHistoryItem> _payments = <PaymentHistoryItem>[];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final List<PaymentHistoryItem> results =
          await _repository.fetchMyPayments(itemId: widget.itemId);
      if (!mounted) return;
      setState(() {
        _payments = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '결제 내역을 불러오지 못했습니다.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: BackgroundColor,
        foregroundColor: Colors.black,
        title: Text(
          widget.itemId != null ? '결제 상세 내역' : '결제 내역',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadPayments,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_payments.isEmpty) {
      return _EmptyPaymentHistory();
    }

    // itemId가 지정된 경우: 상세 1건 화면
    if (widget.itemId != null) {
      final PaymentHistoryItem item = _payments.first;
      return _PaymentDetailBody(item: item);
    }

    // itemId 없으면: 전체 결제 내역 리스트
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemBuilder: (BuildContext context, int index) {
        final PaymentHistoryItem item = _payments[index];
        return _PaymentHistoryCard(item: item);
      },
      separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 8),
      itemCount: _payments.length,
    );
  }
}

class _PaymentDetailBody extends StatelessWidget {
  const _PaymentDetailBody({required this.item});

  final PaymentHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = item.isAuctionWin || item.isInstantBuy;
    final String statusText = item.isAuctionWin
        ? '경매 낙찰'
        : item.isInstantBuy
            ? '즉시 구매'
            : '결제 완료';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 이미지
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: shadowLow,
                        offset: Offset(0, 4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty
                      ? Image.network(
                          item.thumbnailUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: ImageBackgroundColor,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.image,
                            size: 48,
                            color: iconColor,
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                // 제목
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                // 상태 배지
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? const Color(0xFFE6F7EC)
                        : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isCompleted
                          ? const Color(0xFF27AE60)
                          : const Color(0xFFFF5252),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 금액
                Text(
                  '${_formatAmount(item.amount)}원',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 16),
                // 상세 정보 리스트
                _DetailRow(
                  label: '거래 방식',
                  value: item.isInstantBuy ? '즉시 구매' : '경매 낙찰',
                ),
                const SizedBox(height: 8),
                _DetailRow(
                  label: '결제 일시',
                  value: _formatDateTime(item.paidAt),
                ),
                const SizedBox(height: 8),
                if (item.paymentType != null && item.paymentType!.isNotEmpty) ...[
                  _DetailRow(
                    label: '결제 수단',
                    value: item.paymentType!,
                  ),
                  const SizedBox(height: 8),
                ],
                if (item.paymentId != null && item.paymentId!.isNotEmpty) ...[
                  _DetailRow(
                    label: '거래 번호',
                    value: item.paymentId!,
                  ),
                  const SizedBox(height: 8),
                ],
                if (item.txId != null && item.txId!.isNotEmpty)
                  _DetailRow(
                    label: 'TX ID',
                    value: item.txId!,
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: blueColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.7),
                ),
              ),
              child: const Text(
                '확인',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: iconColor,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentHistoryCard extends StatelessWidget {
  const _PaymentHistoryCard({required this.item});

  final PaymentHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = item.isAuctionWin || item.isInstantBuy;
    final String statusText = item.isAuctionWin
        ? '경매 낙찰'
        : item.isInstantBuy
            ? '즉시 구매'
            : '결제 완료';

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
                  _formatDate(item.paidAt),
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
                  statusText,
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

String _formatDate(DateTime date) {
  return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
}

String _formatDateTime(DateTime date) {
  final String dateStr =
      '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  final String timeStr =
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  return '$dateStr $timeStr';
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
