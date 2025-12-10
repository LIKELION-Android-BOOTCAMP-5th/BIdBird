import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:dio/dio.dart';

class NetworkApiManager {
  static final NetworkApiManager _shared = NetworkApiManager();

  static NetworkApiManager get shared => _shared;
  final dio = Dio();

  NetworkApiManager() {}

  static final String supabaseUrl =
      "https://mdwelwjletorehxsptqa.supabase.co/rest/v1";
  static final String apikey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kd2Vsd2psZXRvcmVoeHNwdHFhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQyOTEwNzksImV4cCI6MjA3OTg2NzA3OX0.tpCDNi74KoMcpr3BN7D6fT2SxsteCM9sf7RrEwnVPHg';
  static final Map<String, dynamic> headers = {
    'apikey': apikey,
    'Authorization': SupabaseManager.shared.getAuthorizationKey(),
    'Content-Type': 'application/json',
  };
}
