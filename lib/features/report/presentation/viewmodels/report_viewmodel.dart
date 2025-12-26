import 'package:bidbird/features/report/data/repositories/report_repository.dart';
import 'package:bidbird/features/report/domain/entities/report_type_entity.dart';
import 'package:bidbird/features/report/domain/usecases/fetch_report_types_usecase.dart';
import 'package:bidbird/features/report/domain/usecases/submit_report_usecase.dart';
import 'package:bidbird/features/report/domain/usecases/orchestrations/report_flow_usecase.dart';
import 'package:bidbird/core/errors/error_mapper.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Report ViewModel - Thin Pattern
/// 책임: UI 상태 관리, UseCase 호출
/// 제외: 비즈니스 로직 (UseCase에서 처리)
class ReportViewModel extends ChangeNotifier {
  final FetchReportTypesUseCase _fetchReportTypesUseCase;
  final ReportFlowUseCase _reportFlowUseCase;
  final ImagePicker _picker = ImagePicker();

  ReportViewModel({
    FetchReportTypesUseCase? fetchReportTypesUseCase,
    ReportFlowUseCase? reportFlowUseCase,
  }) : _fetchReportTypesUseCase =
           fetchReportTypesUseCase ??
           FetchReportTypesUseCase(ReportRepositoryImpl()),
       _reportFlowUseCase =
           reportFlowUseCase ??
           ReportFlowUseCase(
             submitReportUseCase: SubmitReportUseCase(ReportRepositoryImpl()),
           ) {
    contentController.addListener(notifyListeners);
  }

  // State: Report Types
  List<ReportTypeEntity> _allReportTypes = [];
  List<ReportTypeEntity> get allReportTypes => _allReportTypes;

  List<String> get categories {
    if (_allReportTypes.isEmpty) return [];
    final categories = _allReportTypes.map((e) => e.category).toSet().toList();
    categories.sort((a, b) {
      try {
        final aName = _allReportTypes
            .firstWhere((e) => e.category == a)
            .categoryName;
        final bName = _allReportTypes
            .firstWhere((e) => e.category == b)
            .categoryName;
        return aName.compareTo(bName);
      } catch (e) {
        return 0;
      }
    });
    return categories;
  }

  List<String> get categoryNames {
    return categories
        .map((c) => _allReportTypes
            .firstWhere((e) => e.category == c)
            .categoryName)
        .toList();
  }

  // State: User Input
  String? _selectedCategory;
  String? get selectedCategory => _selectedCategory;

  String? _selectedReportCode;
  String? get selectedReportCode => _selectedReportCode;

  final TextEditingController contentController = TextEditingController();

  List<XFile> _selectedImages = [];
  List<XFile> get selectedImages => _selectedImages;

  // State: UI Status
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Computed
  List<ReportTypeEntity> get selectedCategoryReports {
    if (_selectedCategory == null) return [];
    return _allReportTypes
        .where((e) => e.category == _selectedCategory)
        .toList();
  }

  bool get canSubmit {
    return _selectedCategory != null &&
        _selectedReportCode != null &&
        contentController.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    contentController.dispose();
    super.dispose();
  }

  // Methods: Data Loading
  Future<void> loadReportTypes() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allReportTypes = await _fetchReportTypesUseCase();
    } catch (e) {
      _error = ErrorMapper().map(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Methods: Input State Management
  void selectCategory(String category) {
    _selectedCategory = category;
    _selectedReportCode = null;
    notifyListeners();
  }

  void selectReportCode(String reportCode) {
    _selectedReportCode = reportCode;
    notifyListeners();
  }

  Future<void> pickImagesFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(imageQuality: 80);
      if (images.isEmpty) return;

      _selectedImages = [..._selectedImages, ...images].take(5).toList();
      notifyListeners();
    } catch (e) {
      _error = ErrorMapper().map(e);
      notifyListeners();
    }
  }

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

      _selectedImages = [..._selectedImages, image];
      notifyListeners();
    } catch (e) {
      _error = ErrorMapper().map(e);
      notifyListeners();
    }
  }

  void removeImageAt(int index) {
    if (index >= 0 && index < _selectedImages.length) {
      _selectedImages.removeAt(index);
      notifyListeners();
    }
  }

  // Methods: Submit (Delegate to Flow UseCase)
  Future<bool> submitReport({
    required String? itemId,
    required String targetUserId,
  }) async {
    if (_isLoading) return false;
    if (!canSubmit) {
      _error = '모든 항목을 입력해주세요.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final (success, failure) = await _reportFlowUseCase.submit(
        itemId: itemId,
        targetUserId: targetUserId,
        reportCode: _selectedReportCode ?? '',
        reportContent: contentController.text.trim(),
        images: _selectedImages,
      );

      if (failure != null) {
        _error = failure.message;
        return false;
      }

      return success != null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _selectedCategory = null;
    _selectedReportCode = null;
    contentController.clear();
    _selectedImages.clear();
    _error = null;
    notifyListeners();
  }
}
