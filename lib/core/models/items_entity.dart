class ItemsEntity {
  final String item_id;
  final String seller_id;
  final String title;
  final String description;
  final String thumbnail_image;
  final int start_price;
  final int? buy_now_price;
  final int keyword_type;
  final String created_at;
  final String? update_at;
  final String? is_agreed;
  final bool visibility_status;
  final int auction_duration_hours;

  DateTime finishTime;
  Auctions auctions;

  ItemsEntity({
    required this.item_id,
    required this.seller_id,
    required this.title,
    required this.description,
    required this.thumbnail_image,
    required this.start_price,
    required this.buy_now_price,
    required this.keyword_type,
    required this.created_at,
    required this.is_agreed,
    required this.auction_duration_hours,
    required this.finishTime,
    required this.update_at,
    required this.visibility_status,
    required this.auctions,
  });

  factory ItemsEntity.fromJson(Map<String, dynamic> json) {
    // is_agreed 처리
    final isAgreedAtRaw = json['is_agreed']?.toString();
    final isAgreedAt = isAgreedAtRaw != null
        ? DateTime.tryParse(isAgreedAtRaw) ?? DateTime.now()
        : DateTime.now();

    DateTime finishTime;

    // auctions 안에 endTime이 있는지 확인
    if (json['auctions'] is List && json['auctions'].isNotEmpty) {
      final auctions = json['auctions'][0];
      final endRaw = auctions['auction_end_at']?.toString();

      if (endRaw != null && endRaw.isNotEmpty) {
        finishTime = DateTime.tryParse(endRaw) ?? DateTime.now();
      } else {
        // 보정값
        final durationHours = (json['auction_duration_hours'] as int?) ?? 24;
        finishTime = isAgreedAt.add(Duration(hours: durationHours));
      }
    } else {
      // auctions 자체가 없는 경우
      final durationHours = (json['auction_duration_hours'] as int?) ?? 24;
      finishTime = isAgreedAt.add(Duration(hours: durationHours));
    }

    // auctions 리스트 파싱
    Auctions auctionsEntity = Auctions(
      bid_count: 0,
      current_price: 0,
      auction_end_at: '',
      auction_start_at: '',
      last_bid_user_id: '',
      trade_status_code: 0,
      auction_status_code: 0,
    );

    if (json['auctions'] is List && json['auctions'].isNotEmpty) {
      auctionsEntity = Auctions.fromJson(json['auctions'][0]);
    }

    return ItemsEntity(
      item_id: (json['item_id']) as String,
      seller_id: (json['seller_id'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      thumbnail_image: (json['thumbnail_image'] ?? '') as String,
      start_price: (json['start_price'] as int?) ?? 0,
      buy_now_price: json['buy_now_price'] as int?,
      keyword_type: (json['keyword_type'] as int?) ?? 0,
      created_at: (json['created_at']) as String,
      is_agreed: (json['is_agreed'] ?? isAgreedAt.toIso8601String()) as String?,
      auction_duration_hours: (json['auction_duration_hours'] as int?) ?? 24,
      finishTime: finishTime,
      update_at: (json['update_at']) as String?,
      visibility_status: (json['visibility_status']) as bool,
      auctions: auctionsEntity,
    );
  }
}

class Auctions {
  int bid_count;
  int current_price;
  String auction_end_at;
  String auction_start_at;
  String last_bid_user_id;
  int? trade_status_code;
  int auction_status_code;

  Auctions({
    required this.bid_count,
    required this.current_price,
    required this.auction_end_at,
    required this.auction_start_at,
    required this.last_bid_user_id,
    required this.trade_status_code,
    required this.auction_status_code,
  });

  factory Auctions.fromJson(Map<String, dynamic> json) {
    return Auctions(
      bid_count: (json['bid_count']) as int,
      current_price: (json['current_price'] ?? 0) as int,
      auction_end_at: (json['auction_end_at'] ?? '') as String,
      auction_start_at: (json['auction_start_at'] ?? '') as String,
      last_bid_user_id: (json['last_bid_user_id'] ?? '') as String,
      trade_status_code: json['trade_status_code'] as int?,
      auction_status_code: json['auction_status_code'] as int,
    );
  }
}
