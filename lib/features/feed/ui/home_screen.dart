import 'package:bidbird/core/utils/ui_set/colors.dart';
import 'package:bidbird/core/utils/ui_set/icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _fabMenuOpen = false;

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
                  width: iconSize.width,
                  height: iconSize.height,
                ),
                Image.asset(
                  'assets/icons/alarm_icon.png',
                  width: iconSize.width,
                  height: iconSize.height,
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
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
            if (_fabMenuOpen)
              Positioned(
                right: 16,
                bottom: 90,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _FabMenuItem(
                      label: '매물 등록하기',
                      icon: Icons.check_circle_outline,
                      onTap: () {
                        setState(() {
                          _fabMenuOpen = false;
                        });
                        context.push('/add_item/check');
                      },
                    ),
                    const SizedBox(height: 16),
                    _FabMenuItem(
                      label: '매물 작성',
                      icon: Icons.edit_outlined,
                      onTap: () {
                        setState(() {
                          _fabMenuOpen = false;
                        });
                        context.push('/add_item');
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _fabMenuOpen = !_fabMenuOpen;
          });
        },
        backgroundColor: blueColor,
        child: Icon(
          _fabMenuOpen ? Icons.close : Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _FabMenuItem extends StatelessWidget {
  const _FabMenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 22,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ].reversed.toList(),
      ),
    );
  }
}

