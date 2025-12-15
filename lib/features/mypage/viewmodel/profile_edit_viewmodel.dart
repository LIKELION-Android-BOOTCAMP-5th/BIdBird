import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/managers/cloudinary_manager.dart';
import '../data/profile_repository.dart';
import '../model/profile_model.dart';

class ProfileEditViewModel extends ChangeNotifier {
  final ProfileRepository _repository;

  final TextEditingController nickNameTextfield;
  // final TextEditingController phoneTextfield;

  String? _profileImageUrl;
  XFile? _selectedProfileImage;

  bool _isUploadingImage = false;
  bool _isSaving = false;

  String? errorMessage;

  late String _initialNickName;
  String? _initialProfileImageUrl;

  ProfileEditViewModel(this._repository, {Profile? initialProfile})
    : nickNameTextfield = TextEditingController(
        text: initialProfile?.nickName ?? '',
      ),
      _profileImageUrl = initialProfile?.profileImageUrl,
      _initialNickName = (initialProfile?.nickName ?? '').trim(),
      _initialProfileImageUrl = initialProfile?.profileImageUrl;

  String? get profileImageUrl => _profileImageUrl;
  XFile? get selectedProfileImage => _selectedProfileImage;
  bool get isUploadingImage => _isUploadingImage;
  bool get isSaving => _isSaving;
  bool get hasChanges {
    final currentNickname = nickNameTextfield.text.trim();
    final nicknameChanged = currentNickname != _initialNickName;
    final imageChanged =
        _selectedProfileImage != null ||
        _profileImageUrl != _initialProfileImageUrl;

    return nicknameChanged || imageChanged;
  }

  Future<void> pickProfileImage(ImageSource source) async {
    try {
      _isUploadingImage = true;
      notifyListeners();

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 80,
      );
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

  Future<void> deleteProfileImage() async {
    if (_isUploadingImage) return;

    final bool hasRemoteProfileImage =
        _profileImageUrl != null && _profileImageUrl!.isNotEmpty;

    if (_selectedProfileImage != null) {
      _selectedProfileImage = null;
    }

    if (!hasRemoteProfileImage) {
      _profileImageUrl = null;
      errorMessage = null;
      notifyListeners();
      return;
    }

    _isUploadingImage = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateProfile(deleteProfileImage: true);
      _profileImageUrl = null;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      _isUploadingImage = false;
      notifyListeners();
    }
  }

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
    notifyListeners(); //로딩인디케이터/저장버튼부분

    try {
      if (_selectedProfileImage != null) {
        _isUploadingImage = true;
        notifyListeners(); //로딩인디케이터/프로필사진부분
        try {
          final url = await CloudinaryManager.shared.uploadImageToCloudinary(
            _selectedProfileImage!,
          );

          if (url == null) {
            errorMessage = '이미지 업로드에 실패했습니다.';
            return;
          }

          _profileImageUrl = url;
          _selectedProfileImage = null;
        } finally {
          _isUploadingImage = false;
          notifyListeners();
        }
      }

      final String nickName = trimmedNickName;

      await _repository.updateProfile(
        nickName: nickName,
        profileImageUrl: _profileImageUrl,
      );
      _initialNickName = nickName;
      _initialProfileImageUrl = _profileImageUrl;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> deleteAccount() async {
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.deleteAccount();
    } catch (e) {
      errorMessage = e.toString();
      //Dart의 기본 Exception 클래스는 toString()을 "Exception: $message" 형태로 만들도록 구현돼 있음
      errorMessage = errorMessage!.substring('Exception: '.length);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nickNameTextfield.dispose();
    super.dispose();
  } //컨트롤러등은메모리정리해야함//언마운트될때ChangeNotifierProvider가자동으로호출해줌
}
