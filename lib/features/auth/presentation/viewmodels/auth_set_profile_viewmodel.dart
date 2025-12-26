import 'package:bidbird/core/managers/cloudinary_manager.dart';
import 'package:bidbird/core/services/keyword_cache_service.dart';
import 'package:bidbird/features/auth/data/repositories/auth_set_profile_repository_impl.dart';
import 'package:bidbird/features/auth/domain/entities/auth_set_profile_entity.dart';
import 'package:bidbird/features/auth/domain/usecases/fetch_profile_usecase.dart';
import 'package:bidbird/features/auth/domain/usecases/fetch_user_keyword_ids_usecase.dart';
import 'package:bidbird/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:bidbird/features/auth/domain/usecases/update_user_keywords_usecase.dart';
import 'package:bidbird/features/home/domain/entities/keywordType_entity.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AuthSetProfileViewmodel extends ChangeNotifier {
  final _repository = AuthSetProfileRepositoryImpl();
  
  final FetchProfileUseCase _fetchProfileUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final FetchUserKeywordIdsUseCase _fetchUserKeywordIdsUseCase;
  final UpdateUserKeywordsUseCase _updateUserKeywordsUseCase;

  final TextEditingController nickNameTextfield;
  // final TextEditingController phoneTextfield;

  String? _profileImageUrl;
  XFile? _selectedProfileImage;

  bool _isUploadingImage = false;
  bool _isSaving = false;

  AuthSetProfileEntity? profile;
  List<int> _keywordIds = [];
  List<int> get keywordIds => _keywordIds;
  bool isLoading = false;

  String? errorMessage;

  //키워드 관련
  List<KeywordType> _keywords = [];
  List<KeywordType> get keywords => _keywords;
  //키워드 복수 선택
  final Set<int> _selectedKeywordIds = {};
  Set<int> get selectedKeywordIds => _selectedKeywordIds;

  AuthSetProfileViewmodel({
    AuthSetProfileEntity? initialProfile,
    List<int>? initialKeywordIds,
  })  : _fetchProfileUseCase = FetchProfileUseCase(AuthSetProfileRepositoryImpl()),
        _updateProfileUseCase = UpdateProfileUseCase(AuthSetProfileRepositoryImpl()),
        _fetchUserKeywordIdsUseCase = FetchUserKeywordIdsUseCase(AuthSetProfileRepositoryImpl()),
        _updateUserKeywordsUseCase = UpdateUserKeywordsUseCase(AuthSetProfileRepositoryImpl()),
        nickNameTextfield = TextEditingController(
          text: initialProfile?.nickName,
        ),
        _profileImageUrl = initialProfile?.profileImageUrl {
    loadProfile();
    getKeywordList();

    if (initialKeywordIds != null) {
      _selectedKeywordIds.addAll(initialKeywordIds);
    }
  }

  String? get profileImageUrl => _profileImageUrl;
  XFile? get selectedProfileImage => _selectedProfileImage;
  bool get isUploadingImage => _isUploadingImage;
  bool get isSaving => _isSaving;

  Future<void> pickProfileImage() async {
    try {
      _isUploadingImage = true;
      notifyListeners();

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        return;
      }

      _selectedProfileImage = image;
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      _isUploadingImage = false;
      notifyListeners();
    }
  }

  //다듬기
  Future<void> saveProfileChanges() async {
    if (_isSaving) return;

    final trimmedNickName = nickNameTextfield.text.trim();
    if (trimmedNickName.isEmpty) {
      errorMessage = '닉네임을 입력하세요.';
      notifyListeners();
      return;
    }

    _isSaving = true;
    errorMessage = null;
    notifyListeners(); //로딩인디케이터

    try {
      if (_selectedProfileImage != null) {
        final url = await CloudinaryManager.shared.uploadImageToCloudinary(
          _selectedProfileImage!,
        );

        if (url == null) {
          errorMessage = '이미지 업로드에 실패했습니다.';
          return;
        }

        _profileImageUrl = url;
        _selectedProfileImage = null;
      }

      final String nickName = trimmedNickName;

      await _updateProfileUseCase.call(
        nickName: nickName,
        profileImageUrl: _profileImageUrl,
      );

      await _updateUserKeywordsUseCase.call(_selectedKeywordIds.toList());
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  //키워드 관련
  Future<void> getKeywordList({List<int>? initialKeywordIds}) async {
    // 전역 캐시에 키워드가 있으면 사용
    final cachedKeywords = KeywordCacheService().getKeywords();
    if (cachedKeywords != null && cachedKeywords.isNotEmpty) {
      _keywords = cachedKeywords;
      if (initialKeywordIds != null && _selectedKeywordIds.isEmpty) {
        _selectedKeywordIds.addAll(initialKeywordIds);
      }
      notifyListeners();
      return;
    }
    
    // 캐시가 없으면 네트워크에서 가져오기
    _keywords = await _repository.getKeywordType();
    
    // 전역 캐시에 저장
    if (_keywords.isNotEmpty) {
      KeywordCacheService().setKeywords(_keywords);
    }

    if (initialKeywordIds != null && _selectedKeywordIds.isEmpty) {
      _selectedKeywordIds.addAll(initialKeywordIds);
    }

    notifyListeners();
  }

  Future<void> loadProfile() async {
    if (isLoading) return; //반복요청대비

    isLoading = true;
    errorMessage = null; //다른곳에서참조할수도있으니확실하게지정해주는게좋음
    notifyListeners(); //로딩인디케이터표시를위함

    try {
      profile = await _fetchProfileUseCase.call();
      _keywordIds = await _fetchUserKeywordIdsUseCase.call();
    } catch (e) {
      errorMessage = e.toString(); //e는String임
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void toggleKeyword(KeywordType keyword) {
    if (keyword.id == 110) return; //전체 항목 ui에서 안보이게 제외
    if (_selectedKeywordIds.contains(keyword.id)) {
      _selectedKeywordIds.remove(keyword.id);
    } else {
      _selectedKeywordIds.add(keyword.id);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    nickNameTextfield.dispose();
    // phoneTextfield.dispose();
    super.dispose();
  } //컨트롤러등은메모리정리해야함//언마운트될때ChangeNotifierProvider가자동으로호출해줌
}

