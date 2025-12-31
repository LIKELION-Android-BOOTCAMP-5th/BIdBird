import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/widgets/item/components/others/transparent_refresh_indicator.dart';
import 'package:flutter/material.dart';

class UnifiedEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Future<void> Function()? onRefresh;

  const UnifiedEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: context.fontSizeMedium,
              color: TextSecondary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: context.fontSizeSmall,
                color: TextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );

    if (onRefresh != null) {
      return TransparentRefreshIndicator(
        onRefresh: onRefresh!,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: constraints.maxHeight,
                child: content,
              ),
            );
          },
        ),
      );
    }

    return content;
  }
}
