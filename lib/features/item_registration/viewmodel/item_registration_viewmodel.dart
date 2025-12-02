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
          .select('id, title, description, start_price, buy_now_price, thumbnail_image, locked, status')
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
    return now.add(Duration(minutes: addMinutes));
  }

  Future<void> registerItem(
      BuildContext context, String itemId, DateTime auctionStartAt) async {
    if (isRegistering) return;

    isRegistering = true;
    notifyListeners();

    final messenger = ScaffoldMessenger.of(context);

    try {
      final supabase = SupabaseManager.shared.supabase;

      await supabase
          .from('items')
          .update(<String, dynamic>{
            'locked': true,
            'is_agree': true,
            'auction_start_at': auctionStartAt.toIso8601String(),
            'auction_stat': auctionStartAt.toIso8601String(),
          })
          .eq('id', itemId);

      messenger.showSnackBar(
        const SnackBar(content: Text('매물이 등록되었습니다.')),
      );

      await fetchMyPendingItems();

      Navigator.of(context).pop();
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

