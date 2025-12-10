import 'package:bidbird/core/utils/extension/money_extension.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/icons_style.dart';
import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
import 'package:bidbird/features/feed/viewmodel/home_viewmodel.dart';
import 'package:bidbird/features/item/identity_verification/data/repository/identity_verification_gateway_impl.dart';
import 'package:bidbird/features/item/identity_verification/screen/identity_verification_screen.dart';
import 'package:bidbird/features/item/identity_verification/usecase/check_and_request_identity_verification_usecase.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/extension/time_extension.dart';
import '../../../core/utils/ui_set/border_radius_style.dart';
import '../../../core/utils/ui_set/shadow_style.dart';
import '../data/repository/home_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _fabMenuOpen = false;

  Future<bool> _ensureIdentityVerified(BuildContext context) async {
    final gateway = IdentityVerificationGatewayImpl();
    final useCase = CheckAndRequestIdentityVerificationUseCase(gateway);

    // 1) 먼저 서버에서 CI 여부 확인
    final hasCi = await gateway.hasCi();
    if (hasCi) {
      // 이미 CI가 있으면 팝업 없이 바로 통과
      return true;
    }

    // 2) CI가 없으면 본인인증 안내 팝업 노출
    bool proceed = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AskPopup(
          content: '본인 인증을 해주세요.',
          yesText: '본인 인증하기',
          noText: '취소',
          yesLogic: () async {
            proceed = true;
            Navigator.of(dialogContext).pop();
          },
        );
      },
    );

    if (!proceed) {
      return false;
    }

    // 3) 팝업에서 "본인 인증하기"를 누른 경우에만 본인인증 화면으로 이동
    final result = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (_) => IdentityVerificationScreen(useCase: useCase),
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HomeViewmodel(HomeRepository()),
      child: MediaQuery(
        //휴대폰 글씨크기 무시, 글씨 고정
        data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
        child: Consumer<HomeViewmodel>(
          builder: (context, viewModel, child) {
            return Scaffold(
              appBar: AppBar(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (viewModel.searchButton == false)
                      Image.asset(
                        'assets/logos/bidbird_text_logo.png',
                        width: 100,
                        height: 100,
                      )
                    else
                      SearchBar(
                        constraints: BoxConstraints(
                          maxWidth: 250,
                          minHeight: 40,
                        ),
                        backgroundColor: MaterialStatePropertyAll(Colors.white),
                        hintText: "검색어를 입력하세요",
                        hintStyle: MaterialStateProperty.all(
                          TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        ),
                        autoFocus: true,
                        onChanged: (text) {
                          viewModel.onSearchTextChanged(text);
                        },
                      ),
                    //UI 깨짐 방지
                    Flexible(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        spacing: 25,
                        children: [
                          GestureDetector(
                            onTap: () {
                              viewModel.workSearchBar();
                              viewModel.search(
                                viewModel.userInputController.text,
                              );
                            },
                            child: Image.asset(
                              'assets/icons/search_icon.png',
                              width: iconSize.width,
                              height: iconSize.height,
                            ),
                          ),
                          Image.asset(
                            'assets/icons/alarm_icon.png',
                            width: iconSize.width,
                            height: iconSize.height,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              body: SafeArea(
                child: Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: viewModel.handleRefresh,
                      child: CustomScrollView(
                        controller: viewModel.scrollController,
                        slivers: [
                          // 키워드 영역
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: 42,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: viewModel.keywords.length,
                                itemBuilder: (context, index) {
                                  final String keyword =
                                      viewModel.keywords[index].title;
                                  final bool isSelected =
                                      keyword == viewModel.selectKeyword;
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      top: 4,
                                      right: 4,
                                      left: 4,
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        final keywordSelect =
                                            viewModel.keywords[index];
                                        viewModel.selectKeywordAndFetch(
                                          keywordSelect.title,
                                          keywordSelect.id,
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isSelected
                                            ? Color(0xffe3ecfd)
                                            : Color(0xffe5e5e8),
                                        // foregroundColor: isSelected
                                        //     ? Colors.white
                                        //     : Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 8,
                                        ),
                                        minimumSize: const Size(0, 0),
                                        elevation: 0.0,
                                      ),
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: Text(
                                          keyword,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Color(0xff3B82F6)
                                                : Color(0xff6B7280),
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          // 슬라이버 그리드 (2개씩)
                          if (viewModel.searchButton)
                            SliverPadding(
                              padding: const EdgeInsets.only(
                                left: 20,
                                right: 20,
                                bottom: 20,
                                top: 15,
                              ),
                              sliver: SliverGrid(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 0.75,
                                      mainAxisSpacing: 1,
                                      crossAxisSpacing: 10,
                                    ),
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final item = viewModel.Items[index];
                                  final title = item.title;

                                  return GestureDetector(
                                    onTap: () {
                                      // item_detail 페이지로 이동
                                      context.push(('/item/${item.id}'));
                                    },
                                    child: Column(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              8.7,
                                            ),
                                            boxShadow: [defaultShadow],
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
                                                        borderRadius:
                                                            defaultBorder,
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
                                                      // 가로 폭을 비율로 주기 위한 UI
                                                      child: Align(
                                                        alignment: Alignment
                                                            .centerRight,
                                                        child: FractionallySizedBox(
                                                          widthFactor: 0.60,
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 4,
                                                                ),
                                                            decoration:
                                                                BoxDecoration(
                                                                  color:
                                                                      RedColor,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        15,
                                                                      ),
                                                                ),
                                                            child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .center,
                                                              spacing: 3,
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .access_alarm,
                                                                  size: 12,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                                Flexible(
                                                                  child: Text(
                                                                    formatRemainingTime(
                                                                      item.finishTime,
                                                                    ),
                                                                    style: TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                      fontSize:
                                                                          12,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),

                                                    /// 입찰 건수
                                                    Positioned(
                                                      bottom: 6,
                                                      left: 6,
                                                      right: 8,
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 4,
                                                                ),
                                                            decoration:
                                                                BoxDecoration(
                                                                  color: Colors
                                                                      .black45,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        15,
                                                                      ),
                                                                ),
                                                            child: Row(
                                                              spacing: 3,
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .account_circle,
                                                                  color: Colors
                                                                      .white,
                                                                  size: 12,
                                                                ),
                                                                Text(
                                                                  "${item.bidding_count}",
                                                                  style: TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),

                                                    //현재 가격
                                                    Positioned(
                                                      bottom: 6,
                                                      right: 6,
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 4,
                                                                ),
                                                            decoration:
                                                                BoxDecoration(
                                                                  color: Colors
                                                                      .black45,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        15,
                                                                      ),
                                                                ),
                                                            child: Text(
                                                              "${item.current_price.toCommaString()}원",
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    // 시간 만료 되면 나오는 UI
                                                    if (DateTime.now().isAfter(
                                                      item.finishTime,
                                                    ))
                                                      Positioned.fill(
                                                        child: Container(
                                                          decoration:
                                                              BoxDecoration(
                                                                color: Colors
                                                                    .black54,
                                                                borderRadius:
                                                                    defaultBorder,
                                                              ),
                                                          child: Align(
                                                            alignment: Alignment
                                                                .center,
                                                            child: Text(
                                                              "종료된 상품입니다",
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 15,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),

                                                // const SizedBox(height: 8),
                                                Align(
                                                  alignment: Alignment.topLeft,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 4,
                                                        ),
                                                    child: Text(
                                                      title,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }, childCount: viewModel.Items.length),
                              ),
                            ),
                          if (!viewModel.searchButton)
                            SliverPadding(
                              padding: const EdgeInsets.only(
                                left: 20,
                                right: 20,
                                bottom: 20,
                                top: 15,
                              ),
                              sliver: SliverGrid(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 0.75,
                                      mainAxisSpacing: 1,
                                      crossAxisSpacing: 10,
                                    ),
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final item = viewModel.Items[index];
                                  final title = item.title;

                                  return GestureDetector(
                                    onTap: () {
                                      // item_detail 페이지로 이동
                                      context.push(('/item/${item.id}'));
                                    },
                                    child: Column(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              8.7,
                                            ),
                                            boxShadow: [defaultShadow],
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
                                                        borderRadius:
                                                            defaultBorder,
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
                                                      // 가로 폭을 비율로 주기 위한 UI
                                                      child: Align(
                                                        alignment: Alignment
                                                            .centerRight,
                                                        child: FractionallySizedBox(
                                                          widthFactor: 0.60,
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 4,
                                                                ),
                                                            decoration:
                                                                BoxDecoration(
                                                                  color:
                                                                      RedColor,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        15,
                                                                      ),
                                                                ),
                                                            child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .center,
                                                              spacing: 3,
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .access_alarm,
                                                                  size: 12,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                                Flexible(
                                                                  child: Text(
                                                                    formatRemainingTime(
                                                                      item.finishTime,
                                                                    ),
                                                                    style: TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                      fontSize:
                                                                          12,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),

                                                    /// 입찰 건수
                                                    Positioned(
                                                      bottom: 6,
                                                      left: 6,
                                                      right: 8,
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 4,
                                                                ),
                                                            decoration:
                                                                BoxDecoration(
                                                                  color: Colors
                                                                      .black45,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        15,
                                                                      ),
                                                                ),
                                                            child: Row(
                                                              spacing: 3,
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .account_circle,
                                                                  color: Colors
                                                                      .white,
                                                                  size: 12,
                                                                ),
                                                                Text(
                                                                  "${item.bidding_count}",
                                                                  style: TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),

                                                    // 현재 가격
                                                    Positioned(
                                                      bottom: 6,
                                                      right: 6,
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 4,
                                                                ),
                                                            decoration:
                                                                BoxDecoration(
                                                                  color: Colors
                                                                      .black45,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        15,
                                                                      ),
                                                                ),
                                                            child: Text(
                                                              "${item.current_price.toCommaString()}원",
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),

                                                    // 시간 만료 되면 나오는 UI
                                                    if (DateTime.now().isAfter(
                                                      item.finishTime,
                                                    ))
                                                      Positioned.fill(
                                                        child: Container(
                                                          decoration:
                                                              BoxDecoration(
                                                                color: Colors
                                                                    .black54,
                                                                borderRadius:
                                                                    defaultBorder,
                                                              ),
                                                          child: Align(
                                                            alignment: Alignment
                                                                .center,
                                                            child: Text(
                                                              "종료된 상품입니다",
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 15,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),

                                                // const SizedBox(height: 8),
                                                Align(
                                                  alignment: Alignment.topLeft,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 4,
                                                        ),
                                                    child: Text(
                                                      title,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
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
                              label: '매물 작성',
                              icon: Icons.edit_outlined,
                              onTap: () async {
                                setState(() {
                                  _fabMenuOpen = false;
                                });

                                final verified = await _ensureIdentityVerified(
                                  context,
                                );
                                if (!verified) return;

                                context.push('/add_item');
                              },
                            ),

                            const SizedBox(height: 16),

                            _FabMenuItem(
                              label: '매물 등록하기',
                              icon: Icons.check_circle_outline,
                              onTap: () async {
                                setState(() {
                                  _fabMenuOpen = false;
                                });

                                final verified = await _ensureIdentityVerified(
                                  context,
                                );
                                if (!verified) return;

                                context.push(
                                  '/add_item/item_registration_list',
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
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
            );
          },
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
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ].reversed.toList(),
      ),
    );
  }
}
