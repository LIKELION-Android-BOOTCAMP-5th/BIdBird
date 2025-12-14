import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PortoneConfig {
  // 결제 관련 설정
  /// 포트원 스토어 ID
  static String? _storeId;
  static String get storeId {
    if (_storeId == null) {
      throw StateError('PortoneConfig not initialized. Call initialize() first.');
    }
    return _storeId!;
  }

  /// 포트원 채널 키
  static String? _channelKey;
  static String get channelKey {
    if (_channelKey == null) {
      throw StateError('PortoneConfig not initialized. Call initialize() first.');
    }
    return _channelKey!;
  }

  /// 초기화 완료 여부
  static bool get isInitialized => _storeId != null && _channelKey != null && _userCode != null && _pg != null && _redirectUrl != null;

  //본인인증 관련 설정
  /// 포트원 사용자 코드
  static String? _userCode;
  static String get userCode {
    if (_userCode == null) {
      throw StateError('PortoneConfig not initialized. Call initialize() first.');
    }
    return _userCode!;
  }
  
  /// PG 설정
  static String? _pg;
  static String get pg {
    if (_pg == null) {
      throw StateError('PortoneConfig not initialized. Call initialize() first.');
    }
    return _pg!;
  }
  
  /// 리다이렉트 URL
  static String? _redirectUrl;
  static String get redirectUrl {
    if (_redirectUrl == null) {
      throw StateError('PortoneConfig not initialized. Call initialize() first.');
    }
    return _redirectUrl!;
  }

  /// Supabase 환경 변수에서 포트원 설정을 로드합니다.
  static Future<void> initialize() async {
    try {
      final supabase = SupabaseManager.shared.supabase;
      final response = await supabase.functions.invoke(
        'payment-config',
        method: HttpMethod.get,
      );

      final data = response.data;
      if (data is Map && data['success'] == true && data['data'] is Map) {
        final configData = data['data'] as Map;
        _storeId = configData['storeId'] as String?;
        _channelKey = configData['channelKey'] as String?;
        _userCode = configData['userCode'] as String?;
        _pg = configData['pg'] as String?;
        _redirectUrl = configData['redirectUrl'] as String?;

        if (_storeId == null || _channelKey == null || _userCode == null || _pg == null || _redirectUrl == null) {
          debugPrint('[PortoneConfig] Missing required config values in response');
          throw StateError('Failed to load Portone config: missing values');
        }

        debugPrint('[PortoneConfig] Initialized successfully');
      } else {
        debugPrint('[PortoneConfig] Invalid response format: $data');
        throw StateError('Failed to load Portone config: invalid response');
      }
    } catch (e, st) {
      debugPrint('[PortoneConfig] Initialization error: $e\n$st');
      rethrow;
    }
  }
}

