import 'package:bidbird/features/auth/data/data_sources/tos_network_api_datasource.dart';
import 'package:bidbird/features/auth/model/tos_model.dart';

class ToSRepository {
  Future<List<ToSModel>> getToSinfo() async {
    return await ToSNetworkApiDatasource.shared.getToSinfo();
  }
}
