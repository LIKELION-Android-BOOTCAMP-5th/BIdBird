import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/item/item_price_utils.dart';
import 'package:bidbird/core/utils/item/item_time_utils.dart';
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
        final String price = '${formatPrice(priceValue)}원';
        final String date = formatDateFromIso(createdAt);

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


}

class _StatusInfo {
  _StatusInfo(this.label, this.color);

  final String label;
  final Color color;
}

_StatusInfo _mapAuctionTradeStatus(int? auctionCode, int? tradeCode) {
  // trade_status_code 기준으로 우선 판단
  // ● 진행 중으로 볼 상태들 → '판매중'
  //   - 결제 대기(510) 포함
  // ● 그 외 완료/종료 코드들 → '거래 종료'

  if (tradeCode != null) {
    if (tradeCode == 510) {
      return _StatusInfo('판매중', tradeBidPendingColor);
    }
    // 520(구매 완료), 550(거래 완료) 등 기타 trade 종료 상태
    return _StatusInfo('거래 종료', tradeSaleDoneColor);
  }

  // trade_code 가 없을 때는 auction_status_code 로 판단
  switch (auctionCode) {
    // 경매 대기/진행/즉시구매 진행 중 → 판매중
    case 300: // 경매 대기
    case 310: // 경매 진행 중
    case 311: // 즉시 구매 진행 중
      return _StatusInfo('판매중', tradeBidPendingColor);

    // 낙찰/구매 완료/유찰 등 → 거래 종료
    case 321: // 낙찰
    case 322: // 즉시 구매 완료
    case 323: // 유찰
      return _StatusInfo('거래 종료', tradeSaleDoneColor);

    default:
      // 알 수 없는 상태도 기본적으로 진행 중으로 취급
      return _StatusInfo('판매중', tradeBidPendingColor);
  }
}
