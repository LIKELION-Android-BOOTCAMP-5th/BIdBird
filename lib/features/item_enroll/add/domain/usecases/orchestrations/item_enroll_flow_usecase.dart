import 'dart:io';
import 'package:bidbird/core/managers/nhost_manager.dart';
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
    List<String>? documentOriginalNames,
    List<int>? documentSizes,
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
      // 원격 URL은 그대로 유지하고, 로컬 파일만 업로드
      onProgress(0.70);
      List<String> docUrls = [];
      List<String> docNames = [];
      List<int> docSizes = [];
      
      for (int i = 0; i < documents.length; i++) {
        final file = documents[i];
        final filePath = file.path;
        
        // URL인지 확인 (http:// 또는 https://로 시작)
        final isRemoteUrl = filePath.startsWith('http://') || filePath.startsWith('https://');
        
        if (isRemoteUrl) {
          docUrls.add(filePath);
          docNames.add(
            (documentOriginalNames != null && documentOriginalNames.length > i)
                ? documentOriginalNames[i]
                : filePath.split('/').last,
          );
          docSizes.add(
            (documentSizes != null && documentSizes.length > i)
                ? documentSizes[i]
                : 0,
          );
        } else {
          // 로컬 파일은 업로드
          final originalName = (documentOriginalNames != null && documentOriginalNames.length > i)
              ? documentOriginalNames[i]
              : null;
          final uploadedDoc = await NhostStorageManager.shared.uploadFile(
            file,
            originalName: originalName,
          );
          
          if (uploadedDoc != null) {
            docUrls.add(uploadedDoc['url']!);
            docNames.add(uploadedDoc['name']!);
            docSizes.add(int.tryParse(uploadedDoc['size'] ?? '0') ?? 0);
          }
        }
      }

      // Step 3: 상품 정보 저장
      onProgress(0.85);
      final String? itemId = await _saveItem(
        itemData: itemData,
        imageUrls: uploadResult.imageUrls,
        documentUrls: docUrls,
        documentNames: docNames,
        documentSizes: docSizes,
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

      // Step 4: nhost 함수 호출하여 PDF 문서를 DB에 저장
      if (docUrls.isNotEmpty) {
        onProgress(0.95);
        try {
          await NhostManager.shared.invokeFunction(
            'update-item-v2',
            body: {
              'itemId': itemId,
              'documentUrls': docUrls,
              'documentNames': docNames,
            },
          );
        } catch (e) {
          // PDF 동기화 실패해도 상품 등록은 성공으로 처리
        }
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
    required List<String> documentNames,
    required List<int> documentSizes,
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
      documentNames: documentNames,
      documentSizes: documentSizes,
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
