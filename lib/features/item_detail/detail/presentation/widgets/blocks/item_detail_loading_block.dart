import 'package:flutter/material.dart';

class ItemDetailLoadingBlock extends StatelessWidget {
  const ItemDetailLoadingBlock({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
