import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/widgets/item/components/fields/error_text.dart';
import 'package:bidbird/features/item_enroll/registration/list/domain/entities/item_registration_entity.dart';
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
      child: Selector<ItemRegistrationListViewModel, ({
        bool isLoading,
        String? error,
        List<ItemRegistrationData> items,
      })>(
        selector: (_, vm) => (
          isLoading: vm.isLoading,
          error: vm.error,
          items: vm.items,
        ),
        builder: (context, data, _) {
          final viewModel = context.read<ItemRegistrationListViewModel>();
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
            body: SafeArea(child: _buildBody(context, viewModel, data)),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ItemRegistrationListViewModel viewModel,
    ({
      bool isLoading,
      String? error,
      List<ItemRegistrationData> items,
    }) data,
  ) {
    if (data.isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: context.spacingSmall),
            Text(
              '로딩중',
              style: TextStyle(
                fontSize: context.fontSizeSmall,
                color: textColor,
              ),
            ),
          ],
        ),
      );
    }

    if (data.error != null) {
      return Center(
        child: ErrorText(text: data.error!),
      );
    }

    if (data.items.isEmpty) {
      return const Center(child: Text('등록 대기 중인 매물이 없습니다.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: data.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = data.items[index];
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



