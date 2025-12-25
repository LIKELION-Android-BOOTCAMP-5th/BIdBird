import 'package:bidbird/core/utils/ui_set/icons_style.dart';
import 'package:bidbird/core/widgets/notification_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodel/home_viewmodel.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final bool searchMode = context.select<HomeViewmodel, bool>((vm) => vm.searchButton);
    return AppBar(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!searchMode)
            GestureDetector(
              onTap: () => context.read<HomeViewmodel>().handleRefresh(),
              child: Image.asset(
                'assets/logos/bidbird_text_logo.png',
                width: 100,
                height: 100,
              ),
            )
          else
            SearchBar(
              constraints: const BoxConstraints(maxWidth: 250, minHeight: 40),
              backgroundColor: const WidgetStatePropertyAll(Colors.white),
              hintText: "검색어를 입력하세요",
              hintStyle: WidgetStateProperty.all(
                TextStyle(color: Colors.grey.shade400, fontSize: 14),
              ),
              autoFocus: true,
              onChanged: context.read<HomeViewmodel>().onSearchTextChanged,
            ),

          // 오른쪽 액션 메뉴
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  final vm = context.read<HomeViewmodel>();
                  vm.workSearchBar();
                  vm.search(vm.userInputController.text);
                },
                child: Image.asset(
                  'assets/icons/search_icon.png',
                  width: iconSize.width,
                  height: iconSize.height,
                ),
              ),
              const SizedBox(width: 25),
              const NotificationButton(),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
