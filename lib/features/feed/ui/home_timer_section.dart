import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/utils/ui_set/colors_style.dart';
import '../../item/detail/screen/item_detail_utils.dart'
    show formatRemainingTime;

class HomeTimerSection extends StatefulWidget {
  const HomeTimerSection({super.key, required this.finishTime});

  final DateTime finishTime;

  @override
  State<HomeTimerSection> createState() => HomeTimerSectionState();
}

class HomeTimerSectionState extends State<HomeTimerSection> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (DateTime.now().isAfter(widget.finishTime)) {
        timer.cancel();
      }

      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFinished = DateTime.now().isAfter(widget.finishTime);

    return Container(
      // padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        color: isFinished ? Colors.black : RedColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isFinished ? '경매 종료' : '${formatRemainingTime(widget.finishTime)}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
