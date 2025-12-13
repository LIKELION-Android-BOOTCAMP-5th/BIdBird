import 'package:bidbird/features/item/detail/model/item_detail_entity.dart';
import 'package:bidbird/features/item/detail/viewmodel/item_detail_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../report/ui/report_screen.dart';
import 'package:bidbird/core/widgets/item/detail/item_image_section.dart';
import 'package:bidbird/core/widgets/item/detail/item_main_info_section.dart';
import 'package:bidbird/core/widgets/item/detail/item_description_section.dart';
import 'package:bidbird/core/widgets/item/detail/item_bottom_action_bar.dart';

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ItemDetailViewModel>(
      create: (_) => ItemDetailViewModel(itemId: itemId)
        ..loadItemDetail()
        ..setupRealtimeSubscription(),
      child: const _ItemDetailScaffold(),
    );
  }
}

class _ItemDetailScaffold extends StatefulWidget {
  const _ItemDetailScaffold();

  @override
  State<_ItemDetailScaffold> createState() => _ItemDetailScaffoldState();
}

class _ItemDetailScaffoldState extends State<_ItemDetailScaffold> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ItemDetailViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return const Scaffold(
            body: SafeArea(
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (vm.error != null || vm.itemDetail == null) {
          return const Scaffold(
            body: SafeArea(
              child: Center(
                child: Text(
                  '매물 정보를 불러올 수 없습니다.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
          );
        }

        final ItemDetail item = vm.itemDetail!;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('상세 보기'),
            actions: [
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReportScreen(
                        itemId: item.itemId,
                        itemTitle: item.itemTitle,
                        targetUserId: item.sellerId,
                        targetNickname: vm.sellerProfile?['nick_name'] as String?,
                      ),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.only(right: 12, left: 4),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(
                  Icons.report_gmailerrorred_outlined,
                  color: Colors.red,
                  size: 18,
                ),
                label: const Text(
                  '신고',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ItemImageSection(item: item),
                        const SizedBox(height: 8),
                        ItemMainInfoSection(item: item, isMyItem: vm.isMyItem),
                        const SizedBox(height: 0),
                        ItemDescriptionSection(item: item),
                      ],
                    ),
                  ),
                ),
                ItemBottomActionBar(item: item, isMyItem: vm.isMyItem),
              ],
            ),
          ),
        );
      },
    );
  }
}
