import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecureLocalStorage extends LocalStorage {
  final FlutterSecureStorage storage;

  const SecureLocalStorage()
      : storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        );

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    return await storage.containsKey(key: supabasePersistSessionKey);
  }

  @override
  Future<String?> accessToken() async {
    return await storage.read(key: supabasePersistSessionKey);
  }

  @override
  Future<void> removePersistedSession() async {
    await storage.delete(key: supabasePersistSessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    await storage.write(key: supabasePersistSessionKey, value: persistSessionString);
  }
}
