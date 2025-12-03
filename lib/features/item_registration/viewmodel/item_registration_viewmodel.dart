import 'package:bidbird/core/supabase_manager.dart';
import 'package:flutter/material.dart';
import '../data/item_registration_data.dart';

class ItemRegistrationViewModel extends ChangeNotifier {
  ItemRegistrationViewModel();

  bool isLoading = false;
  bool isRegistering = false;
  List<ItemRegistrationData> items = <ItemRegistrationData>[];

  Future<void> init() async {
    await fetchMyPendingItems();
  }

  Future<void> fetchMyPendingItems() async {
    isLoading = true;
    notifyListeners();

    try {
      final supabase = SupabaseManager.shared.supabase;
      final user = supabase.auth.currentUser;

      if (user == null) {
        items = <ItemRegistrationData>[];
        return;
      }

      final List<dynamic> data = await supabase
          .from('items')
          .select(
            'id, title, description, start_price, buy_now_price, thumbnail_image, keyword_type, locked, status',
          )
          .eq('seller_id', user.id)
          .eq('locked', false);

      items = data.map((dynamic row) {
        final map = row as Map<String, dynamic>;
        return ItemRegistrationData(
          id: map['id'].toString(),
          title: map['title']?.toString() ?? '',
          description: map['description']?.toString() ?? '',
          startPrice: (map['start_price'] as num?)?.toInt() ?? 0,
          instantPrice: (map['buy_now_price'] as num?)?.toInt() ?? 0,
          thumbnailUrl: map['thumbnail_image'] as String?,
          keywordTypeId: (map['keyword_type'] as num?)?.toInt(),
        );
      }).toList();
    } catch (e) {
      // TODO: 에러 로깅 또는 처리
      items = <ItemRegistrationData>[];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  DateTime getNextAuctionStartTime() {
    final DateTime now = DateTime.now();
    final int minute = now.minute;
    if (minute % 10 == 0) {
      return DateTime(
        now.year,
        now.month,
        now.day,
        now.hour,
        minute,
      );
    }

    final int addMinutes = 10 - (minute % 10);
    final DateTime added = now.add(Duration(minutes: addMinutes));
    return DateTime(
      added.year,
      added.month,
      added.day,
      added.hour,
      added.minute,
    );
  }

  Future<void> registerItem(
      BuildContext context, String itemId, DateTime auctionStartAt) async {
    if (isRegistering) return;

    isRegistering = true;
    notifyListeners();

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final supabase = SupabaseManager.shared.supabase;
      final user = supabase.auth.currentUser;

      final DateTime normalizedAuctionStartAt = DateTime(
        auctionStartAt.year,
        auctionStartAt.month,
        auctionStartAt.day,
        auctionStartAt.hour,
        auctionStartAt.minute,
      );

      await supabase
          .from('items')
          .update(<String, dynamic>{
            'locked': true,
            'is_agree': true,
            'auction_start_at': normalizedAuctionStartAt.toIso8601String(),
            'auction_stat': normalizedAuctionStartAt.toIso8601String(),
          })
          .eq('id', itemId);

      if (user != null) {
        await supabase.from('status_history').insert(<String, dynamic>{
          'item_id': itemId,
          'prev_status': null,
          'new_status': 'AUCTION_SCHEDULED',
          'reason_code': null,
          'created_at': normalizedAuctionStartAt.toIso8601String(),
          'user_id': user.id,
        });

        await supabase.from('bid_log').insert(<String, dynamic>{
          'item_id': itemId,
          'user_id': user.id,
          'bid_price': 0,
          'bid_time': normalizedAuctionStartAt.toIso8601String(),
        });
      }

      messenger.showSnackBar(
        const SnackBar(content: Text('매물이 등록되었습니다.')),
      );

      await fetchMyPendingItems();

      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('등록 중 오류가 발생했습니다: $e')),
      );
    } finally {
      isRegistering = false;
      notifyListeners();
    }
  }
}

