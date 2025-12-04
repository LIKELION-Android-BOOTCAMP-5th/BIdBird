import 'package:flutter/material.dart';

import '../../../../core/utils/ui_set/icons.dart';

class BidScreen extends StatelessWidget {
  const BidScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('입찰내역'),
            Image.asset(
              'assets/icons/alarm_icon.png',
              width: iconSize.width,
              height: iconSize.height,
            ),
          ],
        ),
      ),
    );
  }
}
