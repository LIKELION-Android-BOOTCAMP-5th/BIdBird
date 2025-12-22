import 'dart:io';
import 'dart:typed_data';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/utils/item/item_price_utils.dart' show formatNumber, parseFormattedPrice;
import 'package:bidbird/core/utils/item/item_registration_constants.dart';
import 'package:bidbird/features/item_enroll/add/domain/entities/item_registration_error_messages.dart';
import 'package:bidbird/features/item_enroll/add/domain/entities/item_registration_validator.dart';
import 'package:bidbird/core/utils/item/item_auction_duration_utils.dart';
import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
import 'package:bidbird/core/managers/item_image_cache_manager.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:bidbird/core/viewmodels/item_base_viewmodel.dart';
import 'package:bidbird/features/item_enroll/add/data/repositories/item_add_repository.dart';
import 'package:bidbird/features/item_enroll/add/data/repositories/keyword_repository.dart';
import 'package:bidbird/features/item_enroll/add/data/repositories/edit_item_repository.dart';
import 'package:bidbird/features/item_enroll/add/domain/usecases/add_item_usecase.dart';
import 'package:bidbird/features/item_enroll/add/domain/usecases/get_edit_item_usecase.dart';
import 'package:bidbird/features/item_enroll/add/domain/usecases/get_keyword_types_usecase.dart';
import 'package:bidbird/features/item_enroll/add/domain/usecases/upload_item_images_with_thumbnail_usecase.dart';
import 'package:bidbird/features/item_enroll/add/domain/entities/item_add_entity.dart';
import 'package:bidbird/features/item_enroll/add/domain/entities/item_image_upload_result.dart';
import 'package:bidbird/features/item_enroll/add/domain/entities/keyword_type_entity.dart';
import 'package:bidbird/core/upload/gateways/image_upload_gateway.dart';
import 'package:bidbird/core/upload/repositories/image_upload_repository.dart';

class ItemAddViewModel extends ItemBaseViewModel {
  ItemAddViewModel()
    : _addItemUseCase = AddItemUseCase(ItemAddRepositoryImpl()),
      _getKeywordTypesUseCase =
          GetKeywordTypesUseCase(KeywordRepositoryImpl()),
      _getEditItemUseCase = GetEditItemUseCase(EditItemRepositoryImpl()),
      _uploadItemImagesWithThumbnailUseCase =
          UploadItemImagesWithThumbnailUseCase(ImageUploadGatewayImpl());

  final AddItemUseCase _addItemUseCase;
  final GetKeywordTypesUseCase _getKeywordTypesUseCase;
  final GetEditItemUseCase _getEditItemUseCase;
  final UploadItemImagesWithThumbnailUseCase _uploadItemImagesWithThumbnailUseCase;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController startPriceController = TextEditingController();
  final TextEditingController instantPriceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  List<XFile> selectedImages = <XFile>[];
  final List<KeywordTypeEntity> keywordTypes = <KeywordTypeEntity>[];

  final List<String> durations = ItemAuctionDurationConstants.durationOptions;

  String? editingItemId;
  int? selectedKeywordTypeId;
  String? selectedDuration;
  bool agreed = false;
  bool _isLoadingKeywords = false;
  bool _isSubmitting = false;
  bool useInstantPrice = false;
  int primaryImageIndex = 0;

  bool get isLoadingKeywords => _isLoadingKeywords;
  bool get isSubmitting => _isSubmitting;

  void disposeControllers() {
    titleController.dispose();
    startPriceController.dispose();
    instantPriceController.dispose();
    descriptionController.dispose();
  }

  @override
  void dispose() {
    disposeControllers();
    _dio?.close();
    _dio = null;
    super.dispose();
  }

  Future<void> init() async {
    await fetchKeywordTypes();
  }

  Future<void> fetchKeywordTypes() async {
    _isLoadingKeywords = true;
    notifyListeners();

    try {
      final types = await _getKeywordTypesUseCase();
      final filtered = types.where((e) => e.title != '전체');
      keywordTypes
        ..clear()
        ..addAll(filtered);

      // 현재 선택된 카테고리가 필터링된 목록에 없다면 초기화
      final validIds = keywordTypes.map((e) => e.id).toSet();
      if (selectedKeywordTypeId != null &&
          !validIds.contains(selectedKeywordTypeId)) {
        selectedKeywordTypeId = null;
      }
    } catch (e) {
      throw Exception(ItemRegistrationErrorMessages.categoryLoadError(e));
    } finally {
      _isLoadingKeywords = false;
      notifyListeners();
    }
  }

  Future<void> pickImagesFromGallery() async {
    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 80);
    if (images.isEmpty) {
      return;
    }

    // 리사이징은 upload datasource에서 처리
    final List<XFile> all = <XFile>[...selectedImages, ...images];
    if (all.length > ItemImageLimits.maxImageCount) {
      selectedImages = all.take(ItemImageLimits.maxImageCount).toList();
    } else {
      selectedImages = all;
    }
    notifyListeners();
  }

  Future<void> pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (image == null) return;

    if (selectedImages.length >= ItemImageLimits.maxImageCount) {
      return;
    }

    // 리사이징은 upload datasource에서 처리
    selectedImages = <XFile>[...selectedImages, image];
    notifyListeners();
  }

  Future<void> pickVideoFromGallery() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.gallery,
    );
    if (video == null) {
      return;
    }

    if (selectedImages.length >= ItemImageLimits.maxImageCount) {
      return;
    }

    // 리사이징은 upload datasource에서 처리
    selectedImages = <XFile>[...selectedImages, video];
    notifyListeners();
  }

  void removeImageAt(int index) {
    if (index < 0 || index >= selectedImages.length) return;
    final List<XFile> list = List<XFile>.from(selectedImages);
    list.removeAt(index);
    selectedImages = list;

    if (selectedImages.isEmpty) {
      primaryImageIndex = 0;
    } else {
      if (primaryImageIndex == index) {
        primaryImageIndex = 0;
      } else if (index < primaryImageIndex) {
        primaryImageIndex = primaryImageIndex - 1;
      }
    }
    notifyListeners();
  }

  void setPrimaryImage(int index) {
    if (index < 0 || index >= selectedImages.length) return;
    primaryImageIndex = index;
    notifyListeners();
  }

  Future<void> startEdit(String itemId) async {
    editingItemId = itemId;
    try {

      if (keywordTypes.isEmpty) {
        await fetchKeywordTypes();
      }

      final editItem = await _getEditItemUseCase(itemId);

      titleController.text = editItem.title;
      descriptionController.text = editItem.description;

      final int startPrice = editItem.startPrice;
      if (startPrice > 0) {
        startPriceController.text = formatNumber(startPrice.toString());
      }

      // final int buyNowPrice = editItem.buyNowPrice;
      // if (buyNowPrice > 0) {
      //   useInstantPrice = true;
      //   instantPriceController.text = formatNumber(buyNowPrice.toString());
      // } else {
      //   useInstantPrice = false;
      //   instantPriceController.clear();
      // }
      useInstantPrice = false;
      instantPriceController.clear();

      selectedKeywordTypeId = editItem.keywordTypeId;

      final int durationHours = editItem.auctionDurationHours;
      selectedDuration = formatAuctionDurationForDisplay(durationHours);

      notifyListeners();

      try {
        await loadExistingImages(editItem.imageUrls);
      } catch (e) {
        // 이미지 로드 실패 시에도 수정은 계속 진행 가능
        // 에러는 로그에만 남기고 사용자에게는 알리지 않음
      }
    } catch (e) {
      // 실패해도 새로 작성할 수 있도록 조용히 무시
    }
  }

  Dio? _dio;

  /// 수정 모드에서 기존 이미지를 불러와 selectedImages에 채웁니다.
  Future<void> loadExistingImages(List<String> imageUrls) async {
    if (imageUrls.isEmpty) return;

    _dio ??= Dio();
    final dio = _dio!;

    try {
      final files = await _downloadImagesInParallel(dio, imageUrls);

      if (files.isEmpty) {
        throw Exception('이미지를 불러올 수 없습니다.');
      }

      selectedImages = files;
      notifyListeners();
    } catch (e) {
      // 이미지 로드 실패 시 에러 재발생
      rethrow;
    }
  }

  /// 병렬로 이미지를 다운로드합니다.
  Future<List<XFile>> _downloadImagesInParallel(
    Dio dio,
    List<String> imageUrls,
  ) async {
    final results = await Future.wait(
      imageUrls.map((url) => _downloadSingleImage(dio, url)),
      eagerError: false,
    );

    return results.whereType<XFile>().toList();
  }

  /// 단일 이미지를 다운로드합니다.
  /// 캐시를 먼저 확인하고, 없으면 다운로드합니다.
  Future<XFile?> _downloadSingleImage(Dio dio, String url) async {
    try {
      // 캐시에서 먼저 확인
      final cacheManager = ItemImageCacheManager.instance;
      final cachedFile = await cacheManager.getSingleFile(url);
      
      if (await cachedFile.exists()) {
        // 캐시된 파일이 있으면 사용
        return XFile(cachedFile.path);
      }
      
      // 캐시에 없으면 다운로드
      final response = await dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );

      final fileName = _generateTempFileName();
      final tempPath = '${Directory.systemTemp.path}/$fileName';
      final file = File(tempPath);
      await file.writeAsBytes(response.data ?? <int>[]);

      // 다운로드한 파일을 캐시에 저장
      try {
        final bytes = response.data;
        if (bytes != null) {
          await cacheManager.putFile(url, Uint8List.fromList(bytes));
        }
      } catch (e) {
        // 캐시 저장 실패해도 파일은 반환
      }

      return XFile(file.path);
    } catch (e) {
      return null;
    }
  }

  /// 임시 파일명을 생성합니다.
  String _generateTempFileName() {
    final timestamp = DateTime.now();
    return '${timestamp.millisecondsSinceEpoch}_${timestamp.microsecondsSinceEpoch}.jpg';
  }

  String? validate() {
    final int startPrice = parseFormattedPrice(startPriceController.text);
    final int? instantPrice = useInstantPrice
        ? parseFormattedPrice(instantPriceController.text)
        : null;

    return ItemRegistrationValidator.validateForUI(
      title: titleController.text,
      description: descriptionController.text,
      keywordTypeId: selectedKeywordTypeId,
      startPrice: startPrice,
      instantPrice: instantPrice,
      useInstantPrice: useInstantPrice,
      images: selectedImages,
    );
  }

  void setSelectedKeywordTypeId(int? id) {
    selectedKeywordTypeId = id;
    notifyListeners();
  }

  void setSelectedDuration(String value) {
    selectedDuration = value;
    notifyListeners();
  }

  void setUseInstantPrice(bool value) {
    useInstantPrice = value;
    if (!value) {
      instantPriceController.clear();
    }
    notifyListeners();
  }

  Future<void> submit(BuildContext context) async {
    // 중복 제출 방지
    if (_isSubmitting) {
      return;
    }

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (!_validateSubmission(context, scaffoldMessenger)) {
      return;
    }

    _isSubmitting = true;
    notifyListeners();

    bool loadingDialogOpen = true;
    _showLoadingDialog(context);

    try {
      final itemData = _prepareItemData();
      if (itemData == null) {
        _showError(context, scaffoldMessenger, '경매 기간을 선택해주세요.');
        return;
      }

      final uploadResult = await _uploadItemImagesWithThumbnail(context, scaffoldMessenger);
      if (uploadResult == null) {
        return;
      }

      await _saveItem(itemData, uploadResult.imageUrls, uploadResult.thumbnailUrl);

      _closeLoadingDialog(navigator, loadingDialogOpen);
      loadingDialogOpen = false;

      if (!context.mounted) return;
      await _showSuccessDialog(context, navigator);
    } catch (e) {
      if (context.mounted) {
        _showError(context, scaffoldMessenger, ItemRegistrationErrorMessages.registrationError(e));
      }
    } finally {
      _isSubmitting = false;
      notifyListeners();
      _closeLoadingDialog(navigator, loadingDialogOpen);
    }
  }

  bool _validateSubmission(BuildContext context, ScaffoldMessengerState scaffoldMessenger) {
    final String? error = validate();
    if (error != null) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text(error)));
      }
      return false;
    }
    return true;
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final spacing = dialogContext.inputPadding;
        final fontSize = dialogContext.fontSizeMedium;

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(blueColor),
              ),
              SizedBox(height: spacing),
              Text(
                '로딩중',
                style: TextStyle(
                  fontSize: fontSize,
                  color: textColor,
                  decoration: TextDecoration.none,
                  decorationColor: Colors.transparent,
                  decorationThickness: 0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  ItemAddEntity? _prepareItemData() {
    if (selectedDuration == null) {
      return null;
    }

    final String title = titleController.text.trim();
    final String description = descriptionController.text.trim();
    final int startPrice = parseFormattedPrice(startPriceController.text);
    final int instantPrice = useInstantPrice
        ? parseFormattedPrice(instantPriceController.text)
        : 0;

    final DateTime now = DateTime.now();
    final int auctionHours = parseAuctionDuration(selectedDuration!);

    return ItemAddEntity(
      title: title,
      description: description,
      startPrice: startPrice,
      instantPrice: instantPrice,
      keywordTypeId: selectedKeywordTypeId!,
      auctionStartAt: now,
      auctionEndAt: now.add(Duration(hours: auctionHours)),
      auctionDurationHours: auctionHours,
      imageUrls: [], // 이미지 URL은 업로드 후 설정
      isAgree: agreed,
    );
  }

  Future<ItemImageUploadResult?> _uploadItemImagesWithThumbnail(
    BuildContext context,
    ScaffoldMessengerState scaffoldMessenger,
  ) async {
    try {
      // 유즈케이스를 사용하여 이미지 및 썸네일 업로드
      final result = await _uploadItemImagesWithThumbnailUseCase(
        images: selectedImages,
        primaryImageIndex: primaryImageIndex,
      );

      return result;
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(ItemRegistrationErrorMessages.imageUploadFailed)),
        );
      }
      return null;
    }
  }

  Future<void> _saveItem(
    ItemAddEntity itemData,
    List<String> imageUrls,
    String? thumbnailUrl,
  ) async {
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
      isAgree: itemData.isAgree,
    );

    await _addItemUseCase(
      entity: updatedData,
      imageUrls: imageUrls,
      primaryImageIndex: primaryImageIndex,
      editingItemId: editingItemId,
      thumbnailUrl: thumbnailUrl,
    );
  }

  Future<void> _showSuccessDialog(BuildContext context, NavigatorState navigator) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          // Pop is prevented by canPop: false
        },
        child: AskPopup(
          content: '매물 등록 확인 화면으로 이동하여\n최종 등록을 진행해 주세요.',
          yesText: '이동하기',
          yesLogic: () async {
            navigator.pop();
            if (!context.mounted) return;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              context.go('/add_item/item_registration_list');
            });
          },
        ),
      ),
    );
  }

  void _showError(
    BuildContext context,
    ScaffoldMessengerState scaffoldMessenger,
    String message,
  ) {
    if (context.mounted) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _closeLoadingDialog(NavigatorState navigator, bool isOpen) {
    if (isOpen && navigator.canPop()) {
      navigator.pop();
    }
  }
}

