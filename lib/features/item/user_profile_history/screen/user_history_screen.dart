import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:flutter/material.dart';

class UserTradeHistoryScreen extends StatelessWidget {
  const UserTradeHistoryScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('거래내역'),
        centerTitle: true,
      ),
      backgroundColor: BackgroundColor,
      body: const Center(
        child: Text(
          '거래 내역 화면입니다.',
          style: TextStyle(fontSize: 14, color: Colors.white),
        ),
      ),
    );
  }
}
