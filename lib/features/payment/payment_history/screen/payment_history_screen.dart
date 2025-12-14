import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
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
    final titleFontSize = context.fontSizeLarge;
    
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
          style: TextStyle(
            fontSize: titleFontSize,
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
      final fontSize = context.fontSizeMedium;
      final buttonFontSize = context.fontSizeMedium;
      
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.hPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                style: TextStyle(fontSize: fontSize),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.spacingSmall),
              TextButton(
                onPressed: _loadPayments,
                child: Text(
                  PaymentErrorMessages.retry,
                  style: TextStyle(fontSize: buttonFontSize),
                ),
              ),
            ],
          ),
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
    final horizontalPadding = context.screenPadding;
    final verticalPadding = context.vPadding;
    final separatorHeight = context.spacingSmall;
    
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        verticalPadding,
        horizontalPadding,
        verticalPadding * 1.5,
      ),
      itemBuilder: (BuildContext context, int index) {
        final PaymentHistoryItem item = _payments[index];
        return _PaymentHistoryCard(item: item);
      },
      separatorBuilder: (BuildContext context, int index) => SizedBox(height: separatorHeight),
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
    
    // Responsive values
    final horizontalPadding = context.screenPadding;
    final verticalPadding = context.spacingMedium;
    final imageSize = context.widthRatio(0.4, min: 120.0, max: 200.0); // 특수 케이스: 결제 상세 이미지 크기
    final titleFontSize = context.fontSizeLarge;
    final amountFontSize = context.fontSizeXLarge;
    final badgeFontSize = context.widthRatio(0.03, min: 10.0, max: 14.0); // 특수 케이스: 상태 배지 폰트
    final spacing = context.spacingMedium;
    final buttonHeight = context.buttonHeight;
    final buttonFontSize = context.buttonFontSize;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              verticalPadding,
              horizontalPadding,
              verticalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 이미지
                Container(
                  width: imageSize,
                  height: imageSize,
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
                              placeholder: (context, url) => Container(
                                color: ImageBackgroundColor,
                                alignment: Alignment.center,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: ImageBackgroundColor,
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.image,
                                  size: context.iconSizeMedium,
                                  color: iconColor,
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: ImageBackgroundColor,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.image,
                            size: context.iconSizeMedium,
                            color: iconColor,
                          ),
                        ),
                ),
                SizedBox(height: spacing),
                // 제목
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: spacing * 0.5),
                // 상태 배지
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.inputPadding,
                    vertical: context.spacingSmall * 0.5,
                  ),
                  decoration: BoxDecoration(
                    color: getPaymentStatusBackgroundColor(isCompleted),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: badgeFontSize,
                      fontWeight: FontWeight.w600,
                      color: getPaymentStatusColor(isCompleted),
                    ),
                  ),
                ),
                SizedBox(height: spacing * 0.67),
                // 금액
                Text(
                  '${formatPrice(item.amount)}원',
                  style: TextStyle(
                    fontSize: amountFontSize,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: spacing),
                const Divider(height: 1),
                SizedBox(height: spacing * 0.67),
                // 상세 정보 리스트
                _DetailRow(
                  label: PaymentTexts.transactionType,
                  value: getPaymentTransactionTypeText(item.statusCode),
                ),
                SizedBox(height: context.labelBottomPadding),
                _DetailRow(
                  label: PaymentTexts.paymentDateTime,
                  value: formatDateTime(item.paidAt),
                ),
                SizedBox(height: context.labelBottomPadding),
                if (item.paymentType != null && item.paymentType!.isNotEmpty) ...[
                  _DetailRow(
                    label: PaymentTexts.paymentMethod,
                    value: item.paymentType!,
                  ),
                  SizedBox(height: context.labelBottomPadding),
                ],
                if (item.paymentId != null && item.paymentId!.isNotEmpty) ...[
                  _DetailRow(
                    label: PaymentTexts.transactionNumber,
                    value: item.paymentId!,
                  ),
                  SizedBox(height: context.labelBottomPadding),
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
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            context.spacingMedium,
          ),
          child: SizedBox(
            width: double.infinity,
            height: buttonHeight,
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
              child: Text(
                PaymentTexts.confirm,
                style: TextStyle(
                  fontSize: buttonFontSize,
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
    final labelWidth = context.widthRatio(0.2, min: 70.0, max: 100.0); // 특수 케이스: 상세 정보 라벨 너비
    final labelFontSize = context.fontSizeSmall;
    final valueFontSize = context.fontSizeMedium;
    final spacing = context.inputPadding;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(
            label,
            style: TextStyle(
              fontSize: labelFontSize,
              color: iconColor,
            ),
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize,
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
    
    // Responsive values
    final horizontalPadding = context.screenPadding;
    final verticalPadding = context.inputPadding;
    final borderRadius = context.inputPadding;
    final titleFontSize = context.fontSizeMedium;
    final dateFontSize = context.fontSizeSmall;
    final amountFontSize = context.fontSizeMedium;
    final badgeFontSize = context.widthRatio(0.028, min: 9.0, max: 13.0); // 특수 케이스: 카드 배지 폰트
    final spacing = context.inputPadding;
    final badgePadding = EdgeInsets.symmetric(
      horizontal: context.widthRatio(0.025, min: 8.0, max: 14.0), // 특수 케이스: 배지 패딩
      vertical: context.spacingSmall * 0.5,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: const [
          BoxShadow(
            color: shadowLow,
            offset: Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
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
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: spacing * 0.33),
                Text(
                  formatDate(item.paidAt),
                  style: TextStyle(
                    fontSize: dateFontSize,
                    color: iconColor,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: spacing),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${formatPrice(item.amount)}원',
                style: TextStyle(
                  fontSize: amountFontSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: spacing * 0.33),
              Container(
                padding: badgePadding,
                decoration: BoxDecoration(
                  color: getPaymentStatusBackgroundColor(isCompleted),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: badgeFontSize,
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
    final iconSize = context.iconSizeMedium;
    final titleFontSize = context.fontSizeMedium;
    final subtitleFontSize = context.fontSizeSmall;
    final spacing = context.screenPadding;
    final smallSpacing = context.spacingSmall * 0.5;
    
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.hPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long,
              size: iconSize,
              color: iconColor,
            ),
            SizedBox(height: spacing),
            Text(
              PaymentTexts.emptyHistory,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: smallSpacing),
            Text(
              PaymentTexts.emptyHistorySubtitle,
              style: TextStyle(
                fontSize: subtitleFontSize,
                color: iconColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
