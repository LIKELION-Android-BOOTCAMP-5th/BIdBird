import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/item/item_time_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShippingInfoViewPopup extends StatelessWidget {
  const ShippingInfoViewPopup({
    super.key,
    required this.createdAt,
    required this.carrier,
    required this.trackingNumber,
  });

  final String? createdAt;
  final String? carrier;
  final String? trackingNumber;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: defaultBorder),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '배송 정보',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            _buildInfoRow('생성일', createdAt != null ? formatDateTimeFromIso(createdAt!) : '-'),
            const SizedBox(height: 16),
            _buildInfoRow('택배사', carrier ?? '-'),
            const SizedBox(height: 16),
            _buildTrackingNumberRow('송장 번호', trackingNumber ?? '-', context),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(blueColor),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: defaultBorder,
                    ),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('확인'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: BackgroundColor,
            borderRadius: defaultBorder,
            border: Border.all(color: BorderColor),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingNumberRow(String label, String value, BuildContext context) {
    final hasTrackingNumber = value != '-' && value.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: BackgroundColor,
            borderRadius: defaultBorder,
            border: Border.all(color: BorderColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
              ),
              if (hasTrackingNumber) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: value));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('송장 번호가 복사되었습니다'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.content_copy,
                      size: 16,
                      color: iconColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

