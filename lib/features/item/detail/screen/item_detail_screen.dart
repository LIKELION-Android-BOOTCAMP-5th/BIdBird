import 'package:bidbird/features/item/detail/model/item_detail_entity.dart';
import 'package:bidbird/features/item/detail/viewmodel/item_detail_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bidbird/features/report/screen/report_screen.dart';
import 'package:bidbird/core/widgets/item/components/sections/item_image_section.dart';
import 'package:bidbird/core/widgets/item/components/sections/item_main_info_section.dart';
import 'package:bidbird/core/widgets/item/components/sections/item_description_section.dart';
import 'package:bidbird/core/widgets/item/components/others/item_bottom_action_bar.dart';

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
    // 로딩 상태만 Selector로 분리
    return Selector<ItemDetailViewModel, bool>(
      selector: (_, vm) => vm.isLoading,
      builder: (context, isLoading, _) {
        if (isLoading) {
          return const Scaffold(
            body: SafeArea(
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        return const _ItemDetailContent();
      },
    );
  }
}

class _ItemDetailContent extends StatelessWidget {
  const _ItemDetailContent();

  @override
  Widget build(BuildContext context) {
    // 에러 상태와 itemDetail을 함께 Selector로 분리
    return Selector<ItemDetailViewModel, ({String? error, ItemDetail? itemDetail})>(
      selector: (_, vm) => (error: vm.error, itemDetail: vm.itemDetail),
      builder: (context, data, _) {
        if (data.error != null || data.itemDetail == null) {
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

        final ItemDetail item = data.itemDetail!;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: _ItemDetailAppBar(item: item),
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
                        _ItemMainInfoSection(item: item),
                        const SizedBox(height: 0),
                        ItemDescriptionSection(item: item),
                      ],
                    ),
                  ),
                ),
                _ItemBottomActionBar(item: item),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ItemDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ItemDetailAppBar({required this.item});

  final ItemDetail item;

  @override
  Widget build(BuildContext context) {
    // isMyItem과 sellerProfile만 Selector로 분리
    return Selector<ItemDetailViewModel, ({bool isMyItem, Map<String, dynamic>? sellerProfile})>(
      selector: (_, vm) => (isMyItem: vm.isMyItem, sellerProfile: vm.sellerProfile),
      builder: (context, data, _) {
        return AppBar(
          title: const Text('상세 보기'),
          actions: [
            if (!data.isMyItem)
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => ReportScreen(
                        itemId: item.itemId,
                        itemTitle: item.itemTitle,
                        targetUserId: item.sellerId,
                        targetNickname: data.sellerProfile?['nick_name'] as String?,
                      ),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: const Size(48, 48),
                ),
                icon: const Icon(
                  Icons.warning_outlined,
                  color: Colors.red,
                  size: 20,
                ),
                label: const Text(
                  '신고',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _ItemMainInfoSection extends StatelessWidget {
  const _ItemMainInfoSection({required this.item});

  final ItemDetail item;

  @override
  Widget build(BuildContext context) {
    // isMyItem만 Selector로 분리
    return Selector<ItemDetailViewModel, bool>(
      selector: (_, vm) => vm.isMyItem,
      builder: (context, isMyItem, _) {
        return ItemMainInfoSection(item: item, isMyItem: isMyItem);
      },
    );
  }
}

class _ItemBottomActionBar extends StatelessWidget {
  const _ItemBottomActionBar({required this.item});

  final ItemDetail item;

  @override
  Widget build(BuildContext context) {
    // isMyItem과 isFavorite를 함께 Selector로 분리
    return Selector<ItemDetailViewModel, ({bool isMyItem, bool isFavorite})>(
      selector: (_, vm) => (isMyItem: vm.isMyItem, isFavorite: vm.isFavorite),
      builder: (context, data, _) {
        // ItemBottomActionBar는 내부에서 context.watch를 사용하므로
        // ViewModel을 전달하지 않고 직접 사용하도록 함
        return ItemBottomActionBar(item: item, isMyItem: data.isMyItem);
      },
    );
  }
}
