import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bidbird/core/managers/item_image_cache_manager.dart';
import 'package:bidbird/core/upload/progress/upload_progress_bus.dart';
import 'package:bidbird/core/upload/repositories/image_upload_repository.dart';
import 'package:bidbird/core/utils/item/item_auction_duration_utils.dart';
import 'package:bidbird/core/utils/item/item_price_utils.dart'
    show parseFormattedPrice, formatNumber;
import 'package:bidbird/core/utils/item/item_registration_constants.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/viewmodels/item_base_viewmodel.dart';
import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
import 'package:bidbird/features/item_enroll/add/data/repositories/edit_item_repository.dart';
import 'package:bidbird/features/item_enroll/add/data/repositories/item_add_repository.dart';
import 'package:bidbird/features/item_enroll/add/data/repositories/keyword_repository.dart';
import 'package:bidbird/features/item_enroll/add/domain/entities/item_add_entity.dart';
import 'package:bidbird/features/item_enroll/add/domain/entities/item_registration_error_messages.dart';
import 'package:bidbird/features/item_enroll/add/domain/entities/item_registration_validator.dart';
import 'package:bidbird/features/item_enroll/add/domain/entities/keyword_type_entity.dart';
import 'package:bidbird/features/item_enroll/add/domain/usecases/add_item_usecase.dart';
import 'package:bidbird/features/item_enroll/add/domain/usecases/get_edit_item_usecase.dart';
import 'package:bidbird/features/item_enroll/add/domain/usecases/get_keyword_types_usecase.dart';
import 'package:bidbird/features/item_enroll/add/domain/usecases/orchestrations/item_enroll_flow_usecase.dart';
import 'package:bidbird/features/item_enroll/add/domain/usecases/upload_item_images_with_thumbnail_usecase.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PickedDocument {
  final File file;
  final String originalName;
  final int size;
  PickedDocument({
    required this.file,
    required this.originalName,
    required this.size,
  });

  String get path => file.path;
}

/// ItemAdd ViewModel - Thin Pattern
/// 책임: UI 상태 관리, Flow UseCase 호출
/// 제외: 비즈니스 로직 (Flow UseCase에서 처리)
class ItemAddViewModel extends ItemBaseViewModel {
  ItemAddViewModel()
    : _getKeywordTypesUseCase = GetKeywordTypesUseCase(KeywordRepositoryImpl()),
      _getEditItemUseCase = GetEditItemUseCase(EditItemRepositoryImpl()),
      _itemEnrollFlowUseCase = ItemEnrollFlowUseCase(
        uploadItemImagesUseCase: UploadItemImagesWithThumbnailUseCase(
          ImageUploadGatewayImpl(),
        ),
        addItemUseCase: AddItemUseCase(ItemAddRepositoryImpl()),
      );

  final GetKeywordTypesUseCase _getKeywordTypesUseCase;
  final GetEditItemUseCase _getEditItemUseCase;
  final ItemEnrollFlowUseCase _itemEnrollFlowUseCase;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController startPriceController = TextEditingController();
  final TextEditingController instantPriceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  List<XFile> selectedImages = <XFile>[];
  List<PickedDocument> selectedDocuments = <PickedDocument>[]; // PDF 보증서 목록
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

  final StreamController<double> _progressController =
      StreamController<double>.broadcast();
  Stream<double> get uploadProgressStream => _progressController.stream;

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
    _progressController.close();
    super.dispose();
  }

  Future<void> init() async {
    editingItemId = null; // 신규 작성을 위해 초기화
    await fetchKeywordTypes();
  }

  Future<void> fetchKeywordTypes() async {
    if (_isLoadingKeywords) return; // 중복 호출 방지

    _isLoadingKeywords = true;
    notifyListeners(); // 로딩 상태만 알림

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

      _isLoadingKeywords = false;
      notifyListeners(); // 완료 상태만 알림
    } catch (e) {
      _isLoadingKeywords = false;
      notifyListeners(); // 에러 상태 알림
      throw Exception(ItemRegistrationErrorMessages.categoryLoadError(e));
    }
  }

  Future<void> pickImagesFromGallery() async {
    final List<XFile> images = await _picker.pickMultiImage();
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
    notifyListeners(); // 이미지 추가 시 UI 업데이트 필요
  }

  Future<void> pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    if (selectedImages.length >= ItemImageLimits.maxImageCount) {
      return;
    }

    // 리사이징은 upload datasource에서 처리
    selectedImages = <XFile>[...selectedImages, image];
    notifyListeners(); // 이미지 추가 시 UI 업데이트 필요
  }

  Future<void> pickVideoFromGallery() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video == null) {
      return;
    }

    if (selectedImages.length >= ItemImageLimits.maxImageCount) {
      return;
    }

    // 리사이징은 upload datasource에서 처리
    selectedImages = <XFile>[...selectedImages, video];
    notifyListeners(); // 비디오 추가 시 UI 업데이트 필요
  }

  /// PDF 보증서 선택
  Future<void> pickDocuments() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (result != null) {
        final List<PickedDocument> newDocs = result.files
            .where((file) => file.path != null)
            .map((file) {
              return PickedDocument(
                file: File(file.path!),
                originalName: file.name,
                size: file.size,
              );
            })
            .toList();

        // 최대 5개 제한 (필요 시 조정)
        if (selectedDocuments.length + newDocs.length > 5) {
          // 5개까지만 추가
          final remaining = 5 - selectedDocuments.length;
          if (remaining > 0) {
            selectedDocuments.addAll(newDocs.take(remaining));
          }
        } else {
          selectedDocuments.addAll(newDocs);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error picking documents: $e');
    }
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
    notifyListeners(); // 이미지 제거 시 UI 업데이트 필요
  }

  /// 보증서 삭제
  void removeDocumentAt(int index) {
    if (index < 0 || index >= selectedDocuments.length) return;
    selectedDocuments.removeAt(index);
    notifyListeners();
  }

  void setPrimaryImage(int index) {
    if (index < 0 || index >= selectedImages.length) return;
    primaryImageIndex = index;
    notifyListeners(); // 기본 이미지 변경 시 UI 업데이트 필요
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
        await Future.wait([
          loadExistingImages(editItem.imageUrls),
          loadExistingDocuments(
            editItem.documentUrls,
            editItem.documentNames,
            editItem.documentSizes,
          ),
        ]);
      } catch (e) {
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
        // 다운로드 실패 시에도 네트워크 URL을 직접 표시하도록 폴백
        selectedImages = imageUrls.map((u) => XFile(u)).toList();
      } else {
        selectedImages = files;
      }
      notifyListeners(); // 이미지 로드 시 UI 업데이트 필요
    } catch (e) {
      // 완전 실패 시에도 네트워크 URL로 폴백
      selectedImages = imageUrls.map((u) => XFile(u)).toList();
      notifyListeners(); // 실패 시에도 UI 업데이트 필요
    }
  }

  /// 수정 모드에서 기존 문서를 불러와 selectedDocuments에 채웁니다.
  Future<void> loadExistingDocuments(
    List<String> documentUrls,
    List<String>? documentNames,
    List<int>? documentSizes,
  ) async {
    if (documentUrls.isEmpty) return;

    _dio ??= Dio();
    final dio = _dio!;

    try {
      final results = await Future.wait(
        documentUrls.asMap().entries.map((entry) {
          final idx = entry.key;
          final url = entry.value;
          final name = (documentNames != null && documentNames.length > idx)
              ? documentNames[idx]
              : null;
          final size = (documentSizes != null && documentSizes.length > idx)
              ? documentSizes[idx]
              : 0;
          return _downloadSingleDocument(
            dio,
            url,
            originalName: name,
            originalSize: size,
          );
        }),
        eagerError: false,
      );

      final docs = results.whereType<PickedDocument>().toList();
      if (docs.isNotEmpty) {
        selectedDocuments = docs;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading existing documents: $e');
    }
  }

  Future<PickedDocument?> _downloadSingleDocument(
    Dio dio,
    String url, {
    String? originalName,
    int? originalSize,
  }) async {
    try {
      final response = await dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );

      final fileName = originalName ?? url.split('/').last;
      final size = originalSize ?? (response.data?.length ?? 0);

      final tempPath =
          '${Directory.systemTemp.path}/${url.split('/').last}'; // Keep UUID for temp file system
      final file = File(tempPath);
      await file.writeAsBytes(response.data ?? <int>[]);

      return PickedDocument(file: file, originalName: fileName, size: size);
    } catch (e) {
      return null;
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
    notifyListeners(); // 카테고리 선택 UI 업데이트 필요
  }

  void setSelectedDuration(String value) {
    selectedDuration = value;
    notifyListeners(); // 기간 선택 UI 업데이트 필요
  }

  void setUseInstantPrice(bool value) {
    useInstantPrice = value;
    if (!value) {
      instantPriceController.clear();
    }
    notifyListeners(); // 즉시가 체크박스 UI 업데이트 필요
  }

  // Methods: Submit (Delegate to Flow UseCase)
  Future<void> submit(BuildContext context) async {
    if (_isSubmitting) return;

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final String? validationError = validate();
    if (validationError != null) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(validationError)),
        );
      }
      return;
    }

    _isSubmitting = true;
    notifyListeners(); // 제출 시작 상태 UI 업데이트 필요

    // 업로드 진행률: Cloudinary ProgressBus -> UI Progress
    final int uploadFileCount = selectedImages.where((x) {
      final uri = Uri.tryParse(x.path);
      return !(uri != null && (uri.scheme == 'http' || uri.scheme == 'https'));
    }).length;

    final Map<String, double> fileProgress = {};
    late final StreamSubscription progressSub;
    progressSub = UploadProgressBus.instance.stream.listen((event) {
      if (uploadFileCount == 0) return;
      fileProgress[event.filePath] = event.progress.clamp(0.0, 1.0);
      final double sum = fileProgress.values.fold(0.0, (a, b) => a + b);
      final double overall = (sum / uploadFileCount).clamp(0.0, 1.0);
      _progressController.add(overall * 0.7); // 업로드 단계는 0~70%
    });

    bool loadingDialogOpen = true;
    _showLoadingDialog(context);

    try {
      final itemData = _prepareItemData();
      if (itemData == null) {
        _showError(context, scaffoldMessenger, '경매 기간을 선택해주세요.');
        return;
      }

      final List<String> documentOriginalNames = selectedDocuments
          .map((doc) => doc.originalName)
          .toList();
      final List<int> documentSizes = selectedDocuments
          .map((doc) => doc.size)
          .toList();

      final (success, failure) = await _itemEnrollFlowUseCase.enroll(
        itemData: itemData,
        images: selectedImages,
        documents: selectedDocuments.map((e) => e.file).toList(),
        documentOriginalNames: documentOriginalNames,
        documentSizes: documentSizes,
        primaryImageIndex: primaryImageIndex,
        editingItemId: editingItemId,
        onProgress: (progress) => _progressController.add(progress),
      );

      if (failure != null) {
        if (context.mounted) {
          _showError(context, scaffoldMessenger, failure.message);
        }
        return;
      }

      _closeLoadingDialog(navigator, loadingDialogOpen);
      loadingDialogOpen = false;

      if (!context.mounted) return;
      await _showSuccessDialog(context, navigator);
    } catch (e) {
      if (context.mounted) {
        _showError(
          context,
          scaffoldMessenger,
          ItemRegistrationErrorMessages.registrationError(e),
        );
      }
    } finally {
      _isSubmitting = false;
      notifyListeners(); // 제출 완료 상태 UI 업데이트 필요
      await progressSub.cancel();
      _closeLoadingDialog(navigator, loadingDialogOpen);
    }
  }

  // UI Helpers
  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final spacing = dialogContext.inputPadding;
        final fontSize = dialogContext.fontSizeMedium;

        return Center(
          child: StreamBuilder<double>(
            stream: uploadProgressStream,
            initialData: 0.0,
            builder: (context, snapshot) {
              final p = (snapshot.data ?? 0.0).clamp(0.0, 1.0);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    value: p,
                    valueColor: AlwaysStoppedAnimation<Color>(blueColor),
                  ),
                  SizedBox(height: spacing),
                  Text(
                    '업로드 중 ${(p * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: fontSize,
                      color: Colors.white,
                      decoration: TextDecoration.none,
                      decorationThickness: 0,
                    ),
                  ),
                ],
              );
            },
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
      documentUrls: [], // PDF URL도 업로드 후 설정
      isAgree: agreed,
    );
  }

  Future<void> _showSuccessDialog(
    BuildContext context,
    NavigatorState navigator,
  ) async {
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

  // 튜토리얼을 봤는지 확인하는 함수
  Future<bool> shouldShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('has_seen_item_add_tutorial') ?? false;
    return !hasSeen;
  }

  // 튜토리얼을 완료했음을 저장하는 함수
  Future<void> markTutorialAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_item_add_tutorial', true);
  }
}
