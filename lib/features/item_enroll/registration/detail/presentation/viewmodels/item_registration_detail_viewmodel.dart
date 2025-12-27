import 'dart:io';

import 'package:bidbird/core/utils/item/item_registration_error_messages.dart';
import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
import 'package:bidbird/features/item_enroll/registration/list/domain/entities/item_registration_entity.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/repositories/item_registration_detail_repository.dart';
import '../../domain/usecases/confirm_registration_usecase.dart';
import '../../domain/usecases/delete_item_usecase.dart';
import '../../domain/usecases/fetch_all_image_urls_usecase.dart';
import '../../domain/usecases/fetch_terms_text_usecase.dart';

class ItemRegistrationDetailViewModel extends ChangeNotifier {
  ItemRegistrationDetailViewModel({
    required ItemRegistrationData item,
    FetchTermsTextUseCase? fetchTermsTextUseCase,
    ConfirmRegistrationUseCase? confirmRegistrationUseCase,
    DeleteItemUseCase? deleteItemUseCase,
    FetchAllImageUrlsUseCase? fetchAllImageUrlsUseCase,
  })  : _item = item,
        _fetchTermsTextUseCase = fetchTermsTextUseCase ??
            FetchTermsTextUseCase(ItemRegistrationDetailRepositoryImpl()),
        _confirmRegistrationUseCase = confirmRegistrationUseCase ??
            ConfirmRegistrationUseCase(ItemRegistrationDetailRepositoryImpl()),
        _deleteItemUseCase = deleteItemUseCase ??
            DeleteItemUseCase(ItemRegistrationDetailRepositoryImpl()),
        _fetchAllImageUrlsUseCase = fetchAllImageUrlsUseCase ??
            FetchAllImageUrlsUseCase(ItemRegistrationDetailRepositoryImpl());

  final FetchTermsTextUseCase _fetchTermsTextUseCase;
  final ConfirmRegistrationUseCase _confirmRegistrationUseCase;
  final DeleteItemUseCase _deleteItemUseCase;
  final FetchAllImageUrlsUseCase _fetchAllImageUrlsUseCase;

  final ItemRegistrationData _item;
  ItemRegistrationData get item => _item;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _termsText;
  String? get termsText => _termsText;

  String? _imageUrl;
  String? get imageUrl => _imageUrl;
  List<String> _imageUrls = [];
  List<String> get imageUrls => _imageUrls;
  bool _isLoadingImage = false;
  bool get isLoadingImage => _isLoadingImage;

  // 이미지 URL 캐시 추가
  Map<String, List<String>>? _imageUrlCache;
  DateTime? _imageUrlCacheTime;
  static const Duration _imageUrlCacheDuration = Duration(seconds: 30);

  // 이미지 로드 에러 상태 추가
  String? _imageLoadError;
  String? get imageLoadError => _imageLoadError;

  // 다운로드된 PDF 파일 목록 (URL 기준)
  final Set<String> _downloadedPdfUrls = {};
  bool isPdfDownloaded(String url) => _downloadedPdfUrls.contains(url);

  Future<void> loadTerms() async {
    try {
      _termsText = await _fetchTermsTextUseCase();
    } catch (e) {
      // 약관 로드 실패 시에도 계속 진행 가능하도록 조용히 처리
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadImage() async {
    _isLoadingImage = true;
    _imageLoadError = null; // 에러 초기화
    notifyListeners();

    try {
      // 캐시 검증 추가
      if (_imageUrlCache != null &&
          _imageUrlCacheTime != null &&
          DateTime.now().difference(_imageUrlCacheTime!) <
              _imageUrlCacheDuration) {
        _imageUrls = _imageUrlCache![_item.id] ?? [];
        if (_imageUrls.isNotEmpty) {
          _imageUrl = _imageUrls.first;
          _imageLoadError = null;
        }
        _checkDownloadedFiles(); // 이미지 로드 후 다운로드 상태 확인
        _isLoadingImage = false;
        notifyListeners();
        return; // 캐시 사용하고 반환
      }

      // 모든 이미지 URL 가져오기
      final imageUrls = await _fetchAllImageUrlsUseCase(_item.id);

      if (imageUrls.isNotEmpty) {
        _imageUrls = List<String>.from(imageUrls);
        _imageUrl = imageUrls.first;

        // 캐시 저장
        _imageUrlCache = {_item.id: _imageUrls};
        _imageUrlCacheTime = DateTime.now();
        _imageLoadError = null;
      } else if (_item.thumbnailUrl != null && _item.thumbnailUrl!.isNotEmpty) {
        // 폴백: thumbnailUrl 사용
        _imageUrl = _item.thumbnailUrl;
        _imageUrls = [_item.thumbnailUrl!];

        // 폴백도 캐시
        _imageUrlCache = {_item.id: _imageUrls};
        _imageUrlCacheTime = DateTime.now();
        _imageLoadError = null;
      } else {
        _imageUrl = null;
        _imageUrls = [];
        _imageLoadError = '등록된 이미지가 없습니다';
      }
    } catch (e) {
      // 이미지 로드 실패 시 thumbnailUrl 사용
      if (_item.thumbnailUrl != null && _item.thumbnailUrl!.isNotEmpty) {
        _imageUrl = _item.thumbnailUrl;
        _imageUrls = [_item.thumbnailUrl!];
        _imageLoadError = null;
      } else {
        _imageUrl = null;
        _imageUrls = [];
        _imageLoadError = '이미지 로드 실패';
      }
    } finally {
      _checkDownloadedFiles(); // 로드 완료 후 다운로드 상태 확인
      _isLoadingImage = false;
      notifyListeners();
    }
  }

  Future<void> _checkDownloadedFiles() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      for (final url in _imageUrls) {
        if (!_isPdf(url)) continue;
        final fileName = _getFileNameFromUrl(url);
        final file = File('${dir.path}/$fileName');
        if (await file.exists()) {
          _downloadedPdfUrls.add(url);
        }
      }
      notifyListeners(); // 상태 업데이트
    } catch (e) {
      debugPrint('Failed to check downloaded files: $e');
    }
  }

  Future<void> downloadPdf(BuildContext context, String url) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = _getFileNameFromUrl(url);
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        // 이미 존재하면 다운로드 스킵하고 상태만 업데이트 (혹은 바로 열기)
        _downloadedPdfUrls.add(url);
        notifyListeners();
        _openPdfViewer(context, file);
        return;
      }

      // 다운로드 진행
      await Dio().download(url, filePath);
      
      _downloadedPdfUrls.add(url);
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF 파일이 저장되었습니다.')),
        );
      }
    } catch (e) {
      debugPrint('PDF Download failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('다운로드 실패: $e')),
        );
      }
    }
  }

  void openPdf(BuildContext context, String url) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = _getFileNameFromUrl(url);
      final file = File('${dir.path}/$fileName');

      if (await file.exists()) {
        _openPdfViewer(context, file);
      } else {
        // 파일이 없으면 다운로드 유도
        downloadPdf(context, url);
      }
    } catch (e) {
      debugPrint('Failed to open PDF: $e');
    }
  }

  void _openPdfViewer(BuildContext context, File file) {
    // PDF 뷰어로 이동 (syncfusion_flutter_pdfviewer 사용)
    // 현재 프로젝트 구조상 별도 스크린을 만들거나 Dialog로 띄울 수 있음.
    // 여기서는 간단히 새로운 라우트로 이동하거나 showDialog 등으로 처리.
    // 하지만 가장 확실한 건 Navigator push.
    // 임시로 PDF Viewer 뷰를 생성해서 push.
    
    // Note: PDF 뷰어 위젯은 View 측에서 구현하거나 별도 파일로 분리해야 함.
    // ViewModel은 네비게이션 트리거만.
    // 하지만 context.push를 쓰려면 route가 등록되어 있어야 함.
    // 여기서는 MaterialPageRoute를 직접 사용 (유연성)
    
    // *중요*: syncfusion_flutter_pdfviewer 패키지가 필요함.
    // Viewer는 Screen 파일 내부에 static method나 별도 클래스로 정의하는 것이 좋음.
    // ViewModel에서는 파일 경로만 넘겨주는 콜백을 호출하거나, View에서 처리하도록 유도.
    // 하지만 편의상 여기서 context를 이용해 Navigation 함.
    
    // View 측에서 처리하도록 로직 분리:
    // downloadPdf 완료 후 View에서 감지하여 열거나,
    // openPdf 호출 시 View에 정의된 Viewer 호출.
    
    // 일단 여기서는 파일 존재 여부만 확인하고, 실제 뷰어 열기는 View(Screen)의 메서드를 호출하는 방식이 나음.
    // 하지만 ViewModel 메서드이므로, return 값으로 File을 주거나 함.
    
    // -> View에서 처리하기 위해 downloadPdf가 File을 반환하거나, 완료 알림을 줌.
    // -> 여기서는 단순히 상태 업데이트만 하고, UI에서 "열기" 버튼을 누르면 View 코드에서 뷰어를 열도록 함.
  }
  
  // Helper methods
  bool _isPdf(String url) {
    return url.toLowerCase().contains('.pdf');
  }

  String _getFileNameFromUrl(String url) {
    try {
      return Uri.parse(url).pathSegments.last;
    } catch (e) {
      return 'document.pdf';
    }
  }

  Future<void> confirmRegistration(BuildContext context) async {
    if (_isSubmitting) return;
    _isSubmitting = true;
    notifyListeners();

    final messenger = ScaffoldMessenger.of(context);

    try {
      await _confirmRegistrationUseCase(_item.id);

      if (!context.mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AskPopup(
            content: '매물이 등록되었습니다.',
            yesText: '확인',
            yesLogic: () async {
              Navigator.of(dialogContext).pop();
              if (context.mounted) {
                context.go('/home');
              }
            },
          );
        },
      );
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(ItemRegistrationErrorMessages.registrationError(e)),
          ),
        );
      }
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> deleteItem(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          return AskPopup(
            content: '해당 매물을 삭제하시겠습니까?',
            yesText: '삭제하기',
            noText: '취소',
            yesLogic: () async {
              Navigator.of(dialogContext).pop();
              await _deleteItemUseCase(_item.id);
              if (context.mounted) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('매물이 삭제되었습니다.')),
                );
                Navigator.of(context).pop(true);
              }
            },
          );
        },
      );
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(ItemRegistrationErrorMessages.deletionError(e)),
          ),
        );
      }
    }
  }
}
