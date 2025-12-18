import 'package:flutter/material.dart';

import '../../viewmodel/home_viewmodel.dart';

class KeywordWidget extends StatelessWidget {
  final HomeViewmodel viewModel;
  const KeywordWidget({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 42,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: viewModel.keywords.length,
          itemBuilder: (context, index) {
            final String keyword = viewModel.keywords[index].title;
            final bool isSelected = keyword == viewModel.selectKeyword;
            return Padding(
              padding: const EdgeInsets.only(top: 4, right: 4, left: 4),
              child: ElevatedButton(
                onPressed: () {
                  final keywordSelect = viewModel.keywords[index];
                  viewModel.selectKeywordAndFetch(
                    keywordSelect.title,
                    keywordSelect.id,
                  );
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
