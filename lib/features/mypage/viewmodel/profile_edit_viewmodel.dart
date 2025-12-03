import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/cloudinary_manager.dart';
import '../data/profile_repository.dart';
import 'profile_viewmodel.dart';

class ProfileEditViewModel extends ChangeNotifier {
  final ProfileRepository _repository;
  final Profile? _initialProfile;

  final TextEditingController nameTextfield;
  final TextEditingController phonetextfield;

  String? _profileImageUrl;

  String? lastErrorMessage;

  ProfileEditViewModel(this._repository, {Profile? initialProfile})
    : _initialProfile = initialProfile,
      nameTextfield = TextEditingController(text: initialProfile?.name),
      phonetextfield = TextEditingController(text: initialProfile?.phoneNumber),
      _profileImageUrl = initialProfile?.profileImageUrl;
}
