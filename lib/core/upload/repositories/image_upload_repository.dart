import 'package:image_picker/image_picker.dart';

import 'package:bidbird/core/upload/datasources/image_upload_datasource.dart';
import 'package:bidbird/core/upload/gateways/image_upload_gateway.dart';

class ImageUploadGatewayImpl implements ImageUploadGateway {
  ImageUploadGatewayImpl({ImageUploadDataSource? dataSource})
      : _dataSource = dataSource ?? ImageUploadDataSource();

  final ImageUploadDataSource _dataSource;

  @override
  Future<List<String>> uploadImages(List<XFile> files) {
    return _dataSource.uploadImages(files);
  }
}
