import 'package:flutter/material.dart';

class ItemRelistScreen extends StatelessWidget {
  const ItemRelistScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('유찰 매물 재등록'),
        centerTitle: true,
      ),
      body: Center(
        child: Text('유찰된 매물($itemId)을 재등록하는 화면입니다.'),
      ),
    );
  }
}



