import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/features/item/user_history/model/user_history_entity.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileDatasource {
  UserProfileDatasource({SupabaseClient? supabase})
    : _supabase = supabase ?? SupabaseManager.shared.supabase;

  final SupabaseClient _supabase;

  Future<List<UserTradeSummary>> fetchUserTrades(String userId) async {
    if (userId.isEmpty) return [];

    try {
      // 1) 판매자가 해당 유저인 아이템 목록 조회 (items_detail 기준)
      final List<dynamic> itemRows = await _supabase
          .from('items_detail')
          .select('item_id, title, thumbnail_image, created_at, seller_id')
          .eq('seller_id', userId)
          .order('created_at', ascending: false);

      if (itemRows.isEmpty) return [];

      final Map<String, Map<String, dynamic>> itemsById = {};
      final List<String> itemIds = [];
      for (final row in itemRows) {
        final id = row['item_id']?.toString();
        if (id != null) {
          itemsById[id] = row;
          itemIds.add(id);
        }
      }

      // 2) 각 아이템에 대한 경매/거래 상태 및 현재가 조회 (auctions 기준, 1라운드)
      Map<String, int> priceByItemId = {};
      Map<String, int> auctionCodeByItemId = {};
      Map<String, int> tradeCodeByItemId = {};
      if (itemIds.isNotEmpty) {
        final priceRows = await _supabase
            .from('auctions')
            .select(
                'item_id, current_price, auction_status_code, trade_status_code')
            .inFilter('item_id', itemIds)
            .eq('round', 1);

        for (final row in priceRows) {
          final id = row['item_id']?.toString();
          if (id != null) {
            priceByItemId[id] = (row['current_price'] as int?) ?? 0;
            final auctionCode = row['auction_status_code'] as int?;
            if (auctionCode != null) {
              auctionCodeByItemId[id] = auctionCode;
            }
            final tradeCode = row['trade_status_code'] as int?;
            if (tradeCode != null) {
              tradeCodeByItemId[id] = tradeCode;
            }
          }
        }
      }

      // 3) 화면에서 사용할 요약 데이터로 변환
      return itemIds.map<UserTradeSummary>((itemId) {
        final item = itemsById[itemId] ?? <String, dynamic>{};
        final auctionCode = auctionCodeByItemId[itemId];
        final tradeCode = tradeCodeByItemId[itemId];
        final createdAt = item['created_at']?.toString();

        final String title = item['title']?.toString() ?? '';
        final String? thumbnailUrl = item['thumbnail_image']?.toString();
        final int priceValue = priceByItemId[itemId] ?? 0;
        final String price = _formatPrice(priceValue);
        final String date = _formatDate(createdAt);

        final _StatusInfo status = _mapAuctionTradeStatus(
          auctionCode,
          tradeCode,
        );

        return UserTradeSummary(
          title: title,
          price: price,
          date: date,
          statusLabel: status.label,
          statusColor: status.color,
          thumbnailUrl: thumbnailUrl,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  String _formatPrice(int price) {
    final buffer = StringBuffer();
    final text = price.toString();
    for (int i = 0; i < text.length; i++) {
      final reverseIndex = text.length - i;
      buffer.write(text[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1 && i != text.length - 1) {
        buffer.write(',');
      }
    }
    return '${buffer.toString()}원';
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final dt = DateTime.tryParse(isoString);
      if (dt == null) return '';
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      return '${dt.year}.$m.$d';
    } catch (_) {
      return '';
    }
  }
}

class _StatusInfo {
  _StatusInfo(this.label, this.color);

  final String label;
  final Color color;
}

_StatusInfo _mapAuctionTradeStatus(int? auctionCode, int? tradeCode) {
  // trade_status_code 우선
  if (tradeCode == 550) {
    return _StatusInfo('거래 완료', tradeSaleDoneColor);
  }
  if (tradeCode == 520) {
    return _StatusInfo('구매 완료', tradePurchaseDoneColor);
  }
  if (tradeCode == 510) {
    return _StatusInfo('결제 대기', tradeBidPendingColor);
  }

  // 그 외에는 auction_status_code 기준
  switch (auctionCode) {
    case 300: // 경매 대기
    case 310: // 경매 진행 중
    case 311: // 즉시 구매 진행 중
      return _StatusInfo('입찰 중', tradeBidPendingColor);
    case 321: // 낙찰
      return _StatusInfo('판매 완료', tradeSaleDoneColor);
    case 322: // 즉시 구매 완료
      return _StatusInfo('구매 완료', tradePurchaseDoneColor);
    case 323: // 유찰
      return _StatusInfo('유찰', tradeBlockedColor);
    default:
      return _StatusInfo('입찰 중', tradeBidPendingColor);
  }
}
