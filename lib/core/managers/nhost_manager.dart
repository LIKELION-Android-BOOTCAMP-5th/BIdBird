import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:nhost_flutter_auth/nhost_flutter_auth.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NhostManager {
  static final NhostManager _shared = NhostManager();
  static NhostManager get shared => _shared;

  NhostClient? _nhostClient;
  ValueNotifier<GraphQLClient>? _graphqlClient;
  bool _isInitialized = false;

  NhostClient get nhostClient {
    if (!_isInitialized || _nhostClient == null) {
      throw StateError('NhostManager not initialized. Call initialize() first.');
    }
    return _nhostClient!;
  }

  ValueNotifier<GraphQLClient> get graphqlClient {
    if (!_isInitialized || _graphqlClient == null) {
      throw StateError('NhostManager not initialized. Call initialize() first.');
    }
    return _graphqlClient!;
  }

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final supabase = SupabaseManager.shared.supabase;
      final response = await supabase.functions.invoke(
        'nhost-config',
        method: HttpMethod.get,
      );

      final data = response.data;
      if (data is Map && data['success'] == true && data['data'] is Map) {
        final configData = data['data'] as Map;
        final subdomain = configData['subdomain'] as String?;
        final region = configData['region'] as String?;

        if (subdomain == null || region == null) {
          throw StateError('Failed to load Nhost config: missing subdomain or region');
        }

        _nhostClient = NhostClient(
          subdomain: Subdomain(subdomain: subdomain, region: region),
        );

        _initGraphQL(subdomain, region);
        _isInitialized = true;
        debugPrint('NhostManager initialized successfully');
      } else {
        throw StateError('Failed to load Nhost config: invalid response');
      }
    } catch (e) {
      debugPrint('NhostManager initialization error: $e');
      rethrow;
    }
  }

  void _initGraphQL(String subdomain, String region) {
    // 2.2.0 버전에서는 httpUrl, graphqlUrl 등을 직접 쓰거나 NhostClient에서 제공하는 멤버를 쓸 수 있음
    // 보통 https://$subdomain.graphql.$region.nhost.run/v1 형식이지만, 
    // NhostClient에 관련 getter가 있을 수 있음.
    final httpLink = HttpLink('https://$subdomain.graphql.$region.nhost.run/v1');
    
    final authLink = AuthLink(
      getToken: () async {
        // NhostAuthClient 2.6.x 에서는 accessToken이 바로 있을 가능성이 높음
        return _nhostClient?.auth.accessToken != null 
            ? 'Bearer ${_nhostClient!.auth.accessToken}' 
            : null;
      },
    );

    final link = authLink.concat(httpLink);

    _graphqlClient = ValueNotifier(
      GraphQLClient(
        link: link,
        cache: GraphQLCache(store: HiveStore()),
      ),
    );
  }

  bool get isAuthenticated => _nhostClient?.auth.currentUser != null;
  String? get userId => _nhostClient?.auth.currentUser?.id;
  String? get accessToken => _nhostClient?.auth.accessToken;
}
