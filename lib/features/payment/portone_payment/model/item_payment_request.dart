class ItemPaymentRequest {
  final String itemId;
  final String itemTitle;
  final int amount;
  final String buyerTel;
  final String appScheme;

  const ItemPaymentRequest({
    required this.itemId,
    required this.itemTitle,
    required this.amount,
    required this.buyerTel,
    required this.appScheme,
  });
}
