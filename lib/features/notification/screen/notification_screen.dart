import 'package:bidbird/features/notification/screen/widgets/notification_card.dart';
import 'package:bidbird/features/notification/viewmodel/notification_viewmodel.dart';
import 'package:flutter/material.dart';
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
      child: RefreshIndicator(
        onRefresh: viewModel.fetchNotify,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: viewModel.notifyList.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final notify = viewModel.notifyList[index];
            return NotificationCard(
              title: notify.title,
              status: '',
              body: notify.body,
              date: notify.created_at,
              is_checked: notify.is_checked,
              onDelete: () {
                viewModel.deleteNotification(notify.id);
              },
              onTap: () {
                if (!notify.is_checked) {
                  viewModel.checkNotification(notify.id);
                }
              },
            );
          },
        ),
      ),
    );
  }
}
