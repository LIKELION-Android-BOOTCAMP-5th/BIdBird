import 'package:flutter/material.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';

class ItemRelistScreen extends StatelessWidget {
  const ItemRelistScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BackgroundColor,
      appBar: AppBar(
        title: const Text('유찰 매물 재등록'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(context.spacingMedium),
            child: Text(
              '유찰된 매물($itemId)을 재등록하는 화면입니다.',
              style: TextStyle(
                fontSize: context.fontSizeMedium,
                color: TextPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}



