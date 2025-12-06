import 'package:bidbird/core/utils/ui_set/colors.dart';
import 'package:bidbird/core/utils/ui_set/fonts.dart';
import 'package:bidbird/core/utils/ui_set/border_radius.dart';
import 'package:flutter/material.dart';

class ConfirmCheckCancelPopup extends StatefulWidget {
  final String title;
  final String? description;
  final String checkLabel;
  final String confirmText;
  final String cancelText;
  final void Function(bool isChecked) onConfirm;
  final VoidCallback onCancel;

  const ConfirmCheckCancelPopup({
    super.key,
    required this.title,
    this.description,
    this.checkLabel = '',
    this.confirmText = '확인',
    this.cancelText = '취소',
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<ConfirmCheckCancelPopup> createState() => _ConfirmCheckCancelPopupState();
}

class _ConfirmCheckCancelPopupState extends State<ConfirmCheckCancelPopup> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bool requireCheck = widget.checkLabel.isNotEmpty;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: defaultBorder,
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SafeArea(
        minimum: const EdgeInsets.all(0),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: mediaQuery.size.height * 0.6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: titleFontStyle,
                ),
                if (widget.description != null) ...[
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        widget.description!,
                        textAlign: TextAlign.left,
                        style: contentFontStyle,
                      ),
                    ),
                  ),
                ],
                if (widget.checkLabel.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _checked,
                        activeColor: blueColor,
                        onChanged: (value) {
                          setState(() {
                            _checked = value ?? false;
                          });
                        },
                      ),
                      Text(
                        widget.checkLabel,
                        style: contentFontStyle,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: FilledButton(
                          style: ButtonStyle(
                            backgroundColor:
                                WidgetStateProperty.resolveWith(
                              (states) {
                                if (states.contains(WidgetState.disabled)) {
                                  return Colors.grey.shade300;
                                }
                                return blueColor;
                              },
                            ),
                          ),
                          onPressed: requireCheck
                              ? (_checked
                                  ? () {
                                      Navigator.of(context).pop();
                                      widget.onConfirm(_checked);
                                    }
                                  : null)
                              : () {
                                  Navigator.of(context).pop();
                                  widget.onConfirm(true);
                                },
                          child: Text(
                            widget.confirmText,
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
                                WidgetStateProperty.all<Color>(
                                    Colors.grey.shade100),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onCancel();
                          },
                          child: Text(
                            widget.cancelText,
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
        ),
      ),
    );
  }
}
