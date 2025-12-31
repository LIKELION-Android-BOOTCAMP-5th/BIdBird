import 'package:bidbird/core/widgets/item/components/others/transparent_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodel/home_viewmodel.dart';
import '../widgets/Item_grid.dart';
import '../widgets/floating_menu.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_tutorial_utils.dart';
import '../widgets/keyword_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey _fabKey = GlobalKey();
  final GlobalKey _searchKey = GlobalKey();
  final GlobalKey _notificationKey = GlobalKey();
  final GlobalKey _currentPriceKey = GlobalKey();
  final GlobalKey _biddingCountKey = GlobalKey();
  final GlobalKey _finishTimeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    context.read<HomeViewmodel>().fetchItems();
    //  화면이 다 그려진 후 튜토리얼 실행
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final viewmodel = context.read<HomeViewmodel>();

      // 튜토리얼 캐시 확인
      bool isFirstTutorial = await viewmodel.shouldShowTutorial();

      if (isFirstTutorial) {
        homeTutorial(
          context: context,
          fabKey: _fabKey,
          searchKey: _searchKey,
          notificationKey: _notificationKey,
          currentPriceKey: _currentPriceKey,
          biddingCountKey: _biddingCountKey,
          finishTimeKey: _finishTimeKey,
        );
        await viewmodel.markTutorialAsSeen();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ViewModel은 main.dart에서 전역으로 생성되므로 여기서는 Consumer없이 필요한 부분만 접근
    return MediaQuery(
      //휴대폰 글씨크기 무시, 글씨 고정
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
      child: Scaffold(
        appBar: HomeAppBar(
          searchKey: _searchKey,
          notificationKey: _notificationKey,
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Stack(
                children: [
                  TransparentRefreshIndicator(
                    onRefresh: context.read<HomeViewmodel>().handleRefresh,
                    child: CustomScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      controller: context
                          .read<HomeViewmodel>()
                          .scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        // 키워드 영역
                        const KeywordWidget(),

                        // 슬라이버 그리드 search 모드가 필요 없어짐 viewmodel에서 그냥 데이터만 뿌려주면 되기 때문
                        ItemGrid(
                          currentPriceKey: _currentPriceKey,
                          biddingCountKey: _biddingCountKey,
                          finishTimeKey: _finishTimeKey,
                        ),
                      ],
                    ),
                  ),
                  FloatingMenu(fabKey: _fabKey),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
