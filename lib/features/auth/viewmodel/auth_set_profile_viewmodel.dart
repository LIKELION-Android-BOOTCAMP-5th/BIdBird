import 'package:bidbird/core/managers/cloudinary_manager.dart';
import 'package:bidbird/core/models/keywordType_entity.dart';
import 'package:bidbird/features/auth/data/repository/auth_set_profile_repository.dart';
import 'package:bidbird/features/auth/model/auth_set_profile_model.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AuthSetProfileViewmodel extends ChangeNotifier {
  final AuthSetProfileRepository _repository;

  final TextEditingController nickNameTextfield;
  // final TextEditingController phoneTextfield;

  String? _profileImageUrl;
  XFile? _selectedProfileImage;

  bool _isUploadingImage = false;
  bool _isSaving = false;

  AuthSetProfileModel? profile;
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

  AuthSetProfileViewmodel(
    this._repository, {
    AuthSetProfileModel? initialProfile,
    List<int>? initialKeywordIds,
  }) : nickNameTextfield = TextEditingController(
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

      await _repository.updateProfile(
        nickName: nickName,
        profileImageUrl: _profileImageUrl,
      );

      await _repository.updateUserKeywords(_selectedKeywordIds.toList());
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Future<void> unregisterUser() async {
  //   errorMessage = null;
  //   notifyListeners();
  //   try {
  //     await _repository.unregisterUser();
  //   } catch (e) {
  //     errorMessage = e.toString();
  //     notifyListeners();
  //   }
  // }

  //키워드 관련
  Future<void> getKeywordList({List<int>? initialKeywordIds}) async {
    if (_keywords.isNotEmpty) return; // 중복 호출 방지
    _keywords = await _repository.getKeywordType();

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
      profile = await _repository.fetchProfile();
      _keywordIds = await _repository.fetchUserKeywordIds();
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
