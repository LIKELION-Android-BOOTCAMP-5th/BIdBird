import 'package:bidbird/core/utils/ui_set/colors.dart';
import 'package:bidbird/features/item/item_registration_list/viewmodel/item_registration_list_viewmodel.dart';
import 'package:bidbird/features/item/widgets/history_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RegistrationViewModel>(
      create: (_) => RegistrationViewModel()..loadPendingItems(),
      child: Consumer<RegistrationViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('매물 등록 확인'),
              centerTitle: true,
            ),
            backgroundColor: BackgroundColor,
            body: SafeArea(
              child: _buildBody(context, viewModel),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, RegistrationViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.error != null) {
      return Center(
        child: Text(
          viewModel.error!,
          style: const TextStyle(fontSize: 14),
        ),
      );
    }

    if (viewModel.items.isEmpty) {
      return const Center(
        child: Text('등록 대기 중인 매물이 없습니다.'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: viewModel.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = viewModel.items[index];
        return HistoryCard(
          title: item.title,
          thumbnailUrl: item.thumbnailUrl,
          status: '등록 대기',
          date: null,
          onTap: () async {
            final result = await context.push(
              '/add_item/item_registration_detail',
              extra: item,
            );
            if (result == true) {
              viewModel.loadPendingItems();
            }
          },
        );
      },
    );
  }
}

