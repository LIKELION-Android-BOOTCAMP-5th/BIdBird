import 'package:bidbird/core/services/time_ticker.dart';
import 'package:bidbird/core/utils/item/item_time_utils.dart' show formatRemainingTime;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeTimerSection extends StatelessWidget {
  const HomeTimerSection({super.key, required this.finishTime});

  final DateTime finishTime;

  @override
  Widget build(BuildContext context) {
    // TimeTicker의 now가 변할 때만 이 위젯이 갱신됩니다.
    final now = context.select<TimeTicker, DateTime>((t) => t.now);
    final isFinished = now.isAfter(finishTime);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isFinished ? Colors.black45 : const Color(0xffef6b6b),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isFinished ? '경매 종료' : formatRemainingTime(finishTime),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
