import 'package:flutter/material.dart';

class ItemAddScreen extends StatelessWidget {
  const ItemAddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('매물 등록'),
      ),
      body: const Center(
        child: Text('매물 등록 화면입니다. TODO: UI 구현'),
      ),
    );
  }
}