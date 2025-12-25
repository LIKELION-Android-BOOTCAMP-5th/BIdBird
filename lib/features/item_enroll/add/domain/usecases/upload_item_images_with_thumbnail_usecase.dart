import 'package:flutter/foundation.dart';

import 'package:bidbird/core/utils/item/media_resizer.dart';
import 'package:bidbird/core/upload/gateways/image_upload_gateway.dart';
import 'package:bidbird/features/item_enroll/add/domain/entities/item_image_upload_result.dart';
import 'package:image_picker/image_picker.dart';

/// 아이템 이미지 및 썸네일 업로드 유즈케이스
class UploadItemImagesWithThumbnailUseCase {
  UploadItemImagesWithThumbnailUseCase(this._imageUploadGateway);

  final ImageUploadGateway _imageUploadGateway;

  /// 이미지 목록과 primaryImageIndex를 받아서 이미지들을 업로드하고 썸네일을 생성하여 업로드
  Future<ItemImageUploadResult> call({
    required List<XFile> images,
    required int primaryImageIndex,
  }) async {
    if (images.isEmpty) {
      throw Exception('이미지가 없습니다.');
    }

    // 1. 메인 이미지들 업로드
    debugPrint('이미지 업로드 시작: ${images.length}개');
    final imageUrls = await _imageUploadGateway.uploadImages(images);
    debugPrint('이미지 업로드 완료: ${imageUrls.length}개 URL 반환');
    
    if (imageUrls.isEmpty) {
      throw Exception('이미지 업로드에 실패했습니다.');
    }
    
    if (imageUrls.length != images.length) {
      debugPrint('경고: 업로드한 이미지 수(${images.length})와 반환된 URL 수(${imageUrls.length})가 다릅니다.');
    }

    // 2. 썸네일 생성 및 업로드 (로컬에서 생성 후 별도 업로드)
    String thumbnailUrl;
    
    if (primaryImageIndex >= 0 && primaryImageIndex < images.length) {
      try {
        final primaryImage = images[primaryImageIndex];
        
        // 로컬에서 썸네일 생성
        final thumbnailFile = await MediaResizer.createThumbnail(primaryImage);
        
        if (thumbnailFile != null) {
          // 썸네일 파일 크기 확인
          final fileLength = await thumbnailFile.length();
          if (fileLength > 0) {
            // 썸네일을 별도로 업로드
            final thumbnailUrls = await _imageUploadGateway.uploadImages([thumbnailFile]);
            if (thumbnailUrls.isNotEmpty) {
              thumbnailUrl = thumbnailUrls.first;
            } else {
              // 썸네일 업로드 실패 시 primaryImageIndex의 이미지 URL 사용
              final index = primaryImageIndex < imageUrls.length ? primaryImageIndex : 0;
              thumbnailUrl = imageUrls[index];
            }
          } else {
            // 썸네일 파일이 비어있으면 primaryImageIndex의 이미지 URL 사용
            final index = primaryImageIndex < imageUrls.length ? primaryImageIndex : 0;
            thumbnailUrl = imageUrls[index];
          }
        } else {
          // 썸네일 생성 실패 시 primaryImageIndex의 이미지 URL 사용
          final index = primaryImageIndex < imageUrls.length ? primaryImageIndex : 0;
          thumbnailUrl = imageUrls[index];
        }
      } catch (e) {
        // 썸네일 생성/업로드 실패 시 primaryImageIndex의 이미지 URL 사용
        final index = primaryImageIndex < imageUrls.length ? primaryImageIndex : 0;
        thumbnailUrl = imageUrls[index];
      }
    } else {
      // primaryImageIndex가 유효하지 않으면 첫 번째 이미지 URL 사용
      thumbnailUrl = imageUrls.first;
    }

    return ItemImageUploadResult(
      imageUrls: imageUrls,
      thumbnailUrl: thumbnailUrl,
    );
  }
}

