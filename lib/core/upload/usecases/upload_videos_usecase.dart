import 'package:image_picker/image_picker.dart';

import 'package:bidbird/core/upload/gateways/video_upload_gateway.dart';

class UploadVideosUseCase {
  UploadVideosUseCase(this._gateway);

  final VideoUploadGateway _gateway;

  Future<List<String>> call(List<XFile> files) {
    return _gateway.uploadVideos(files);
  }
}

