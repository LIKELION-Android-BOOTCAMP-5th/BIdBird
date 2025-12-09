import 'package:image_picker/image_picker.dart';

import 'image_upload_gateway.dart';

class UploadImagesUseCase {
  UploadImagesUseCase(this._gateway);

  final ImageUploadGateway _gateway;

  Future<List<String>> call(List<XFile> files) {
    return _gateway.uploadImages(files);
  }
}
