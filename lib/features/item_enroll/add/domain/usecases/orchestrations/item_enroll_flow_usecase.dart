import 'dart:io';
import 'package:bidbird/core/upload/gateways/nhost_storage_manager.dart';
import 'package:bidbird/features/item_enroll/add/domain/entities/item_add_entity.dart';
import 'package:bidbird/features/item_enroll/add/domain/entities/item_image_upload_result.dart';
import 'package:bidbird/features/item_enroll/add/domain/usecases/add_item_usecase.dart';
import 'package:bidbird/features/item_enroll/add/domain/usecases/upload_item_images_with_thumbnail_usecase.dart';
import 'package:bidbird/features/item_enroll/registration/list/domain/entities/item_registration_entity.dart';
import 'package:image_picker/image_picker.dart';

/// ItemEnroll Flow UseCase - Orchestration Layer
/// 
/// 책임: 상품 등록 전체 플로우 오케스트레이션
/// 1. 이미지 업로드 (썸네일 포함)
/// 2. PDF 보증서 업로드 (Nhost Storage)
/// 3. 상품 정보 저장
/// 4. 결과 반환
sealed class ItemEnrollFlowResult {}

class ItemEnrollFlowSuccess extends ItemEnrollFlowResult {
  ItemEnrollFlowSuccess({required this.itemId});
  final String? itemId;
}

class ItemEnrollFlowFailure extends ItemEnrollFlowResult {
  ItemEnrollFlowFailure({required this.message});
  final String message;
}

class ItemEnrollFlowUseCase {
  ItemEnrollFlowUseCase({
    required UploadItemImagesWithThumbnailUseCase uploadItemImagesUseCase,
    required AddItemUseCase addItemUseCase,
  })  : _uploadItemImagesUseCase = uploadItemImagesUseCase,
        _addItemUseCase = addItemUseCase;

  final UploadItemImagesWithThumbnailUseCase _uploadItemImagesUseCase;
  final AddItemUseCase _addItemUseCase;

  /// 상품 등록 플로우 실행
  /// 
  /// Returns: (success, failure) 튜플
  Future<(ItemEnrollFlowSuccess?, ItemEnrollFlowFailure?)> enroll({
    required ItemAddEntity itemData,
    required List<XFile> images,
    required List<File> documents,
    required int primaryImageIndex,
    required String? editingItemId,
    required Function(double) onProgress,
  }) async {
    try {
      onProgress(0.05);

      // Step 1: 이미지 업로드
      final ItemImageUploadResult? uploadResult = await _uploadImages(
        images: images,
        primaryImageIndex: primaryImageIndex,
        onProgress: onProgress,
      );

      if (uploadResult == null) {
        return (
          null,
          ItemEnrollFlowFailure(message: '이미지 업로드에 실패했습니다.')
        );
      }

      // Step 2: PDF 보증서 업로드 (Nhost Storage)
      onProgress(0.70);
      List<String> documentUrls = [];
      if (documents.isNotEmpty) {
        documentUrls = await NhostStorageManager.shared.uploadFileList(documents);
        // 보증서 업로드 실패 시에도 진행할지 여부는 정책에 따라 다름. 여기서는 계속 진행.
      }

      // Step 3: 상품 정보 저장
      onProgress(0.85);
      final String? itemId = await _saveItem(
        itemData: itemData,
        imageUrls: uploadResult.imageUrls,
        documentUrls: documentUrls,
        thumbnailUrl: uploadResult.thumbnailUrl,
        primaryImageIndex: primaryImageIndex,
        editingItemId: editingItemId,
      );

      if (itemId == null) {
        return (
          null,
          ItemEnrollFlowFailure(message: '상품 등록에 실패했습니다.')
        );
      }

      onProgress(1.0);

      return (ItemEnrollFlowSuccess(itemId: itemId), null);
    } catch (e) {
      return (
        null,
        ItemEnrollFlowFailure(message: '상품 등록 중 오류가 발생했습니다: $e')
      );
    }
  }

  Future<ItemImageUploadResult?> _uploadImages({
    required List<XFile> images,
    required int primaryImageIndex,
    required Function(double) onProgress,
  }) async {
    try {
      onProgress(0.1);
      return await _uploadItemImagesUseCase(
        images: images,
        primaryImageIndex: primaryImageIndex,
      );
    } catch (e) {
      return null;
    }
  }

  Future<String?> _saveItem({
    required ItemAddEntity itemData,
    required List<String> imageUrls,
    required List<String> documentUrls,
    required String thumbnailUrl,
    required int primaryImageIndex,
    required String? editingItemId,
  }) async {
    final updatedData = ItemAddEntity(
      title: itemData.title,
      description: itemData.description,
      startPrice: itemData.startPrice,
      instantPrice: itemData.instantPrice,
      keywordTypeId: itemData.keywordTypeId,
      auctionStartAt: itemData.auctionStartAt,
      auctionEndAt: itemData.auctionEndAt,
      auctionDurationHours: itemData.auctionDurationHours,
      imageUrls: imageUrls,
      documentUrls: documentUrls,
      isAgree: itemData.isAgree,
    );

    final ItemRegistrationData result = await _addItemUseCase(
      entity: updatedData,
      imageUrls: imageUrls,
      primaryImageIndex: primaryImageIndex,
      editingItemId: editingItemId,
      thumbnailUrl: thumbnailUrl,
    );
    
    return result.id;
  }
}
