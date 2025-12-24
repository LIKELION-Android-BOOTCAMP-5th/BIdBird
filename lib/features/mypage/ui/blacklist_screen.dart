import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';

import 'package:bidbird/core/widgets/item/components/others/transparent_refresh_indicator.dart';
import 'package:bidbird/features/mypage/domain/entities/blacklisted_user_entity.dart';
import 'package:bidbird/features/mypage/viewmodel/blacklist_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BlacklistScreen extends StatelessWidget {
  const BlacklistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<BlacklistViewModel>();
    // 필요한 속성만 선택적으로 구독하여 불필요한 리빌드 방지

    return Scaffold(
      backgroundColor: BackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('차단목록'),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _Blacklist(vm: vm),
        ),
      ),
    );
  }
}

class _Blacklist extends StatelessWidget {
  const _Blacklist({required this.vm});

  final BlacklistViewModel vm;

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<BlacklistViewModel, bool>(
      (vm) => vm.isLoading,
    );
    final errorMessage = context.select<BlacklistViewModel, String?>(
      (vm) => vm.errorMessage,
    );
    final users = context.select<BlacklistViewModel, List>((vm) => vm.users);

    if (isLoading) {
      return const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (errorMessage != null) {
      //나중에팝업띄울거임
    }

    if (users.isEmpty) {
      return const Center(child: Text('차단한 사용자가 없습니다.'));
    }

    //차단토글확인할수있도록//RefreshIndicator
    return TransparentRefreshIndicator(
      onRefresh: vm.loadBlacklist,
      child: ListView.separated(
        itemBuilder: (context, index) {
          final user = vm.users[index];
          final bool isProcessing = vm.isProcessing(user.targetUserId);
          return _Item(
            user: user,
            isProcessing: isProcessing,
            onPressed: () => vm.toggleBlock(user), //버튼에만반응
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemCount: vm.users.length,
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.user,
    required this.onPressed,
    required this.isProcessing,
  });

  final BlacklistedUserEntity user;
  final VoidCallback onPressed;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final bool isBlocked = user.isBlocked;
    final Color backgroundColor = isBlocked
        ? const Color(0xffF0F0F0)
        : blueColor;
    final Color textColor = isBlocked ? Colors.black87 : Colors.white;
    final String buttonLabel = isBlocked ? '차단해제' : '차단';

    final String displayName =
        user.nickName?.isNotEmpty ==
            true //탈퇴처리시방침정해지면모델도수정하고nickName?.isNotEmpty도수정
        ? user.nickName!
        : '탈퇴한 사용자';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BorderColor,
        borderRadius: defaultBorder,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: BackgroundColor,
            backgroundImage:
                (user.profileImageUrl != null &&
                    user.profileImageUrl!.isNotEmpty)
                ? NetworkImage(user.profileImageUrl!)
                : null,
            child:
                (user.profileImageUrl == null || user.profileImageUrl!.isEmpty)
                ? const Icon(Icons.person, color: iconColor)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(displayName)), //닉네임길이다양함
          const SizedBox(width: 12),
          SizedBox(
            height: 32,
            child: TextButton(
              onPressed: isProcessing ? null : onPressed,
              style: TextButton.styleFrom(
                backgroundColor: backgroundColor,
                foregroundColor: textColor,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: defaultBorder),
              ),
              child: isProcessing
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}
