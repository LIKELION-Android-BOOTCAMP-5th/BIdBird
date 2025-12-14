import 'dart:io';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/utils/item/item_price_utils.dart' show formatNumber, formatPrice, parseFormattedPrice;
import 'package:bidbird/core/utils/item/item_registration_constants.dart';
import 'package:bidbird/core/utils/item/item_registration_error_messages.dart';
import 'package:bidbird/core/utils/item/item_registration_validator.dart';
import 'package:bidbird/core/utils/item/item_auction_duration_utils.dart';
import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../data/repository/item_add_repository.dart';
import '../data/repository/keyword_repository.dart';
import '../data/repository/edit_item_repository.dart';
import 'package:bidbird/core/upload/repositories/image_upload_repository.dart';
import 'package:bidbird/core/upload/usecases/upload_images_usecase.dart';
import '../model/add_item_usecase.dart';
import '../model/get_edit_item_usecase.dart';
import '../model/get_keyword_types_usecase.dart';
import '../model/item_add_entity.dart';
import '../model/keyword_type_entity.dart';

class ItemAddViewModel extends ChangeNotifier {
  ItemAddViewModel()
    : _addItemUseCase = AddItemUseCase(ItemAddGatewayImpl()),
      _getKeywordTypesUseCase =
          GetKeywordTypesUseCase(KeywordGatewayImpl()),
      _getEditItemUseCase = GetEditItemUseCase(EditItemGatewayImpl()),
      _uploadImagesUseCase =
          UploadImagesUseCase(ImageUploadGatewayImpl());

  final AddItemUseCase _addItemUseCase;
  final GetKeywordTypesUseCase _getKeywordTypesUseCase;
  final GetEditItemUseCase _getEditItemUseCase;
  final UploadImagesUseCase _uploadImagesUseCase;

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
  bool isLoadingKeywords = false;
  bool isSubmitting = false;
  bool useInstantPrice = false;
  int primaryImageIndex = 0;

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
    isLoadingKeywords = true;
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
      isLoadingKeywords = false;
      notifyListeners();
    }
  }

  Future<void> pickImagesFromGallery() async {
    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 80);
    if (images.isEmpty) {
      return;
    }

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

      final int buyNowPrice = editItem.buyNowPrice;
      if (buyNowPrice > 0) {
        useInstantPrice = true;
        instantPriceController.text = formatNumber(buyNowPrice.toString());
      } else {
        useInstantPrice = false;
        instantPriceController.clear();
      }

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
    final List<XFile> files = <XFile>[];

    try {
      // 병렬로 이미지 다운로드
      final results = await Future.wait(
        imageUrls.map((url) async {
          try {
            final response = await dio.get<List<int>>(
              url,
              options: Options(responseType: ResponseType.bytes),
            );

            final String fileName =
                '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch}.jpg';
            final String tempPath = '${Directory.systemTemp.path}/$fileName';
            final file = File(tempPath);
            await file.writeAsBytes(response.data ?? <int>[]);

            return XFile(file.path);
          } catch (e) {
            return null;
          }
        }),
        eagerError: false,
      );

      files.addAll(results.whereType<XFile>());

      if (files.isNotEmpty) {
        selectedImages = files;
        notifyListeners();
      } else {
        // 모든 이미지 다운로드 실패 시 에러
        throw Exception('이미지를 불러올 수 없습니다.');
      }
    } catch (e) {
      // 전체 실패 시에만 에러 처리
      if (files.isEmpty) {
        rethrow;
      }
    }
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
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final String? error = validate();
    if (error != null) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text(error)));
      }
      return;
    }

    final String title = titleController.text.trim();
    final String description = descriptionController.text.trim();
    final int startPrice = parseFormattedPrice(startPriceController.text);
    final int instantPrice = useInstantPrice
        ? parseFormattedPrice(instantPriceController.text)
        : 0;

    isSubmitting = true;
    notifyListeners();

    bool loadingDialogOpen = true;

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

    try {
      if (selectedDuration == null) {
        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('경매 기간을 선택해주세요.')),
          );
        }
        return;
      }
      
      final DateTime now = DateTime.now();
      final int auctionHours = parseAuctionDuration(selectedDuration!);

      final DateTime auctionStartAt = now;
      final DateTime auctionEndAt = now.add(Duration(hours: auctionHours));

      final List<String> imageUrls = await _uploadImagesUseCase(selectedImages);

      if (imageUrls.isEmpty) {
        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text(ItemRegistrationErrorMessages.imageUploadFailed)),
          );
        }
        return;
      }

      final ItemAddEntity data = ItemAddEntity(
        title: title,
        description: description,
        startPrice: startPrice,
        instantPrice: instantPrice,
        keywordTypeId: selectedKeywordTypeId!,
        auctionStartAt: auctionStartAt,
        auctionEndAt: auctionEndAt,
        auctionDurationHours: auctionHours,
        imageUrls: imageUrls,
        isAgree: agreed,
      );

      await _addItemUseCase(
        entity: data,
        imageUrls: imageUrls,
        primaryImageIndex: primaryImageIndex,
        editingItemId: editingItemId,
      );

      if (loadingDialogOpen && navigator.canPop()) {
        navigator.pop();
        loadingDialogOpen = false;
      }

      if (!context.mounted) return;
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
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(ItemRegistrationErrorMessages.registrationError(e))),
        );
      }
    } finally {
      isSubmitting = false;
      notifyListeners();

      if (loadingDialogOpen && navigator.canPop()) {
        navigator.pop();
      }
    }
  }
}
