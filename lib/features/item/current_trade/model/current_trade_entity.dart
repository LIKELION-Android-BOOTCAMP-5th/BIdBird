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

class CurrentTradeDateFormatter {
  static String format(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final dt = DateTime.tryParse(isoString);
      if (dt == null) return isoString;

      final y = dt.year.toString().padLeft(4, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$y-$m-$d $h:$min';
    } catch (_) {
      return isoString;
    }
  }
}

