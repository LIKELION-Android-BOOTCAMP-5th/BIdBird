import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 아이템 상세에서 테이블/채널 구독을 관리하는 서비스
class RealtimeChannelService {
  RealtimeChannelService({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseManager.shared.supabase;

  final SupabaseClient _supabase;
  RealtimeChannel? _channel;

  void subscribeToItem(String table, String itemId, void Function(Map<String, dynamic> row) onChange) {
    _channel?.unsubscribe();
    _channel = _supabase.channel('realtime-$table-$itemId');

    _channel!
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: table,
        callback: (payload) {
          final record = payload.newRecord;
          if (record['item_id'] == itemId) {
            onChange(record);
          }
        },
      );

    _channel!.subscribe();
  }

  Future<void> dispose() async {
    await _channel?.unsubscribe();
    _channel = null;
  }
}
