import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart';
import 'package:bidbird/features/item_detail/detail/presentation/viewmodels/item_detail_viewmodel.dart';
import 'package:bidbird/features/item_detail/detail/presentation/widgets/blocks/item_detail_error_block.dart';
import 'package:bidbird/features/item_detail/detail/presentation/widgets/blocks/item_detail_content_block.dart';
import 'package:bidbird/features/item_detail/detail/presentation/widgets/sections/item_detail_app_bar_section.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ItemDetailViewModel>(
      create: (_) => ItemDetailViewModel(itemId: itemId)..loadItemDetail(),
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
    // 로딩 전용 인디케이터 제거: 항상 컨텐츠 빌더로 위임
    return const _ItemDetailContent();
  }
}

class _ItemDetailContent extends StatefulWidget {
  const _ItemDetailContent();

  @override
  State<_ItemDetailContent> createState() => _ItemDetailContentState();
}

class _ItemDetailContentState extends State<_ItemDetailContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 에러 상태와 itemDetail, isMyItem을 함께 Selector로 분리
    return Selector<
      ItemDetailViewModel,
      ({String? error, ItemDetail? itemDetail, bool isMyItem, bool isLoading})
    >(
      selector: (_, vm) => (error: vm.error, itemDetail: vm.itemDetail, isMyItem: vm.isMyItem, isLoading: vm.isLoading),
      builder: (context, data, _) {
        // 로딩 중에는 전체 화면 인디케이터 없이 빈 화면 유지
        if (data.isLoading && data.itemDetail == null) {
          return const Scaffold(
            body: SafeArea(child: SizedBox.shrink()),
            backgroundColor: BackgroundColor,
          );
        }

        if (data.itemDetail == null) {
          final msg = data.error ?? '상품을 찾을 수 없습니다.';
          return ItemDetailErrorBlock(
            message: msg,
            onRetry: () => context.read<ItemDetailViewModel>().loadItemDetail(forceRefresh: true),
          );
        }

        final item = data.itemDetail!;
        return ItemDetailContentBlock(
          item: item,
          isMyItem: data.isMyItem,
          onRefresh: () => context.read<ItemDetailViewModel>().loadItemDetail(forceRefresh: true),
          appBar: ItemDetailAppBarSection(item: item),
        );
      },
    );
  }
}
