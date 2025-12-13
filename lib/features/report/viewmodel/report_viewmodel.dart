import 'package:bidbird/core/managers/cloudinary_manager.dart';
import 'package:bidbird/features/report/data/datasource/report_datasource.dart';
import 'package:bidbird/features/report/model/report_type_entity.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ReportViewModel extends ChangeNotifier {
  final ReportDatasource _datasource;
  final ImagePicker _picker = ImagePicker();

  ReportViewModel({ReportDatasource? datasource})
      : _datasource = datasource ?? ReportDatasource() {
    // 생성 시 즉시 로드 시작
    loadReportTypes();
  }

  List<ReportTypeEntity> _allReportTypes = [];
  List<ReportTypeEntity> get allReportTypes => _allReportTypes;

  // 대분류 목록 (한글명으로 정렬)
  List<String> get categories {
    if (_allReportTypes.isEmpty) return [];
    final categories = _allReportTypes.map((e) => e.category).toSet().toList();
    // 한글명 기준으로 정렬
    categories.sort((a, b) {
      try {
        final aName = _allReportTypes.firstWhere((e) => e.category == a).categoryName;
        final bName = _allReportTypes.firstWhere((e) => e.category == b).categoryName;
        return aName.compareTo(bName);
      } catch (e) {
        return 0;
      }
    });
    return categories;
  }

  // 대분류 한글명 목록
  List<String> get categoryNames {
    return categories.map((c) {
      final firstType = _allReportTypes.firstWhere((e) => e.category == c);
      return firstType.categoryName;
    }).toList();
  }

  // 선택된 대분류
  String? _selectedCategory;
  String? get selectedCategory => _selectedCategory;

  // 선택된 신고 사유
  String? _selectedReportCode;
  String? get selectedReportCode => _selectedReportCode;

  // 상세 내용
  final TextEditingController contentController = TextEditingController();

  // 이미지 관련
  List<XFile> _selectedImages = [];
  List<XFile> get selectedImages => _selectedImages;
  
  List<String> _uploadedImageUrls = [];
  List<String> get uploadedImageUrls => _uploadedImageUrls;
  
  bool _isUploadingImages = false;
  bool get isUploadingImages => _isUploadingImages;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // 선택된 대분류에 해당하는 신고 사유 목록
  List<ReportTypeEntity> get selectedCategoryReports {
    if (_selectedCategory == null) return [];
    return _allReportTypes
        .where((e) => e.category == _selectedCategory)
        .toList();
  }

  // 제출 가능 여부
  bool get canSubmit {
    return _selectedCategory != null &&
        _selectedReportCode != null &&
        contentController.text.trim().length >= 10;
  }

  @override
  void dispose() {
    contentController.dispose();
    super.dispose();
  }

  /// 신고 타입 목록 로드
  Future<void> loadReportTypes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allReportTypes = await _datasource.fetchReportTypes();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 대분류 선택
  void selectCategory(String category) {
    _selectedCategory = category;
    _selectedReportCode = null; // 대분류 변경 시 하위 선택 초기화
    notifyListeners();
  }

  /// 신고 사유 선택
  void selectReportCode(String reportCode) {
    _selectedReportCode = reportCode;
    notifyListeners();
  }

  /// 이미지 선택 (갤러리)
  Future<void> pickImagesFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(imageQuality: 80);
      if (images.isEmpty) return;

      final List<XFile> all = <XFile>[..._selectedImages, ...images];
      if (all.length > 5) {
        _selectedImages = all.take(5).toList();
      } else {
        _selectedImages = all;
      }
      notifyListeners();
    } catch (e) {
      _error = '이미지 선택 실패: $e';
      notifyListeners();
    }
  }

  /// 이미지 선택 (카메라)
  Future<void> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image == null) return;

      if (_selectedImages.length >= 5) {
        _error = '최대 5장까지 업로드 가능합니다.';
        notifyListeners();
        return;
      }

      _selectedImages = <XFile>[..._selectedImages, image];
      notifyListeners();
    } catch (e) {
      _error = '이미지 선택 실패: $e';
      notifyListeners();
    }
  }

  /// 이미지 삭제
  void removeImageAt(int index) {
    if (index >= 0 && index < _selectedImages.length) {
      _selectedImages.removeAt(index);
      notifyListeners();
    }
  }

  /// 이미지 업로드
  Future<void> uploadImages() async {
    if (_selectedImages.isEmpty) {
      _uploadedImageUrls = [];
      return;
    }

    _isUploadingImages = true;
    _error = null;
    notifyListeners();

    try {
      _uploadedImageUrls = await CloudinaryManager.shared
          .uploadImageListToCloudinary(_selectedImages);
      
      if (_uploadedImageUrls.isEmpty && _selectedImages.isNotEmpty) {
        _error = '이미지 업로드에 실패했습니다.';
      }
    } catch (e) {
      _error = '이미지 업로드 실패: $e';
      _uploadedImageUrls = [];
    } finally {
      _isUploadingImages = false;
      notifyListeners();
    }
  }

  /// 신고 제출
  Future<bool> submitReport({
    required String? itemId,
    required String targetUserId,
  }) async {
    if (!canSubmit) {
      _error = '모든 항목을 입력해주세요.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 이미지 업로드
      await uploadImages();
      
      if (_selectedImages.isNotEmpty && _uploadedImageUrls.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _datasource.submitReport(
        itemId: itemId,
        targetUserId: targetUserId,
        reportCode: _selectedReportCode!,
        reportContent: contentController.text.trim(),
        imageUrls: _uploadedImageUrls,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // 에러 메시지에서 사용자 친화적인 메시지 추출
      final errorString = e.toString();
      if (errorString.contains('Exception: ')) {
        _error = errorString.replaceFirst('Exception: ', '');
      } else {
        _error = '신고 제출에 실패했습니다.\n잠시 후 다시 시도해주세요.';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 초기화
  void reset() {
    _selectedCategory = null;
    _selectedReportCode = null;
    contentController.clear();
    _selectedImages.clear();
    _uploadedImageUrls.clear();
    _error = null;
    notifyListeners();
  }
}

