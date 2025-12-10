import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/managers/cloudinary_manager.dart';
import '../data/profile_repository.dart';
import '../model/profile_model.dart';

class ProfileEditViewModel extends ChangeNotifier {
  final ProfileRepository _repository;

  final TextEditingController nickNameTextfield;
  final TextEditingController phoneTextfield;

  String? _profileImageUrl;

  bool _isUploadingImage = false;
  bool _isSaving = false;

  String? errorMessage;

  ProfileEditViewModel(this._repository, {Profile? initialProfile})
    : nickNameTextfield = TextEditingController(text: initialProfile?.nickName),
      phoneTextfield = TextEditingController(text: initialProfile?.phoneNumber),
      _profileImageUrl = initialProfile?.profileImageUrl;

  String? get profileImageUrl => _profileImageUrl;
  bool get isUploadingImage => _isUploadingImage;
  bool get isSaving => _isSaving;

  //다듬기
  Future<void> pickAndUploadProfileImage() async {
    try {
      _isUploadingImage = true;
      notifyListeners();

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) {
        _isUploadingImage = false;
        notifyListeners();
        return;
      }

      final url = await CloudinaryManager.shared.uploadImageToCloudinary(image);

      if (url != null) {
        _profileImageUrl = url;
      } else {
        errorMessage = '이미지 업로드에 실패했습니다.';
      }
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

    _isSaving = true;
    notifyListeners();

    try {
      final String? nickName = nickNameTextfield.text.trim().isEmpty
          ? null
          : nickNameTextfield.text.trim();
      final String? phoneNumber = phoneTextfield.text.trim().isEmpty
          ? null
          : phoneTextfield.text.trim();

      await _repository.updateProfile(
        nickName: nickName,
        phoneNumber: phoneNumber,
        profileImageUrl: _profileImageUrl,
      );
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  //delete만들기
  Future<void> unregisterUser() async {
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
    phoneTextfield.dispose();
    super.dispose();
  } //컨트롤러등은메모리정리해야함//언마운트될때ChangeNotifierProvider가자동으로호출해줌
}
