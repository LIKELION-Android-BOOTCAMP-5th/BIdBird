import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/widgets/item/components/others/transparent_refresh_indicator.dart';
import 'package:bidbird/features/bid/domain/entities/item_bid_win_entity.dart';
import 'package:bidbird/features/item_detail/detail/data/datasources/item_detail_datasource.dart';
import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart';
import 'package:bidbird/features/notification/domain/entities/notification_entity.dart';
import 'package:bidbird/features/notification/presentation/viewmodel/notification_viewmodel.dart';
import 'package:bidbird/features/notification/presentation/widgets/notification_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final viewModel = context.read<NotificationViewmodel>();

    if (state == AppLifecycleState.resumed) {
      viewModel.onAppResumed();
    }
    if (state == AppLifecycleState.paused) {
      viewModel.onAppPaused();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

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

  double notificationActionExtentRatio({required bool isChecked}) {
    if (isChecked) {
      // 삭제만
      return 0.15;
    } else {
      // 읽음 + 삭제
      return 0.27;
    }
  }

  Widget _buildReadAction(
    NotificationEntity notify,
    NotificationViewmodel viewModel,
  ) {
    return SlidableAction(
      onPressed: (_) {
        viewModel.checkNotification(notify.id);
      },
      backgroundColor: Colors.grey.withOpacity(0.12),
      foregroundColor: Colors.grey.shade700,
      icon: Icons.done,
      // borderRadius: BorderRadius.circular(16),
    );
  }

  Widget _buildDeleteAction(
    NotificationEntity notify,
    NotificationViewmodel viewModel,
  ) {
    return SlidableAction(
      onPressed: (_) {
        viewModel.removeNotificationLocally(notify.id);
        viewModel.deleteNotification(notify.id);
      },
      backgroundColor: Colors.red.withOpacity(0.08),
      foregroundColor: Colors.red.withOpacity(0.9),
      icon: Icons.delete_outline,
      // borderRadius: BorderRadius.circular(16),
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: Colors.red, borderRadius: defaultBorder),
      child: const Icon(Icons.delete, color: Colors.white, size: 28),
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
    // if (viewModel.notifyList.isEmpty) {
    //   return const Center(child: Text('알림이 없습니다.'));
    // }

    return TransparentRefreshIndicator(
      onRefresh: viewModel.fetchNotify,
      child: viewModel.notifyList.isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.8,
                child: const Center(child: Text('알림이 없습니다.')),
              ),
            )
          : SlidableAutoCloseBehavior(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                itemCount: viewModel.notifyList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final notify = viewModel.notifyList[index];
                  final type = notify.alarm_type;
                  return ClipRRect(
                    borderRadius: defaultBorder,
                    child: Slidable(
                      // 👉 오른쪽에서 액션 등장
                      endActionPane: ActionPane(
                        motion: const StretchMotion(), // 밀리는 느낌 좋음
                        extentRatio: notificationActionExtentRatio(
                          isChecked: notify.is_checked,
                        ),

                        children: [
                          // 🗑 삭제
                          _buildDeleteAction(notify, viewModel),

                          // 👁 읽음 처리
                          if (!notify.is_checked)
                            _buildReadAction(notify, viewModel),
                        ],
                      ),

                      child: NotificationCard(
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
                            ItemDetailDatasource _datasource =
                                ItemDetailDatasource();
                            final String? itemId = notify.item_id;
                            if (itemId == null) return;
                            final ItemDetail? item = await _datasource
                                .fetchItemDetail(itemId);
                            if (item == null) {
                              print("낙찰 화면으로 이동");
                              context.push('/item_bid_win');
                              return;
                            }
                            ItemBidWinEntity itemBidWinEntity =
                                ItemBidWinEntity.fromItemDetail(item);
                            context.push(
                              '/item_bid_win',
                              extra: itemBidWinEntity,
                            );
                          }
                        },
                        type: type,
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
