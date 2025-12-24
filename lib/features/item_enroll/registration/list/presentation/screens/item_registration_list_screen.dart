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
    if (data.error != null) {
      return Center(child: ErrorText(text: data.error!));
    }

    if (data.items.isEmpty) {
      // 빈 상태에서는 별도 문구 없이 배경만 보여줌
      return Container(color: BackgroundColor);
    }

    return ListView.separated(
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
    );
  }
}
