class BidHistoryItem {
  final String itemId;
  final String title;
  final int price;
  final String? thumbnailUrl;
  final String status;

  BidHistoryItem({
    required this.itemId,
    required this.title,
    required this.price,
    this.thumbnailUrl,
    required this.status,
  });
}

class SaleHistoryItem {
  final String itemId;
  final String title;
  final int price;
  final String? thumbnailUrl;
  final String status;
  final String date;

  SaleHistoryItem({
    required this.itemId,
    required this.title,
    required this.price,
    this.thumbnailUrl,
    required this.status,
    required this.date,
  });
}
