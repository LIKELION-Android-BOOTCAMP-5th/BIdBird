import 'dart:io';

import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
import 'package:bidbird/features/auth/presentation/viewmodels/auth_set_profile_viewmodel.dart';
import 'package:bidbird/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/ui_set/border_radius_style.dart';
import '../../../../core/utils/ui_set/colors_style.dart';
import '../../../../core/utils/ui_set/fonts_style.dart';

class AuthSetProfileScreen extends StatelessWidget {
  const AuthSetProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthSetProfileViewmodel>(
      create: (_) => AuthSetProfileViewmodel(),
      child: Builder(
        builder: (context) {
          final vm = context.watch<AuthSetProfileViewmodel>();

          return Scaffold(
            appBar: AppBar(
              title: const Text('시작하기'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  //Column을 Column + Expanded + SingleChildScrollView + Column로바꿔봄//오버플로우방지
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: Column(
                          children: [
                            const SizedBox(height: 24),
                            _ProfileImage(vm: vm),
                            const SizedBox(height: 48),
                            _ProfileForm(vm: vm),
                            const SizedBox(height: 35),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text("나의 카테고리", style: contentFontStyle),
                            ),
                            const SizedBox(height: 12),

                            _Keywords(vm: vm),
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

class _ProfileImage extends StatelessWidget {
  final AuthSetProfileViewmodel vm;

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
                  width: 45,
                  height: 45,
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
                          size: 30,
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
  final AuthSetProfileViewmodel vm;

  const _ProfileForm({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('닉네임', style: contentFontStyle),
        const SizedBox(height: 12),
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

class _Keywords extends StatelessWidget {
  const _Keywords({required this.vm});

  final AuthSetProfileViewmodel vm;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: vm.keywords.where((keyword) => keyword.id != 110).map((
        keyword,
      ) {
        final isSelected = vm.selectedKeywordIds.contains(keyword.id);

        return ChoiceChip(
          label: Text(keyword.title),
          selected: isSelected,
          onSelected: (_) => vm.toggleKeyword(keyword),
          selectedColor: blueColor,
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
          ),
          showCheckmark: false,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }).toList(),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final AuthSetProfileViewmodel vm;

  const _SaveButton({required this.vm});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: blueColor,
          foregroundColor: BackgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 12),
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
                    .read<AuthSetProfileViewmodel>()
                    .loadProfile(); // 마이페이지프로필갱신

                if (!context.mounted) return; //await후에다시context쓰려면이렇게해야함

                await showDialog(
                  context: context,
                  builder: (dialogContext) {
                    return AskPopup(
                      content: '정보 저장이 완료되었습니다.',
                      yesText: '확인',
                      yesLogic: () async {
                        Navigator.of(dialogContext).pop();
                        await context.read<AuthViewModel>().fetchUser();
                        context.go('/home');
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
