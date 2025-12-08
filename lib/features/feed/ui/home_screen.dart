import 'package:bidbird/core/utils/extension/money_extension.dart';
import 'package:bidbird/core/utils/ui_set/colors.dart';
import 'package:bidbird/core/utils/ui_set/icons.dart';
import 'package:bidbird/features/feed/repository/home_repository.dart';
import 'package:bidbird/features/feed/viewmodel/home_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/ui_set/border_radius.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeRepository _homeRepository = HomeRepository();
  bool _fabMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HomeViewmodel(_homeRepository),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                'assets/logos/bidbird_text_logo.png',
                width: 100,
                height: 100,
              ),
              Row(
                spacing: 25,
                children: [
                  Image.asset(
                    'assets/icons/search_icon.png',
                    width: iconSize.width,
                    height: iconSize.height,
                  ),
                  Image.asset(
                    'assets/icons/alarm_icon.png',
                    width: iconSize.width,
                    height: iconSize.height,
                  ),
                ],
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Consumer<HomeViewmodel>(
            builder: (context, viewModel, child) {
              return Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: viewModel.handleRefresh,
                    child: CustomScrollView(
                      controller: viewModel.scrollController,
                      slivers: [
                        // 키워드 영역
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 50,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: viewModel.keywords.length,
                              itemBuilder: (context, index) {
                                final String title =
                                    viewModel.keywords[index].title;

                                return Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: blueColor,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 8,
                                      ),
                                      minimumSize: const Size(0, 0),
                                    ),
                                    child: Text(
                                      title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        // 슬라이버 그리드 (2개씩)
                        SliverPadding(
                          padding: const EdgeInsets.all(20.0),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.75,
                                  mainAxisSpacing: 5,
                                  crossAxisSpacing: 20,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final item = viewModel.Items[index];
                              final title = item.title;
                              final currentPrice = item.current_price;

                              return Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8.7),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        children: [
                                          Stack(
                                            children: [
                                              AspectRatio(
                                                aspectRatio: 1,
                                                child: ClipRRect(
                                                  borderRadius: defaultBorder,
                                                  child: Image.network(
                                                    item.thumbnail_image,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),

                                              // 잔여 시간
                                              Positioned(
                                                top: 8,
                                                left: 8,
                                                right: 8,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: const Text(
                                                    '잔여 시간: 12:12',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              /// 입찰 건수
                                              Positioned(
                                                bottom: 4,
                                                left: 8,
                                                right: 8,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: const [
                                                    Text(
                                                      "입찰 건수: 12",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 8),

                                          Text(
                                            title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            "현재 가격: ${currentPrice.toCommaString()}원",
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }, childCount: viewModel.Items.length),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_fabMenuOpen)
                    Positioned(
                      right: 16,
                      bottom: 90,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _FabMenuItem(
                            label: '매물 등록하기',
                            icon: Icons.check_circle_outline,
                            onTap: () {
                              setState(() {
                                _fabMenuOpen = false;
                              });
                              context.push('/add_item/item_registration_list');
                            },
                          ),
                          const SizedBox(height: 16),
                          _FabMenuItem(
                            label: '매물 작성',
                            icon: Icons.edit_outlined,
                            onTap: () {
                              setState(() {
                                _fabMenuOpen = false;
                              });
                              context.push('/add_item');
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              _fabMenuOpen = !_fabMenuOpen;
            });
          },
          backgroundColor: blueColor,
          child: Icon(
            _fabMenuOpen ? Icons.close : Icons.add,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _FabMenuItem extends StatelessWidget {
  const _FabMenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 22, color: Colors.black87),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ].reversed.toList(),
      ),
    );
  }
}
