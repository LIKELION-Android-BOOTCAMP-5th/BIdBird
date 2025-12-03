import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

class CloudinaryManager {
  static final CloudinaryManager _shared = CloudinaryManager();
  static CloudinaryManager get shared => _shared;

  Future<String?> uploadImageToCloudinary(XFile inputImage) async {
    // Future<String?> uploadImageToCloudinary() async {

    final XFile image = inputImage;

    if (image == null) return null;

    String cloudName = 'dn12so6sm';
    String uploadPreset = 'bidbird_upload_preset'; // Unsigned 프리셋 이름
    String url = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

    try {
      final String fileName = "${DateTime.now().millisecondsSinceEpoch}";
      String filePath = image.path;
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: '${fileName}.jpg',
        ),
        'upload_preset': uploadPreset,
      });

      Dio dio = Dio();
      Response response = await dio.post(url, data: formData);

      if (response.statusCode == 200) {
        // 업로드 성공, 이미지 URL 반환
        print('Image uploaded successfully: ${response.data['secure_url']}');
        return response.data['secure_url'];
      } else {
        print('Image upload failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<List<String>> uploadImageListToCloudinary(
    List<XFile> ImageList,
  ) async {
    // Future<String?> uploadImageToCloudinary() async {

    final List<XFile> images = ImageList;
    List<String> imageUrlList = [];
    String cloudName = 'dn12so6sm';
    String uploadPreset = 'bidbird_upload_preset'; // Unsigned 프리셋 이름
    String url = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

    try {
      if (images.length != 0) {
        for (var image in images) {
          final String fileName = "${DateTime.now().millisecondsSinceEpoch}";
          String filePath = image.path;
          FormData formData = FormData.fromMap({
            'file': await MultipartFile.fromFile(
              filePath,
              filename: '${fileName}.jpg',
            ),
            'upload_preset': uploadPreset,
          });

          Dio dio = Dio();
          Response response = await dio.post(url, data: formData);

          if (response.statusCode == 200) {
            // 업로드 성공, 이미지 URL 반환
            print(
              'Image uploaded successfully: ${response.data['secure_url']}',
            );
            imageUrlList.add(response.data['secure_url']);
          } else {
            print('Image upload failed with status: ${response.statusCode}');
            return List.empty();
          }
        }
      }
    } catch (e) {
      print('Error uploading image: $e');
      return List.empty();
    }
    return imageUrlList;
  }
}
