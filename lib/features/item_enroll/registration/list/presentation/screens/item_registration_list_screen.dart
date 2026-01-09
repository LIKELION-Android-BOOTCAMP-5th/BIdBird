import 'package:bidbird/core/widgets/unified_empty_state.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/widgets/item/components/fields/error_text.dart';
import 'package:bidbird/features/item_enroll/registration/list/domain/entities/item_registration_entity.dart';
import 'package:bidbird/features/item_enroll/registration/list/presentation/viewmodels/item_registration_list_viewmodel.dart';
import 'package:bidbird/features/item_enroll/registration/list/presentation/widgets/auction_item_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ItemRegistrationListScreen extends StatelessWidget {
  const ItemRegistrationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ItemRegistrationListViewModel>(
      create: (_) => ItemRegistrationListViewModel()..loadPendingItems(),
      child:
          Selector<
            ItemRegistrationListViewModel,
            ({bool isLoading, String? error, List<ItemRegistrationData> items})
          >(
            selector: (_, vm) =>
                (isLoading: vm.isLoading, error: vm.error, items: vm.items),
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
    ({bool isLoading, String? error, List<ItemRegistrationData> items}) data,
  ) {
    // 로딩 중: 배경색만 표시
    if (data.isLoading) {
      return Container(color: BackgroundColor);
    }

    if (data.error != null) {
      return Center(child: ErrorText(text: data.error!));
    }

    if (data.items.isEmpty) {
      return UnifiedEmptyState(
        title: '등록할 매물이 없습니다.',
        subtitle: '새로운 상품을 등록해보세요!',
        onRefresh: () async => context.read<ItemRegistrationListViewModel>().loadPendingItems(),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => viewModel.loadPendingItems(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(), // 리스트가 짧아도 스크롤 가능하게 함
        padding: EdgeInsets.fromLTRB(
          context.screenPadding,
          context.spacingSmall,
          context.screenPadding,
          context.spacingSmall,
        ),
        itemCount: data.items.length,
        separatorBuilder: (_, __) => SizedBox(height: context.spacingSmall),
        itemBuilder: (context, index) {
          final item = data.items[index];
          return AuctionItemCard(
            title: item.title,
            thumbnailUrl: item.thumbnailUrl,
            price: item.startPrice,
            auctionDurationHours: item.auctionDurationHours,
            useResponsive: true,
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
      ),
    );
  }
}
