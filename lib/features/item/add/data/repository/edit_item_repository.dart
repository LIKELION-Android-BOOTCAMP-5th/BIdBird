import 'package:bidbird/features/item/add/model/edit_item_entity.dart';
import 'package:bidbird/features/item/add/gateway/edit_item_gateway.dart';

import 'package:bidbird/features/item/add/data/datasource/edit_item_remote_datasource.dart';

class EditItemGatewayImpl implements EditItemGateway {
  EditItemGatewayImpl({EditItemRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? EditItemRemoteDataSource();

  final EditItemRemoteDataSource _dataSource;

  @override
  Future<EditItemEntity> fetchItemForEdit(String itemId) {
    return _dataSource.fetchItemForEdit(itemId);
  }
}
