import 'package:bidbird/features/mypage/data/repositories/terms_repository_impl.dart';
import 'package:bidbird/features/mypage/domain/usecases/get_terms_content.dart';
import 'package:bidbird/features/mypage/viewmodel/terms_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/ui_set/border_radius_style.dart';
import '../../../core/utils/ui_set/fonts_style.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ChangeNotifierProvider<TermsViewModel>(
      create: (_) => TermsViewModel(GetTermsContent(TermsRepositoryImpl())),
      child: Builder(
        builder: (context) {
          final vm = context.read<TermsViewModel>();
          final isLoading = context.select<TermsViewModel, bool>(
            (vm) => vm.isLoading,
          );
          final termsContent = context.select<TermsViewModel, List>(
            (vm) => vm.termsContent,
          );
          final errorMessage = context.select<TermsViewModel, String?>(
            (vm) => vm.errorMessage,
          );

          Widget body;
          if (isLoading && termsContent.isEmpty) {
            body = const Center(child: CircularProgressIndicator());
          } else if (errorMessage != null) {
            body = Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('약관을 불러오지 못했습니다.'),
                    const SizedBox(height: 8),
                    Text(errorMessage, textAlign: TextAlign.center),
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
                // final sectionHeight = constraints.maxHeight * 0.8;

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      children: termsContent
                          .map(
                            (section) => Container(
                              width: double.infinity,
                              // height: sectionHeight,
                              // margin: const EdgeInsets.all(5), //두개사이의간격
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: defaultBorder,
                              ),
                              child: SingleChildScrollView(
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      section.title,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 30),
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
