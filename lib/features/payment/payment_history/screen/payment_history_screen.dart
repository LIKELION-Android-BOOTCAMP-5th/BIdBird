import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/item/item_time_utils.dart';
import 'package:bidbird/core/utils/item/item_price_utils.dart';
import 'package:bidbird/core/utils/item/item_media_utils.dart';
import 'package:bidbird/core/utils/payment/payment_error_messages.dart';
import 'package:bidbird/core/utils/payment/payment_texts.dart';
import 'package:bidbird/core/utils/payment/payment_status_utils.dart';
import 'package:bidbird/features/payment/payment_history/data/payment_history_repository.dart';
import 'package:bidbird/core/managers/item_image_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
        _error = PaymentErrorMessages.loadHistoryFailed;
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
          widget.itemId != null 
              ? PaymentTexts.historyDetailTitle 
              : PaymentTexts.historyTitle,
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
              child: const Text(PaymentErrorMessages.retry),
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
    final String statusText = getPaymentStatusText(
      item.statusCode,
      isCompleted: isCompleted,
    );

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
                      ? Builder(
                          builder: (context) {
                            final String imageUrl = isVideoFile(item.thumbnailUrl!)
                                ? getVideoThumbnailUrl(item.thumbnailUrl!)
                                : item.thumbnailUrl!;
                            
                            return CachedNetworkImage(
                              imageUrl: imageUrl,
                              cacheManager: ItemImageCacheManager.instance,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Container(
                                color: ImageBackgroundColor,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.image,
                                  size: 48,
                                  color: iconColor,
                                ),
                              ),
                            );
                          },
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
                    color: getPaymentStatusBackgroundColor(isCompleted),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: getPaymentStatusColor(isCompleted),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 금액
                Text(
                  '${formatPrice(item.amount)}원',
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
                  label: PaymentTexts.transactionType,
                  value: getPaymentTransactionTypeText(item.statusCode),
                ),
                const SizedBox(height: 8),
                _DetailRow(
                  label: PaymentTexts.paymentDateTime,
                  value: formatDateTime(item.paidAt),
                ),
                const SizedBox(height: 8),
                if (item.paymentType != null && item.paymentType!.isNotEmpty) ...[
                  _DetailRow(
                    label: PaymentTexts.paymentMethod,
                    value: item.paymentType!,
                  ),
                  const SizedBox(height: 8),
                ],
                if (item.paymentId != null && item.paymentId!.isNotEmpty) ...[
                  _DetailRow(
                    label: PaymentTexts.transactionNumber,
                    value: item.paymentId!,
                  ),
                  const SizedBox(height: 8),
                ],
                if (item.txId != null && item.txId!.isNotEmpty)
                  _DetailRow(
                    label: PaymentTexts.txId,
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
                // 1순위: 스택에 이전 화면이 있으면 단순히 뒤로가기
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                  return;
                }

                // 2순위: 딥링크 등으로 단독 진입한 경우에는 해당 매물 상세로 이동
                context.go('/item/${item.itemId}');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: blueColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.7),
                ),
              ),
              child: const Text(
                PaymentTexts.confirm,
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
    final String statusText = getPaymentStatusText(
      item.statusCode,
      isCompleted: isCompleted,
    );

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
                  formatDate(item.paidAt),
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
                '${formatPrice(item.amount)}원',
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
                  color: getPaymentStatusBackgroundColor(isCompleted),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: getPaymentStatusColor(isCompleted),
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
            PaymentTexts.emptyHistory,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            PaymentTexts.emptyHistorySubtitle,
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
