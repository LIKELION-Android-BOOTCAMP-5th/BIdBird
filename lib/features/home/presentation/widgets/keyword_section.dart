import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodel/home_viewmodel.dart';

class KeywordWidget extends StatelessWidget {
  const KeywordWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // 길이와 선택 상태만 구독해 변경을 감지하고, 실제 리스트는 read로 조회
    final selected = context.select<HomeViewmodel, String>((vm) => vm.selectKeyword);
    final keywordCount = context.select<HomeViewmodel, int>((vm) => vm.keywords.length);
    final vm = context.read<HomeViewmodel>();
    final keywords = vm.keywords;
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 42,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: keywordCount,
          itemBuilder: (context, index) {
            final String keyword = keywords[index].title;
            final bool isSelected = keyword == selected;
            return Padding(
              padding: const EdgeInsets.only(top: 4, right: 4, left: 4),
              child: ElevatedButton(
                onPressed: () {
                  final keywordSelect = keywords[index];
                  vm.selectKeywordAndFetch(keywordSelect.title, keywordSelect.id);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected
                      ? Color(0xffe3ecfd)
                      : Colors.white,
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
                      color: isSelected ? Color(0xff3B82F6) : Color(0xff6B7280),
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
    );
  }
}
