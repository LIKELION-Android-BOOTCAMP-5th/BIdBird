/// Datasource 싱글톤 관리자
/// 앱 전체에서 사용되는 datasource들을 중앙 집중식으로 관리하여
/// 중복 생성을 방지하고 캐싱 이점을 활용합니다.

import 'package:bidbird/features/item_detail/detail/data/datasources/item_detail_datasource.dart';

class DatasourceManager {
  static final DatasourceManager _instance = DatasourceManager._internal();

  DatasourceManager._internal();

  factory DatasourceManager() {
    return _instance;
  }

  // Datasource 싱글톤 인스턴스들
  late final ItemDetailDatasource _itemDetail = ItemDetailDatasource();

  /// 아이템 상세 정보 조회용 datasource
  ItemDetailDatasource get itemDetail => _itemDetail;
}
