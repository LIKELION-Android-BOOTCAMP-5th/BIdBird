import 'package:bidbird/core/utils/ui_set/colors.dart';
import 'package:bidbird/core/utils/ui_set/fonts.dart';
import 'package:bidbird/core/utils/ui_set/border_radius.dart';
import 'package:flutter/material.dart';

class ConfirmCancelPopup extends StatelessWidget {
  final String title;
  final String? description;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const ConfirmCancelPopup({
    super.key,
    required this.title,
    this.description,
    this.confirmText = '확인',
    this.cancelText = '취소',
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: defaultBorder,
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: titleFontStyle,
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: contentFontStyle,
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: FilledButton(
                      style: ButtonStyle(
                        backgroundColor:
                            WidgetStateProperty.all<Color>(blueColor),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        onConfirm();
                      },
                      child: Text(
                        confirmText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: FilledButton(
                      style: ButtonStyle(
                        backgroundColor:
                            WidgetStateProperty.all<Color>(Colors.grey.shade100),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        onCancel();
                      },
                      child: Text(
                        cancelText,
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
