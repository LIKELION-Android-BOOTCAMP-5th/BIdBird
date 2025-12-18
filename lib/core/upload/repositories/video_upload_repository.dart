import 'package:image_picker/image_picker.dart';

import 'package:bidbird/core/upload/datasources/video_upload_datasource.dart';
import 'package:bidbird/core/upload/gateways/video_upload_gateway.dart';

class VideoUploadGatewayImpl implements VideoUploadGateway {
  VideoUploadGatewayImpl({VideoUploadDataSource? dataSource})
      : _dataSource = dataSource ?? VideoUploadDataSource();

  final VideoUploadDataSource _dataSource;

  @override
  Future<List<String>> uploadVideos(List<XFile> files) {
    return _dataSource.uploadVideos(files);
  }
}



