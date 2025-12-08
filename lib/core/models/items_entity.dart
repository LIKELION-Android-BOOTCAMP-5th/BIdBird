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
  final bool is_agree;
  final String auction_start_at;
  final String? auction_stat;
  final int auction_duration_hours;
  final int status_code;

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
    required this.is_agree,
    required this.auction_start_at,
    required this.auction_stat,
    required this.auction_duration_hours,
    required this.status_code,
  });

  factory ItemsEntity.fromJson(Map<String, dynamic> json) {
    return ItemsEntity(
      id: json['id'] as String,
      seller_id: json['seller_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      thumbnail_image: json['thumbnail_image'] as String,
      start_price: json['start_price'] as int,
      buy_now_price: json['buy_now_price'] as int?,
      current_price: json['current_price'] as int,
      bidding_count: json['bidding_count'] as int?,
      status: json['status'] as String,
      keyword_type: json['keyword_type'] as int,
      auction_end_at: json['auction_end_at'] as String,
      created_at: json['created_at'] as String,
      is_agree: json['is_agree'] as bool,
      auction_start_at: json['auction_start_at'] as String,
      auction_stat: json['auction_stat'] as String?,
      auction_duration_hours: json['auction_duration_hours'] as int,
      status_code: json['status_code'] as int,
    );
  }
}
