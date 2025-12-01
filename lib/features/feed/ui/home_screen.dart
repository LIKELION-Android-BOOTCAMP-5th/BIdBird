import 'package:bidbird/core/utils/ui_set/icons.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              'assets/logos/bidbird_text_logo.png',
              width: 100,
              height: 100,
            ),
            Row(
              spacing: 25,
              children: [
                Image.asset(
                  'assets/icons/search_icon.png',
                  width: appbarIconSize.width,
                  height: appbarIconSize.height,
                ),
                Image.asset(
                  'assets/icons/alarm_icon.png',
                  width: appbarIconSize.width,
                  height: appbarIconSize.height,
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                  ),
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    return Container(color: Colors.white);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
