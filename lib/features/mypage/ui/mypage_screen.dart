import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/fonts_style.dart';

import 'package:bidbird/core/widgets/notification_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../viewmodel/profile_viewmodel.dart';

class MypageScreen extends StatelessWidget {
  const MypageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              _MypageProfile(),
              const SizedBox(height: 12),
              Expanded(child: _MypageItemList()),
            ],
          ),
        ),
      ),
    );
  }
}

class _MypageProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<ProfileViewModel, bool>(
      (vm) => vm.isLoading,
    );

    //처음프로필로딩할떄나옴
    if (isLoading) {
      return Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final profile = context.select<ProfileViewModel, dynamic>(
      (vm) => vm.profile,
    );
    final nickName = profile?.nickName ?? '닉네임을 등록하세요';

    return GestureDetector(
      onTap: () {
        context.go('/mypage/update_info');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: blueColor,
          borderRadius: defaultBorder,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: ImageBackgroundColor,
                    foregroundImage:
                        (profile?.profileImageUrl != null &&
                            profile!.profileImageUrl!.isNotEmpty)
                        ? NetworkImage(profile.profileImageUrl!)
                        : null,
                    child: const Icon(Icons.person, color: iconColor, size: 32),
                  ),
                  if (isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Text(
                nickName,
                style: contentFontStyle.copyWith(color: BackgroundColor),
              ),
            ),
            const Icon(Icons.chevron_right, color: BackgroundColor),
          ],
        ),
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
          icon: Icons.favorite_border,
          title: '관심목록',
          onTap: () {
            context.go('/mypage/favorite');
          },
        ),
        _Item(
          icon: Icons.receipt_long,
          title: '거래내역',
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
          title: '차단목록',
          onTap: () {
            context.go('/mypage/black_list');
          },
        ),
        const SizedBox(height: 24),
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
