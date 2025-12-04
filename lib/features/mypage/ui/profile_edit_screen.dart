import 'package:bidbird/core/utils/ui_set/border_radius.dart';
import 'package:bidbird/core/utils/ui_set/colors.dart';
import 'package:bidbird/core/utils/ui_set/fonts.dart';
import 'package:bidbird/core/utils/ui_set/icons.dart';
import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
import 'package:bidbird/features/auth/viewmodel/auth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:bidbird/features/mypage/data/profile_repository.dart';
import 'package:bidbird/features/mypage/viewmodel/profile_edit_viewmodel.dart';
import 'package:bidbird/features/mypage/viewmodel/profile_viewmodel.dart';

class ProfileEditScreen extends StatelessWidget {
  const ProfileEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = context.read<ProfileViewModel>().profile;

    return ChangeNotifierProvider<ProfileEditViewModel>(
      create: (_) =>
          ProfileEditViewModel(ProfileRepository(), initialProfile: profile),
      child: Builder(
        builder: (context) {
          final vm = context.watch<ProfileEditViewModel>();

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
              title: const Text('정보 수정'),
              centerTitle: true,
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    _ProfileImage(vm: vm),
                    //const SizedBox(height: 24),
                    _ProfileForm(vm: vm),
                    // const SizedBox(height: 24),
                    // Align(
                    //   alignment: Alignment.centerRight,
                    //   child: _UnregisterButton(vm: vm),
                    // ),
                    const Spacer(),
                    _SaveButton(vm: vm),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileImage extends StatelessWidget {
  final ProfileEditViewModel vm;

  const _ProfileImage({required this.vm});

  @override
  Widget build(BuildContext context) {
    final imageUrl = vm.profileImageUrl;

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                  ? NetworkImage(imageUrl)
                  : null,
              child: (imageUrl == null || imageUrl.isEmpty)
                  ? const Icon(Icons.person, size: 60, color: iconColor)
                  : null,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: vm.isUploadingImage
                    ? null
                    : () async {
                        await vm.pickAndUploadProfileImage();
                        final error = vm.errorMessage;
                        if (error != null && context.mounted) {
                          //에러팝업
                        }
                      },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: blueColor,
                    shape: BoxShape.circle,
                  ),
                  child: vm.isUploadingImage
                      ? const Center(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileForm extends StatelessWidget {
  final ProfileEditViewModel vm;

  const _ProfileForm({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('이름', style: contentFontStyle),
        const SizedBox(height: 8),
        TextField(
          controller: vm.nickNameTextfield,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              //borderRadius: defaultBorder,
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              //borderRadius: defaultBorder,
              borderSide: const BorderSide(color: Colors.grey),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('전화번호', style: contentFontStyle),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: vm.phoneTextfield,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    //borderRadius: defaultBorder,
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    //borderRadius: defaultBorder,
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 40,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  side: const BorderSide(color: blueColor),
                  shape: RoundedRectangleBorder(borderRadius: defaultBorder),
                ),
                onPressed: () {
                  // 재인증
                },
                child: Text(
                  '재인증',
                  style: buttonFontStyle.copyWith(color: blueColor),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  final ProfileEditViewModel vm;

  const _SaveButton({required this.vm});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: blueColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: defaultBorder),
        ),
        onPressed: vm.isSaving
            ? null
            : () async {
                await vm.saveProfileChanges();
                final error = vm.errorMessage;
                if (error != null) {
                  if (context.mounted) {
                    //에러팝업
                  }
                  return;
                }

                if (context.mounted) {
                  await context
                      .read<ProfileViewModel>()
                      .loadProfile(); // 마이페이지프로필갱신
                  context.pop();
                }
              },
        child: vm.isSaving
            ? const SizedBox(
                height: 32,
                width: 32,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text('저장'),
      ),
    );
  }
}
