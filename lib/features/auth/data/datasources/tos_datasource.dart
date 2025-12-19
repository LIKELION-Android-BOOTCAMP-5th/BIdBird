import 'package:bidbird/core/managers/network_api_manager.dart';
import 'package:bidbird/features/auth/domain/entities/tos_entity.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ToSDatasource {
  static final ToSDatasource _shared = ToSDatasource();
  static ToSDatasource get shared => _shared;

  final Dio dio = Dio();
  final supabase = Supabase.instance.client;

  // ToS 목록 조회
  Future<List<ToSEntity>> getToSinfo() async {
    final response = await dio.get(
      '${NetworkApiManager.supabaseUrl}/tos?select=*',
      options: Options(headers: NetworkApiManager.useThisHeaders()),
    );

    final List<dynamic> data = response.data as List<dynamic>;

    return data
        .map((json) => ToSEntity.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  ///ToS 동의 처리
  Future<void> updateTosAgreed(String currentUserId) async {
    await supabase
        .from('users')
        .update({'ToS_agreed_at': DateTime.now().toIso8601String()})
        .eq('id', currentUserId);
  }
}


