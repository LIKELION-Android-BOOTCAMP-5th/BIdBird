import 'package:flutter/material.dart';
import 'package:bidbird/core/utils/ui_set/colors.dart';
import 'package:bidbird/features/item/current_trade/viewmodel/current_trade_viewmodel.dart';
import '../../../../core/utils/ui_set/border_radius.dart';

class HistoryCard extends StatelessWidget {
  const HistoryCard({
    super.key,
    required this.title,
    this.thumbnailUrl,
    required this.status,
    this.date,
    this.onTap,
  });

  final String title;
  final String? thumbnailUrl;
  final String status;
  final String? date;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: BackgroundColor,
          border: Border.all(color: iconColor.withOpacity(0.2), width: 1),
          borderRadius: defaultBorder,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
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
                      child: (thumbnailUrl != null && thumbnailUrl!.isNotEmpty)
                          ? Image.network(
                              thumbnailUrl!,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color:
                              BackgroundColor,
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
                padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox.shrink(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              status,
                              style: TextStyle(
                                color:
                                    CurrentTradeViewModel.getStatusColor(status),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (date != null && date!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                date!,
                                style: const TextStyle(
                                  color: iconColor,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}