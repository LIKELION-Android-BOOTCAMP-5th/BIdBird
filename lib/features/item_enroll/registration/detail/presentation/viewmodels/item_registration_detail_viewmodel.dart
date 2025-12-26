import 'package:bidbird/core/utils/item/item_registration_error_messages.dart';
import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
import '../../data/repositories/item_registration_detail_repository.dart';
import '../../domain/usecases/fetch_terms_text_usecase.dart';
import '../../domain/usecases/confirm_registration_usecase.dart';
import '../../domain/usecases/delete_item_usecase.dart';
import '../../domain/usecases/fetch_all_image_urls_usecase.dart';
import 'package:bidbird/features/item_enroll/registration/list/domain/entities/item_registration_entity.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ItemRegistrationDetailViewModel extends ChangeNotifier {
  ItemRegistrationDetailViewModel({
    required ItemRegistrationData item,
    FetchTermsTextUseCase? fetchTermsTextUseCase,
    ConfirmRegistrationUseCase? confirmRegistrationUseCase,
    DeleteItemUseCase? deleteItemUseCase,
    FetchAllImageUrlsUseCase? fetchAllImageUrlsUseCase,
  }) : _item = item,
       _fetchTermsTextUseCase =
           fetchTermsTextUseCase ??
           FetchTermsTextUseCase(ItemRegistrationDetailRepositoryImpl()),
       _confirmRegistrationUseCase =
           confirmRegistrationUseCase ??
           ConfirmRegistrationUseCase(ItemRegistrationDetailRepositoryImpl()),
       _deleteItemUseCase =
           deleteItemUseCase ??
           DeleteItemUseCase(ItemRegistrationDetailRepositoryImpl()),
       _fetchAllImageUrlsUseCase =
           fetchAllImageUrlsUseCase ??
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
      _isLoadingImage = false;
      notifyListeners();
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
