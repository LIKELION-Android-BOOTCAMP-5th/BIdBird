import 'package:bidbird/core/widgets/item/components/others/transparent_refresh_indicator.dart';
import 'package:bidbird/features/bid/domain/entities/item_bid_win_entity.dart';
import 'package:bidbird/features/item_detail/detail/data/datasources/item_detail_datasource.dart';
import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart';
import 'package:bidbird/features/notification/presentation/viewmodel/notification_viewmodel.dart';
import 'package:bidbird/features/notification/presentation/widgets/notification_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationViewmodel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text("알림"),
            actions: [
              TextButton(
                onPressed: viewModel.notifyList.length > 0
                    ? () {
                        viewModel.deleteAllNotification();
                      }
                    : () {},
                child: Text("전체 삭제"),
              ),
              TextButton(
                onPressed: viewModel.unCheckedCount > 0
                    ? () {
                        viewModel.checkAllNotification();
                      }
                    : () {},
                child: Text("전체 읽음"),
              ),
            ],
          ),
          body: SafeArea(child: _buildBody(context, viewModel)),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, NotificationViewmodel viewModel) {
    // if (viewModel.isLoading) {
    //   return const Center(child: CircularProgressIndicator());
    // }
    //
    // if (viewModel.error != null) {
    //   return Center(
    //     child: Text(viewModel.error!, style: const TextStyle(fontSize: 14)),
    //   );
    // }
    //
    if (viewModel.notifyList.isEmpty) {
      return const Center(child: Text('알림이 없습니다.'));
    }

    return Expanded(
      child: TransparentRefreshIndicator(
        onRefresh: viewModel.fetchNotify,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: viewModel.notifyList.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final notify = viewModel.notifyList[index];
            final type = notify.alarm_type;
            return NotificationCard(
              title: notify.title,
              status: '',
              body: notify.body,
              date: notify.created_at,
              is_checked: notify.is_checked,
              onDelete: () {
                viewModel.deleteNotification(notify.id);
              },
              onTap: () async {
                if (!notify.is_checked) {
                  viewModel.checkNotification(notify.id);
                }
                if (viewModel.toItemDetail.contains(type)) {
                  context.push('/item/${notify.item_id}');
                }

                if (type == "WIN") {
                  ItemDetailDatasource _datasource = ItemDetailDatasource();
                  final String? itemId = notify.item_id;
                  if (itemId == null) return;
                  final ItemDetail? item = await _datasource.fetchItemDetail(
                    itemId,
                  );
                  if (item == null) {
                    print("낙찰 화면으로 이동");
                    context.push('/item_bid_win');
                    return;
                  }
                  ItemBidWinEntity itemBidWinEntity =
                      ItemBidWinEntity.fromItemDetail(item);
                  context.push('/item_bid_win', extra: itemBidWinEntity);
                }
              },
            );
          },
        ),
      ),
    );
  }
}
