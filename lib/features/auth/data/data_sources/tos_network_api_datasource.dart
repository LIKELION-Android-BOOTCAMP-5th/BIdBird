import 'package:bidbird/core/managers/network_api_manager.dart';
import 'package:bidbird/features/auth/model/tos_model.dart';
import 'package:dio/dio.dart';

class ToSNetworkApiDatasource {
  static final ToSNetworkApiDatasource _shared = ToSNetworkApiDatasource();
  static ToSNetworkApiDatasource get shared => _shared;

  final dio = Dio();

  Future<List<ToSModel>> getToSinfo() async {
    final response = await dio.get(
      '${NetworkApiManager.supabaseUrl}/tos?select=*',
      options: Options(headers: NetworkApiManager.useThisHeaders()),
    );

    final List<dynamic> data = response.data;
    final List<ToSModel> results = data.map((json) {
      return ToSModel.fromJson(json);
    }).toList();

    return results;
  }
}
