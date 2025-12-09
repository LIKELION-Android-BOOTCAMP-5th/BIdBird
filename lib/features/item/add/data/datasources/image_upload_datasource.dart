import 'package:bidbird/core/managers/cloudinary_manager.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploadDataSource {
  Future<List<String>> uploadImages(List<XFile> files) {
    return CloudinaryManager.shared.uploadImageListToCloudinary(files);
  }
}
