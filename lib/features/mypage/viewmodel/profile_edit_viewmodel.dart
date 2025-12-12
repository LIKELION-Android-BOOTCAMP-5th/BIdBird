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

  ProfileEditViewModel(this._repository, {Profile? initialProfile})
    : nickNameTextfield = TextEditingController(text: initialProfile?.nickName),
      // phoneTextfield = TextEditingController(text: initialProfile?.phoneNumber),
      _profileImageUrl = initialProfile?.profileImageUrl;

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
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> unregisterUser() async {
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.unregisterUser();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nickNameTextfield.dispose();
    // phoneTextfield.dispose();
    super.dispose();
  } //컨트롤러등은메모리정리해야함//언마운트될때ChangeNotifierProvider가자동으로호출해줌
}
