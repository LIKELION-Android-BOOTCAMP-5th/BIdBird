import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FirebaseConfig {
  static String? _projectId;
  static String? _messagingSenderId;
  static String? _storageBucket;

  // Web
  static String? _webApiKey;
  static String? _webAppId;
  static String? _webAuthDomain;
  static String? _webMeasurementId;
  static String? _webVapidKey;


  // Android
  static String? _androidApiKey;
  static String? _androidAppId;

  // iOS
  static String? _iosApiKey;
  static String? _iosAppId;
  static String? _iosBundleId;

  // Google Sign-In
  static String? _googleWebClientId;
  static String? _googleIosClientId;

  static String get projectId => _require(_projectId, 'projectId');
  static String get messagingSenderId => _require(_messagingSenderId, 'messagingSenderId');
  static String get storageBucket => _require(_storageBucket, 'storageBucket');

  static String get webApiKey => _require(_webApiKey, 'webApiKey');
  static String get webAppId => _require(_webAppId, 'webAppId');
  static String get webAuthDomain => _require(_webAuthDomain, 'webAuthDomain');
  static String? get webMeasurementId => _webMeasurementId;
  static String? get webVapidKey => _webVapidKey;


  static String get androidApiKey => _require(_androidApiKey, 'androidApiKey');
  static String get androidAppId => _require(_androidAppId, 'androidAppId');

  static String get iosApiKey => _require(_iosApiKey, 'iosApiKey');
  static String get iosAppId => _require(_iosAppId, 'iosAppId');
  static String get iosBundleId => _require(_iosBundleId, 'iosBundleId');

  static String? get googleWebClientId => _googleWebClientId;
  static String? get googleIosClientId => _googleIosClientId;


  static String _require(String? value, String name) {
    if (value == null) {
      throw StateError('FirebaseConfig not initialized or missing value: $name. Call initialize() first.');
    }
    return value;
  }

  static bool get isInitialized => _projectId != null;

  static Future<void> initialize() async {
    try {
      final supabase = SupabaseManager.shared.supabase;
      final response = await supabase.functions.invoke(
        'FirebaseConfig',
        method: HttpMethod.get,
      );


      final data = response.data;
      if (data is Map && data['success'] == true && data['data'] is Map) {
        final configData = data['data'] as Map;
        
        _projectId = configData['projectId'] as String?;
        _messagingSenderId = configData['messagingSenderId'] as String?;
        _storageBucket = configData['storageBucket'] as String?;

        final webData = configData['web'] as Map?;
        if (webData != null) {
          _webApiKey = webData['apiKey'] as String?;
          _webAppId = webData['appId'] as String?;
          _webAuthDomain = webData['authDomain'] as String?;
          _webMeasurementId = webData['measurementId'] as String?;
          _webVapidKey = webData['vapidKey'] as String?;
        }


        final androidData = configData['android'] as Map?;
        if (androidData != null) {
          _androidApiKey = androidData['apiKey'] as String?;
          _androidAppId = androidData['appId'] as String?;
        }

        final iosData = configData['ios'] as Map?;
        if (iosData != null) {
          _iosApiKey = iosData['apiKey'] as String?;
          _iosAppId = iosData['appId'] as String?;
          _iosBundleId = iosData['bundleId'] as String?;
        }

        final googleData = configData['googleSignIn'] as Map?;
        if (googleData != null) {
          _googleWebClientId = googleData['webClientId'] as String?;
          _googleIosClientId = googleData['iosClientId'] as String?;
        }

        if (_projectId == null || _messagingSenderId == null || _storageBucket == null) {

          throw StateError('Failed to load Firebase config: missing base values');
        }
      } else {
        throw StateError('Failed to load Firebase config: invalid response');
      }
    } catch (e) {
      rethrow;
    }
  }
}
