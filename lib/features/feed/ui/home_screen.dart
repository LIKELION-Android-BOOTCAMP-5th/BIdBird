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
                  ListView(
                    children: [
                      SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: viewModel.keywords.length,
                          itemBuilder: (context, index) {
                            final String title =
                                viewModel.keywords[index].title;
                            // final bool isSelected =
                            //     title == viewModel.selectCategory;
                            return Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: ElevatedButton(
                                onPressed: () {
                                  // viewModel.ChangeCategory(title);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: blueColor,

                                  // foregroundColor: isSelected
                                  //     ? Colors.white
                                  //     : Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                  minimumSize: const Size(0, 0),
                                ),
                                child: Text(
                                  title,
                                  //TODO: 색 나중에 선택 되었을 때 조건문으로 변경 예정
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: GridView.builder(
                          // GridView가 부모 ListView의 공간에 맞게 높이를 최소화하도록 설정
                          shrinkWrap: true,
                          // GridView 자체는 스크롤되지 않도록 설정 (부모 ListView가 스크롤을 담당)
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.75,
                                mainAxisSpacing: 5,
                                crossAxisSpacing: 20,
                              ),
                          itemCount: 10,
                          itemBuilder: (context, index) {
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
                                            //이 컨테이너 대신에 사진이 들어가면 됨
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius: defaultBorder,
                                              ),
                                              child: AspectRatio(
                                                aspectRatio: 1,
                                                child: Center(
                                                  child: const Icon(
                                                    Icons.image,
                                                    size: 100,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: Align(
                                                alignment: Alignment.topCenter,
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
                                                  child: Text(
                                                    '잔여 시간: 12:12',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 4,
                                              left: 8,
                                              right: 8,
                                              //나중에 사진 올라가면 이 부분 grey[200]으로 잔여 시간처럼, 글씨도 똑같이
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  //Todo: 나중에 뷰카운트 2차 업데이트
                                                  // Row(
                                                  //   spacing: 2,
                                                  //   children: [
                                                  //     Icon(
                                                  //       Icons.remove_red_eye,
                                                  //       size: 12,
                                                  //     ),
                                                  //     Text("12"),
                                                  //   ],
                                                  // ),
                                                  Text("입찰 건수: 12"),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Align(
                                          alignment: Alignment.center,
                                          child: Text(
                                            "상품명",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const Align(
                                          alignment: Alignment.center,
                                          child: Text("현재 가격"),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
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
