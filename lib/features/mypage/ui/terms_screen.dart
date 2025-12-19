import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/fonts_style.dart';
import 'package:bidbird/core/utils/ui_set/icons_style.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:bidbird/features/mypage/data/repositories/terms_repository_impl.dart';
import 'package:bidbird/features/mypage/domain/usecases/get_terms_content.dart';
import 'package:bidbird/features/mypage/viewmodel/terms_viewmodel.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ChangeNotifierProvider<TermsViewModel>(
      create: (_) => TermsViewModel(
        GetTermsContent(TermsRepositoryImpl()),
      ),
      child: Builder(
        builder: (context) {
          final vm = context.watch<TermsViewModel>();

          Widget body;
          if (vm.isLoading && vm.termsContent.isEmpty) {
            body = const Center(child: CircularProgressIndicator());
          } else if (vm.errorMessage != null) {
            body = Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('약관을 불러오지 못했습니다.'),
                    const SizedBox(height: 8),
                    Text(vm.errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: vm.loadTerms,
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            );
          } else {
            body = LayoutBuilder(
              builder: (context, constraints) {
                final sectionHeight = constraints.maxHeight * 0.8;

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      children: vm.termsContent
                          .map(
                            (section) => Container(
                              width: double.infinity,
                              height: sectionHeight,
                              margin: const EdgeInsets.all(16), //두개사이의간격
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: shadowLow,
                                borderRadius: defaultBorder,
                              ),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      section.title,
                                      style: contentFontStyle,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(section.body, style: contentFontStyle),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                );
              },
            );
          }

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
              title: const Text('약관확인'),
              centerTitle: true,
            ),
            body: SafeArea(child: body),
          );
        },
      ),
    );
  }
}
