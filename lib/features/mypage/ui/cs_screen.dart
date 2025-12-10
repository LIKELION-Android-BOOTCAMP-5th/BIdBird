import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/fonts_style.dart';
import 'package:bidbird/core/utils/ui_set/icons_style.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CsScreen extends StatelessWidget {
  const CsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('고객센터'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [const CsItemList()],
          ),
        ),
      ),
    );
  }
}

class CsItemList extends StatelessWidget {
  const CsItemList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Item(
          icon: Icons.description_outlined,
          color: blueColor,
          title: '약관 확인',
          onTap: () {
            context.go('/mypage/service_center/terms');
          },
        ),
        _Item(
          icon: Icons.chat_bubble_outline,
          color: yellowColor,
          title: '신고 내역',
          onTap: () {
            context.go('/mypage/service_center/report_feedback');
          },
        ),
      ],
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;

  const _Item({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: color),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right, color: iconColor),
          onTap: onTap,
        ),
        //const Divider(height: 0),
      ],
    );
  }
}
