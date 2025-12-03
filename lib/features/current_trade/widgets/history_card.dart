import 'package:flutter/material.dart';
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

  Color _statusColor() {
    if (status.contains('최고입찰 중') ||
        status.contains('즉시 구매') ||
        status == '낙찰') {
      return Colors.green;
    }
    if (status.contains('상위 입찰 발생')) {
      return Colors.orange;
    }
    if (status.contains('유찰') ||
        status.contains('패찰') ||
        status.contains('입찰 제한')) {
      return Colors.redAccent;
    }
    if (status.contains('입찰 없음')) {
      return Colors.grey;
    }
    return Colors.black54;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: defaultBorder,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
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
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image,
                          size: 32,
                          color: Colors.grey,
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
                                color: _statusColor(),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (date != null && date!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                date!,
                                style: const TextStyle(
                                  color: Colors.grey,
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