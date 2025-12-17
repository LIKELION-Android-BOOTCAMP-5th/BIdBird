import 'dart:io'; //File경로/FileImage프리뷰

import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/fonts_style.dart';
import 'package:bidbird/core/utils/ui_set/icons_style.dart';
import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
import 'package:bidbird/features/auth/viewmodel/auth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:bidbird/features/mypage/data/profile_repository.dart';
import 'package:bidbird/features/mypage/viewmodel/profile_edit_viewmodel.dart';
import 'package:bidbird/features/mypage/viewmodel/profile_viewmodel.dart';

import 'package:bidbird/core/widgets/components/bottom_sheet/image_source_bottom_sheet.dart';
import 'package:image_picker/image_picker.dart';

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

          Future<bool> _handlePop() async {
            if (!vm.hasChanges) {
              return true;
            }

            bool shouldLeave = false;
            await showDialog(
              context: context,
              builder: (dialogContext) {
                return AskPopup(
                  content: '프로필을 저장하지 않습니다.',
                  yesText: '확인',
                  noText: '취소',
                  yesLogic: () async {
                    shouldLeave = true;
                    Navigator.of(dialogContext).pop();
                  },
                );
              },
            );
            return shouldLeave;
          }

          Future<void> confirmAndPop() async {
            final shouldPop = await _handlePop();
            if (shouldPop && context.mounted) {
              context.go('/mypage');
            }
          }

          return PopScope(
            canPop: vm.hasChanges ? false : true,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              confirmAndPop();
            },
            child: Scaffold(
              resizeToAvoidBottomInset: false,

              backgroundColor: theme.scaffoldBackgroundColor,
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () async {
                    await confirmAndPop();
                  },
                ),
                title: const Text('정보수정'),
                centerTitle: true,
              ),
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      children: [
                                        const SizedBox(height: 24),
                                        _ProfileImage(vm: vm),
                                        const SizedBox(height: 36),
                                        _ProfileForm(vm: vm),
                                        const SizedBox(
                                          height: 150,
                                        ), //키보드가올라오는높이에따라가변적으로하면더확실해질듯함//아니면아래칼럼을패딩으로감싸고그쪽을가변적으로
                                      ],
                                    ),
                                    //Column부분은키보드가올라오면가려짐
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _LogoutLink(),
                                        _UnregisterLink(vm: vm),
                                        //gorouter에의해login으로이동하게됨
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 48),
                      _SaveButton(vm: vm),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LogoutLink extends StatelessWidget {
  const _LogoutLink();

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () async {
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return AskPopup(
              content: '로그아웃 하시겠습니까?',
              yesText: '확인',
              noText: '취소',
              yesLogic: () async {
                Navigator.pop(dialogContext);
                await context.read<AuthViewModel>().logout(
                  onLoggedOut: () {
                    context.go('/login');
                  },
                );
              },
            );
          },
        );
      },
      child: Text('로그아웃'),
    );
  }
}

class _UnregisterLink extends StatelessWidget {
  final ProfileEditViewModel vm;

  const _UnregisterLink({required this.vm});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () async {
        bool didRequest = false;

        await showDialog(
          context: context,
          builder: (dialogContext) {
            return AskPopup(
              content: '회원탈퇴 하시겠습니까? \n탈퇴 후 복원은 불가능합니다.',
              yesText: '확인',
              noText: '취소',
              yesLogic: () async {
                await vm.deleteAccount();
                didRequest = true;
                Navigator.of(dialogContext).pop();
              },
            );
          },
        );

        if (!didRequest || !context.mounted) {
          return;
        }

        final errorMessage = vm.errorMessage;
        final content = errorMessage ?? '회원탈퇴가 완료되었습니다.';

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

    Future<void> pickProfileImage(ImageSource source) async {
      await vm.pickProfileImage(source);
      final errorMessage = vm.errorMessage;
      if (errorMessage != null && context.mounted) {
        //에러팝업
      }
    }

    Future<void> deleteProfileImage() async {
      await vm.deleteProfileImage();
      final errorMessage = vm.errorMessage;
      if (errorMessage != null && context.mounted) {
        //에러팝업
      }
    }

    void showImageOptions() {
      if (vm.isUploadingImage) return;

      final hasImage =
          selectedProfileImage != null ||
          (profileImageUrl != null && profileImageUrl.isNotEmpty);

      ImageSourceBottomSheet.show(
        context,
        onGalleryTap: () async => pickProfileImage(ImageSource.gallery),
        onCameraTap: () async => pickProfileImage(ImageSource.camera),
        onDeleteTap: hasImage ? () async => deleteProfileImage() : null,
      );
    }

    if (selectedProfileImage != null) {
      profileImage = FileImage(File(selectedProfileImage.path));
    } else if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      profileImage = NetworkImage(profileImageUrl);
    }

    return Column(
      children: [
        GestureDetector(
          onTap: vm.isUploadingImage ? null : showImageOptions,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundColor: ImageBackgroundColor,
                    foregroundImage: profileImage,
                    child: const Icon(Icons.person, color: iconColor, size: 60),
                  ),
                  if (vm.isUploadingImage)
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              Positioned(
                right: 10,
                bottom: 0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: blueColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
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
                final hadChanges = vm.hasChanges;

                if (!hadChanges) {
                  if (context.mounted) {
                    context.go('/mypage');
                  }
                  return;
                }

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

                // 변화가 없을 때는 바로 마이페이지로 이동
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
