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
                child: Column(children: [
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
