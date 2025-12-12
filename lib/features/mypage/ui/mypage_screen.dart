import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/fonts_style.dart';
import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
import 'package:bidbird/core/widgets/notification_button.dart';
import 'package:bidbird/features/auth/viewmodel/auth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../viewmodel/profile_viewmodel.dart';

class MypageScreen extends StatelessWidget {
  const MypageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = context.watch<ProfileViewModel>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [const Text('마이페이지'), NotificationButton()],
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MypageProfile(vm: vm),
              const SizedBox(height: 24),
              Expanded(child: _MypageItemList()),
            ],
          ),
        ),
      ),
    );
  }
}

class _MypageProfile extends StatelessWidget {
  final ProfileViewModel vm;

  const _MypageProfile({required this.vm});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); //쓴적이없음

    //처음프로필로딩할떄나옴
    if (vm.isLoading) {
      return Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final profile = vm.profile;
    final nickName = profile?.nickName ?? '닉네임을 등록하세요';
    final phoneNumber = profile?.phoneNumber ?? '전화번호를 등록하세요';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(color: blueColor, borderRadius: defaultBorder),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,

            backgroundImage:
                (profile?.profileImageUrl != null &&
                    profile!.profileImageUrl!.isNotEmpty)
                ? NetworkImage(profile.profileImageUrl!)
                : null,
            child:
                (profile?.profileImageUrl == null ||
                    profile!.profileImageUrl!.isEmpty)
                ? const Icon(Icons.person, color: iconColor, size: 30)
                : null,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nickName),
              const SizedBox(height: 4),
              Text(phoneNumber),
            ],
          ),
        ],
      ),
    );
  }
}

class _MypageItemList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Item(
          icon: Icons.edit,
          title: '정보 수정',
          onTap: () {
            context.go('/mypage/update_info');
          },
        ),
        _Item(
          icon: Icons.favorite_border,
          title: '관심 목록',
          onTap: () {
            context.go('/mypage/favorite');
          },
        ),
        _Item(
          icon: Icons.receipt_long,
          title: '거래 내역',
          onTap: () {
            context.go('/mypage/trade');
          },
        ),
        _Item(
          icon: Icons.support_agent,
          title: '고객센터',
          onTap: () {
            context.go('/mypage/service_center');
          },
        ),
        _Item(
          icon: Icons.block,
          title: '블랙리스트',
          onTap: () {
            context.go('/mypage/black_list');
          },
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: RedColor,
              side: const BorderSide(color: RedColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: defaultBorder),
            ),
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
            child: Text(
              '로그아웃',
              style: TextStyle(
                fontSize: buttonFontStyle.fontSize,
                fontWeight: buttonFontStyle.fontWeight,
                color: RedColor,
              ),
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _Item({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: iconColor),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right, color: iconColor),
          onTap: onTap,
        ),
        //const Divider(height: 0),
      ],
    );
  }
}
