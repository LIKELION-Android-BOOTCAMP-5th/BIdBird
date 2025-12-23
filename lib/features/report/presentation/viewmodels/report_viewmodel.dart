import 'package:bidbird/features/report/data/repositories/report_repository.dart';
import 'package:bidbird/features/report/domain/entities/report_type_entity.dart';
import 'package:bidbird/features/report/domain/usecases/fetch_report_types_usecase.dart';
import 'package:bidbird/features/report/domain/usecases/submit_report_usecase.dart';
import 'package:bidbird/features/report/domain/usecases/orchestrations/report_flow_usecase.dart';
import 'package:bidbird/core/errors/error_mapper.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Report ViewModel - Thin Pattern
/// 
/// 책임:
/// - UI 입력 상태 관리 (카테고리, 신고 사유, 이미지, 텍스트)
/// - UseCase 호출 및 결과 매핑
/// - 상태 변경 알림
/// 
/// 제외:
/// - 비즈니스 로직 (UseCase에서 처리)
/// - 직접 에러 처리 (Flow UseCase에서 처리)
/// - 복잡한 유효성 검사
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
    // 상세 내용 텍스트 변경 시 버튼 상태 업데이트
    contentController.addListener(() {
      notifyListeners();
    });
  }

  // State: Report 타입
  List<ReportTypeEntity> _allReportTypes = [];
  List<ReportTypeEntity> get allReportTypes => _allReportTypes;

  // 대분류 목록 (한글명으로 정렬)
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

  // 대분류 한글명 목록
  List<String> get categoryNames {
    return categories.map((c) {
      final firstType = _allReportTypes.firstWhere((e) => e.category == c);
      return firstType.categoryName;
    }).toList();
  }

  // State: 사용자 입력
  String? _selectedCategory;
  String? get selectedCategory => _selectedCategory;

  String? _selectedReportCode;
  String? get selectedReportCode => _selectedReportCode;

  final TextEditingController contentController = TextEditingController();

  List<XFile> _selectedImages = [];
  List<XFile> get selectedImages => _selectedImages;

  // State: UI 상태
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
        contentController.text.trim().length >= 1;
  }

  @override
  void dispose() {
    contentController.dispose();
    super.dispose();
  }

  // Methods: 데이터 로드
  
  /// 신고 타입 목록 로드 (초기 로드)
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

  // Methods: 입력 상태 관리
  
  /// 대분류 선택
  void selectCategory(String category) {
    _selectedCategory = category;
    _selectedReportCode = null;
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
      _selectedImages = all.length > 5 ? all.take(5).toList() : all;
      notifyListeners();
    } catch (e) {
      _error = ErrorMapper().map(e);
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
      _error = ErrorMapper().map(e);
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

  // Methods: 제출 (Flow UseCase 위임)
  
  /// 신고 제출 (Flow UseCase로 오케스트레이션)
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
      // Flow UseCase에 위임
      final (success, failure) = await _reportFlowUseCase.submit(
        itemId: itemId,
        targetUserId: targetUserId,
        reportCode: _selectedReportCode ?? '',
        reportContent: contentController.text.trim(),
        images: _selectedImages,
      );

      // 결과 매핑
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

  /// 초기화
  void reset() {
    _selectedCategory = null;
    _selectedReportCode = null;
    contentController.clear();
    _selectedImages.clear();
    _error = null;
    notifyListeners();
  }
}
