import 'package:image_picker/image_picker.dart';

abstract class ImageUploadGateway {
  Future<List<String>> uploadImages(List<XFile> files);
}

