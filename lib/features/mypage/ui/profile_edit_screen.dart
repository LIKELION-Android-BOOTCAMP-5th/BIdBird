import 'dart:io'; //File경로/FileImage프리뷰

import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/fonts_style.dart';
import 'package:bidbird/core/utils/ui_set/icons_style.dart';
import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
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
                  //Column을 Column + Expanded + SingleChildScrollView + Column로바꿔봄//오버플로우방지
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 24),
                            _ProfileImage(vm: vm),
                            const SizedBox(height: 48),
                            _ProfileForm(vm: vm),
                            const SizedBox(height: 12),
                            _UnregisterLink(vm: vm),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
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

class _UnregisterLink extends StatelessWidget {
  final ProfileEditViewModel vm;

  const _UnregisterLink({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () async {
          bool didRequest = false;

          await showDialog(
            context: context,
            builder: (dialogContext) {
              return AskPopup(
                content: '회원탈퇴 하시겠습니까? \n복구가능 기간은 30일입니다.',
                yesText: '확인',
                noText: '취소',
                yesLogic: () async {
                  await vm.unregisterUser();
                  didRequest = true;
                  Navigator.of(dialogContext).pop();
                },
              );
            },
          );

          if (!didRequest || !context.mounted) {
            return;
          }

          final unregisterError = vm.errorMessage;
          final content = unregisterError ?? '회원탈퇴가 완료되었습니다.';

          await showDialog(
            context: context,
            builder: (dialogContext) {
              return AskPopup(
                content: content,
                yesText: '확인',
                yesLogic: () async {
                  Navigator.of(dialogContext).pop();
                },
              );
            },
          );
        },
        child: Text('회원탈퇴'),
      ),
    );
  }
}

class _ProfileImage extends StatelessWidget {
  final ProfileEditViewModel vm;

  const _ProfileImage({required this.vm});

  @override
  Widget build(BuildContext context) {
    final profileImageUrl = vm.profileImageUrl;
    final selectedProfileImage = vm.selectedProfileImage;
    ImageProvider? profileImage;

    if (selectedProfileImage != null) {
      profileImage = FileImage(File(selectedProfileImage.path));
    } else if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      profileImage = NetworkImage(profileImageUrl);
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 80,
              foregroundImage: profileImage,
              child: profileImage == null
                  ? const Icon(Icons.person, size: 60)
                  : null,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: vm.isUploadingImage
                    ? null
                    : () async {
                        await vm.pickProfileImage();
                        final errorMessage = vm.errorMessage;
                        if (errorMessage != null && context.mounted) {
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
        Text('닉네임', style: contentFontStyle),
        const SizedBox(height: 8),
        TextField(
          controller: vm.nickNameTextfield,
          decoration: InputDecoration(
            filled: true,
            fillColor: BackgroundColor,
            border: OutlineInputBorder(
              borderSide: const BorderSide(color: BorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: BorderColor),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 12,
            ),
          ),
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
          foregroundColor: BackgroundColor,
          padding: const EdgeInsets.symmetric(
            vertical: 12,
          ), //현재작으면CircularProgressIndicator때문에오버플러우에러남//전체수정하면서Center로옮기기//너무키우면키보드올라와서공간작아서오버플로우에러남
          shape: RoundedRectangleBorder(borderRadius: defaultBorder),
        ),
        onPressed: vm.isSaving
            ? null
            : () async {
                await vm.saveProfileChanges();
                final errorMessage = vm.errorMessage;
                if (!context.mounted) return; //await후에다시context쓰려면이렇게해야함

                if (errorMessage != null) {
                  final content = errorMessage == '닉네임을 입력하세요.'
                      ? '닉네임을 입력하세요.'
                      : '정보 수정이 실패하였습니다.';

                  await showDialog(
                    context: context,
                    builder: (dialogContext) {
                      return AskPopup(
                        content: content,
                        yesText: '확인',
                        yesLogic: () async {
                          Navigator.of(dialogContext).pop();
                        },
                      );
                    },
                  );
                  return;
                }

                await context
                    .read<ProfileViewModel>()
                    .loadProfile(); // 마이페이지프로필갱신

                if (!context.mounted) return; //await후에다시context쓰려면이렇게해야함

                await showDialog(
                  context: context,
                  builder: (dialogContext) {
                    return AskPopup(
                      content: '정보 수정이 완료되었습니다.',
                      yesText: '확인',
                      yesLogic: () async {
                        Navigator.of(dialogContext).pop();
                        context.go('/mypage');
                      },
                    );
                  },
                );
              },
        child: vm.isSaving
            ? const SizedBox(
                height: 24, //일단이걸줄였음
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text('저장'),
      ),
    );
  }
}
