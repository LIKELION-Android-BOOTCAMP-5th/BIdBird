import 'package:image_picker/image_picker.dart';

import 'package:bidbird/core/upload/gateways/image_upload_gateway.dart';

class UploadImagesUseCase {
  UploadImagesUseCase(this._gateway);

  final ImageUploadGateway _gateway;

  Future<List<String>> call(List<XFile> files) {
    return _gateway.uploadImages(files);
  }
}

