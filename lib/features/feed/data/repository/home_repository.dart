import 'package:bidbird/features/feed/domain/entities/items_entity.dart';
import 'package:bidbird/features/feed/domain/entities/keywordType_entity.dart';
import 'package:bidbird/features/feed/domain/repositories/home_repository.dart'
    as domain;

import '../data_sources/home_network_api_datasource.dart';

class HomeRepositoryImpl implements domain.HomeRepository {
  final HomeNetworkApiManager _apiDatasource;

  HomeRepositoryImpl({HomeNetworkApiManager? apiDatasource})
    : _apiDatasource = apiDatasource ?? HomeNetworkApiManager();

  @override
  Future<List<KeywordType>> getKeywordType() {
    return _apiDatasource.getKeywordType();
  }

  @override
  Future<List<ItemsEntity>> fetchItems(
    String orderBy, {
    int currentIndex = 1,
    int? keywordType,
  }) {
    return _apiDatasource.getItems(
      orderBy,
      currentIndex: currentIndex,
      keywordType: keywordType,
    );
  }

  @override
  Future<List<ItemsEntity>> fetchSearchResult(
    String orderBy, {
    int currentIndex = 1,
    int? keywordType,
    String? userInputSearchText,
  }) {
    return _apiDatasource.getSearchResults(
      orderBy,
      currentIndex: currentIndex,
      keywordType: keywordType,
      userInputSearchText: userInputSearchText,
    );
  }
}
