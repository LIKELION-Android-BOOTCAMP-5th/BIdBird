class ItemsEntity {
  final String id;
  final String seller_id;
  final String title;
  final String description;
  final String thumbnail_image;
  final int start_price;
  final int? buy_now_price;
  final int current_price;
  final int? bidding_count;
  final String status;
  final int keyword_type;
  final String auction_end_at;
  final String created_at;
  final String? is_agreed;
  final String auction_start_at;
  final String? auction_stat;
  final int auction_duration_hours;
  final int status_code;
  final DateTime finishTime;
  final String? lastBidUserId;
  final int? auctionStatusCode;
  final int? tradeStatusCode;

  ItemsEntity({
    required this.id,
    required this.seller_id,
    required this.title,
    required this.description,
    required this.thumbnail_image,
    required this.start_price,
    required this.buy_now_price,
    required this.current_price,
    required this.bidding_count,
    required this.status,
    required this.keyword_type,
    required this.auction_end_at,
    required this.created_at,
    required this.is_agreed,
    required this.auction_start_at,
    required this.auction_stat,
    required this.auction_duration_hours,
    required this.status_code,
    required this.finishTime,
    required this.lastBidUserId,
    required this.auctionStatusCode,
    required this.tradeStatusCode,
  });

  factory ItemsEntity.fromJson(Map<String, dynamic> json) {
    // is_agreed 기본값 계산용 (없으면 현재 시간 사용)
    final isAgreedAtRaw = json['is_agreed']?.toString();
    final isAgreedAt = isAgreedAtRaw != null
        ? DateTime.tryParse(isAgreedAtRaw) ?? DateTime.now()
        : DateTime.now();

    // 종료 시간은 auction_end_at 컬럼을 직접 사용
    final auctionEndRaw = json['auction_end_at']?.toString();
    DateTime finishTime;
    if (auctionEndRaw != null && auctionEndRaw.isNotEmpty) {
      finishTime = DateTime.tryParse(auctionEndRaw) ?? DateTime.now();
    } else {
      // auction_end_at 이 없는 경우 기존 로직(동의 시각 + duration)으로 보정
      final isAgreedAtRaw = json['is_agreed']?.toString();
      final isAgreedAt = isAgreedAtRaw != null
          ? DateTime.tryParse(isAgreedAtRaw) ?? DateTime.now()
          : DateTime.now();

      final durationHours = (json['auction_duration_hours'] as int?) ?? 24;
      finishTime = isAgreedAt.add(Duration(hours: durationHours));
    }

    final String id = (json['item_id'] ?? json['id'])?.toString() ?? '';

    int? biddingCount;
    final auctions = json['auctions'];
    String? lastBidUserId;
    int? auctionStatusCode;
    int? tradeStatusCode;

    if (auctions is List && auctions.isNotEmpty) {
      final first = auctions.first;

      final dynamic rawBidCount = first['bid_count'];
      if (rawBidCount is int) {
        biddingCount = rawBidCount;
      } else if (rawBidCount is String) {
        biddingCount = int.tryParse(rawBidCount);
      }

      lastBidUserId = first['last_bid_user_id'] as String?;
      final dynamic rawStatusCode = first['auction_status_code'];
      if (rawStatusCode is int) {
        auctionStatusCode = rawStatusCode;
      } else if (rawStatusCode is String) {
        auctionStatusCode = int.tryParse(rawStatusCode);
      }

      final dynamic rawTradeCode = first['trade_status_code'];
      if (rawTradeCode is int) {
        tradeStatusCode = rawTradeCode;
      } else if (rawTradeCode is String) {
        tradeStatusCode = int.tryParse(rawTradeCode);
      }
    }

    biddingCount ??= json['bidding_count'] as int?;
    lastBidUserId ??= json['last_bid_user_id'] as String?;
    auctionStatusCode ??= json['auction_status_code'] as int?;
    tradeStatusCode ??= json['trade_status_code'] as int?;

    return ItemsEntity(
      id: id,
      seller_id: (json['seller_id'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      thumbnail_image: (json['thumbnail_image'] ?? '') as String,
      start_price: (json['start_price'] as int?) ?? 0,
      buy_now_price: json['buy_now_price'] as int?,
      current_price:
          (json['current_price'] as int?) ?? (json['start_price'] as int?) ?? 0,
      bidding_count: biddingCount,
      status: (json['status'] ?? '') as String,
      keyword_type: (json['keyword_type'] as int?) ?? 0,
      auction_end_at: (json['auction_end_at'] ?? '') as String,
      created_at: (json['created_at']) as String,
      is_agreed: (json['is_agreed'] ?? isAgreedAt.toIso8601String()) as String?,
      auction_start_at: (json['auction_start_at'] ?? '') as String,
      auction_stat: json['auction_stat'] as String?,
      auction_duration_hours: (json['auction_duration_hours'] as int?) ?? 24,
      status_code: (json['status_code'] as int?) ?? 0,
      finishTime: finishTime,
      lastBidUserId: lastBidUserId,
      auctionStatusCode: auctionStatusCode,
      tradeStatusCode: tradeStatusCode,
    );
  }
}
