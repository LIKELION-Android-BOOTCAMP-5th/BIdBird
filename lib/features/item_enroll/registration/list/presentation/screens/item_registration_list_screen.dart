import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/features/item_enroll/registration/list/presentation/viewmodels/item_registration_list_viewmodel.dart';
import 'package:bidbird/features/item_trade/trade_status/presentation/widgets/history_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ItemRegistrationListScreen extends StatelessWidget {
  const ItemRegistrationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ItemRegistrationListViewModel>(
      create: (_) => ItemRegistrationListViewModel()..loadPendingItems(),
      child: Consumer<ItemRegistrationListViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () {
                  context.go('/home');
                },
              ),
              title: const Text('매물 등록 확인'),
              centerTitle: true,
            ),
            backgroundColor: BackgroundColor,
            body: SafeArea(child: _buildBody(context, viewModel)),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, ItemRegistrationListViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: 0.8,
                child: Text(
                  '로딩중',
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
                    decoration: TextDecoration.none,
                    decorationColor: Colors.transparent,
                    decorationThickness: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (viewModel.error != null) {
      return Center(
        child: Text(viewModel.error!, style: const TextStyle(fontSize: 14)),
      );
    }

    if (viewModel.items.isEmpty) {
      return const Center(child: Text('등록 대기 중인 매물이 없습니다.'));
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



