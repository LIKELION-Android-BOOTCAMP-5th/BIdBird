import 'package:bidbird/features/chat/domain/entities/auction_info_entity.dart';
import 'package:bidbird/features/chat/domain/entities/item_info_entity.dart';
import 'package:bidbird/features/chat/domain/entities/opponent_entity.dart';
import 'package:bidbird/features/chat/domain/entities/trade_info_entity.dart';

class RoomInfoEntity {
  final ItemInfoEntity item;
  final AuctionInfoEntity auction;
  final OpponentEntity opponent;
  final TradeInfoEntity? trade;
  final int unreadCount;
  final DateTime? lastMessageAt;

  RoomInfoEntity({
    required this.item,
    required this.auction,
    required this.opponent,
    required this.trade,
    this.unreadCount = 0,
    this.lastMessageAt,
  });

  factory RoomInfoEntity.fromJson(Map<String, dynamic> json) {
    return RoomInfoEntity(
      item: ItemInfoEntity.fromJson(json["item"] ?? {}),
      auction: AuctionInfoEntity.fromJson(json["auction"] ?? {}),
      opponent: OpponentEntity.fromJson(json["opponent"] ?? {}),
      trade: json["trade"] != null
          ? TradeInfoEntity.fromJson(json["trade"])
          : null,
      unreadCount: json["unread_count"] ?? 0,
      lastMessageAt: json["last_message_at"] != null 
          ? DateTime.parse(json["last_message_at"]).toLocal()
          : null,
    );
  }
}
