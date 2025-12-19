import 'package:bidbird/core/widgets/item/components/others/transparent_refresh_indicator.dart';
import 'package:bidbird/features/feed/data/repository/home_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodel/home_viewmodel.dart';
import '../widgets/Item_grid.dart';
import '../widgets/floating_menu.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/keyword_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewmodel(HomeRepositoryImpl()),
      child: MediaQuery(
        //휴대폰 글씨크기 무시, 글씨 고정
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(1.0)),
        child: Consumer<HomeViewmodel>(
          builder: (context, viewModel, child) {
            return Scaffold(
              appBar: HomeAppBar(viewModel: viewModel),
              body: SafeArea(
                child: Stack(
                  children: [
                    TransparentRefreshIndicator(
                      onRefresh: viewModel.handleRefresh,
                      child: CustomScrollView(
                        controller: viewModel.scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          // 키워드 영역
                          KeywordWidget(viewModel: viewModel),

                          // 슬라이버 그리드 search 모드가 필요 없어짐 viewmodel에서 그냥 데이터만 뿌려주면 되기 때문
                          ItemGrid(viewModel: viewModel),
                        ],
                      ),
                    ),
                    child!, // 불변 위젯을 child로 분리
                  ],
                ),
              ),
            );
          },
          child: const FloatingMenu(), // 불변 위젯을 child로 분리하여 리빌드 방지
        ),
      ),
    );
  }
}
