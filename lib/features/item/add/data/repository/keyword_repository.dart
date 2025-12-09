import 'package:bidbird/features/item/add/data/datasources/keyword_remote_datasource.dart';
import 'package:bidbird/features/item/add/model/keyword_gateway.dart';
import 'package:bidbird/features/item/add/model/keyword_type_entity.dart';

class KeywordGatewayImpl implements KeywordGateway {
  KeywordGatewayImpl({KeywordRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? KeywordRemoteDataSource();

  final KeywordRemoteDataSource _dataSource;

  @override
  Future<List<KeywordTypeEntity>> fetchKeywordTypes() {
    return _dataSource.fetchKeywordTypes();
  }
}
