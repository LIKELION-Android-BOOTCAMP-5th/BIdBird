import 'package:flutter/material.dart';

class AuctionStartDialog extends StatelessWidget {
  const AuctionStartDialog({
    super.key,
    required this.startAt,
    this.onConfirmed,
  });

  final DateTime startAt;
  final VoidCallback? onConfirmed;

  @override
  Widget build(BuildContext context) {
    final String hour = startAt.hour.toString().padLeft(2, '0');
    final String minute = startAt.minute.toString().padLeft(2, '0');

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text('경매 등록 완료'),
      content: Text('경매가 오늘 $hour:$minute 에 시작됩니다.'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            if (onConfirmed != null) {
              onConfirmed!();
            }
          },
          child: const Text('확인'),
        ),
      ],
    );
  }
}
