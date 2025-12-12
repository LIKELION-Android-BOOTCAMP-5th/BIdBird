import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:flutter/material.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.title,
    this.thumbnailUrl,
    required this.status,
    this.date,
    this.onTap,
    this.onDelete,
    required this.body,
    required this.is_checked,
  });

  final String title;
  final String? thumbnailUrl;
  final String status;
  final String? date;
  final String body;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool is_checked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: !is_checked ? Colors.white : Color(0xff6B7280),
          border: Border.all(color: iconColor.withValues(alpha: 0.2), width: 1),
          borderRadius: defaultBorder,
          boxShadow: const [
            BoxShadow(color: shadowHigh, blurRadius: 10, offset: Offset(0, 4)),
            BoxShadow(color: shadowLow, blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 96,
                  child: Container(
                    decoration: BoxDecoration(
                      color: BackgroundColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(defaultRadius),
                        bottomLeft: Radius.circular(defaultRadius),
                      ),
                    ),
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(defaultRadius),
                          child: Container(
                            color: BackgroundColor,
                            child: const Icon(
                              Icons.image,
                              size: 32,
                              color: iconColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(children: [Expanded(child: Text(body))]),
                        // Align(
                        //   alignment: Alignment.centerRight,
                        //   child: TradeStatusChip(
                        //     label: status,
                        //     color: CurrentTradeViewModel.getStatusColor(status),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
                IconButton(onPressed: onDelete, icon: Icon(Icons.close)),
              ],
            ),
            if (!is_checked)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3B82F6), // 파란색 (원하면 변경)
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
