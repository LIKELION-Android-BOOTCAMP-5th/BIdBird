import 'package:image_picker/image_picker.dart';

abstract class VideoUploadGateway {
  Future<List<String>> uploadVideos(List<XFile> files);
}

