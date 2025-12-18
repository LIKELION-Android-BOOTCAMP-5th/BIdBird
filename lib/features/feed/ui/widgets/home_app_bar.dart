import 'package:bidbird/core/utils/ui_set/icons_style.dart';
import 'package:bidbird/core/widgets/notification_button.dart';
import 'package:bidbird/features/feed/viewmodel/home_viewmodel.dart';
import 'package:flutter/material.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final HomeViewmodel viewModel; // ⭐ 필드로 선언

  const HomeAppBar({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!viewModel.searchButton)
            GestureDetector(
              onTap: viewModel.handleRefresh,
              child: Image.asset(
                'assets/logos/bidbird_text_logo.png',
                width: 100,
                height: 100,
              ),
            )
          else
            SearchBar(
              constraints: const BoxConstraints(maxWidth: 250, minHeight: 40),
              backgroundColor: const MaterialStatePropertyAll(Colors.white),
              hintText: "검색어를 입력하세요",
              hintStyle: MaterialStateProperty.all(
                TextStyle(color: Colors.grey.shade400, fontSize: 14),
              ),
              autoFocus: true,
              onChanged: viewModel.onSearchTextChanged,
            ),

          // 오른쪽 액션 메뉴
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  viewModel.workSearchBar();
                  viewModel.search(viewModel.userInputController.text);
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
