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

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'title': title,
      'price': price,
      'thumbnailUrl': thumbnailUrl,
      'status': status,
    };
  }

  factory BidHistoryItem.fromJson(Map<String, dynamic> json) {
    return BidHistoryItem(
      itemId: json['item_id'] ?? '',
      title: json['title'] ?? '',
      price: json['price'] as int? ?? 0,
      thumbnailUrl: json['thumbnailUrl'],
      status: json['status'] ?? '',
    );
  }
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

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'title': title,
      'price': price,
      'thumbnailUrl': thumbnailUrl,
      'status': status,
      'date': date,
    };
  }

  factory SaleHistoryItem.fromJson(Map<String, dynamic> json) {
    return SaleHistoryItem(
      itemId: json['item_id'] ?? '',
      title: json['title'] ?? '',
      price: json['price'] as int? ?? 0,
      thumbnailUrl: json['thumbnailUrl'],
      status: json['status'] ?? '',
      date: json['date'] ?? '',
    );
  }
}
