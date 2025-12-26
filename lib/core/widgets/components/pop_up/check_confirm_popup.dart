import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/fonts_style.dart';
import 'package:flutter/material.dart';

/// 체크박스 확인 팝업
/// 체크박스를 체크해야만 확인 버튼이 활성화되는 팝업
class CheckConfirmPopup extends StatefulWidget {
  final String title;
  final String? description;
  final String checkLabel;
  final String confirmText;
  final String cancelText;
  final void Function() onConfirm;
  final VoidCallback? onCancel;

  const CheckConfirmPopup({
    super.key,
    required this.title,
    this.description,
    required this.checkLabel,
    this.confirmText = '확인',
    this.cancelText = '취소',
    required this.onConfirm,
    this.onCancel,
  });

  @override
  State<CheckConfirmPopup> createState() => _CheckConfirmPopupState();

  /// 팝업을 표시하는 헬퍼 메서드
  static void show(
    BuildContext context, {
    required String title,
    String? description,
    required String checkLabel,
    String confirmText = '확인',
    String cancelText = '취소',
    required void Function() onConfirm,
    VoidCallback? onCancel,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => CheckConfirmPopup(
        title: title,
        description: description,
        checkLabel: checkLabel,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: () {
          Navigator.of(dialogContext).pop();
          onConfirm();
        },
        onCancel: onCancel != null
            ? () {
                Navigator.of(dialogContext).pop();
                onCancel();
              }
            : () {
                Navigator.of(dialogContext).pop();
              },
      ),
    );
  }
}

class _CheckConfirmPopupState extends State<CheckConfirmPopup> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bool hasDescription = widget.description != null;
    final bool isLongDescription =
        (widget.description != null && widget.description!.length > 200);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: defaultBorder),
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
                if (hasDescription) ...[
                  const SizedBox(height: 8),
                  if (isLongDescription)
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: Text(
                          widget.description!,
                          textAlign: TextAlign.left,
                          style: contentFontStyle,
                        ),
                      ),
                    )
                  else
                    Text(
                      widget.description!,
                      textAlign: TextAlign.left,
                      style: contentFontStyle,
                    ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Transform.translate(
                      offset: const Offset(-4, 0),
                      child: Checkbox(
                        value: _checked,
                        activeColor: blueColor,
                        visualDensity: const VisualDensity(
                          horizontal: -3,
                          vertical: -3,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (value) {
                          setState(() {
                            _checked = value ?? false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(widget.checkLabel, style: contentFontStyle),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: FilledButton(
                          style: ButtonStyle(
                            backgroundColor:
                                WidgetStateProperty.resolveWith<Color?>((
                                  states,
                                ) {
                                  if (states.contains(WidgetState.disabled)) {
                                    return Colors.grey.shade300;
                                  }
                                  return blueColor;
                                }),
                          ),
                          onPressed: _checked
                              ? () {
                                  widget.onConfirm();
                                }
                              : null,
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
                    if (widget.onCancel != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: FilledButton(
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all<Color>(
                                Colors.grey.shade100,
                              ),
                            ),
                            onPressed: widget.onCancel,
                            child: Text(
                              widget.cancelText,
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                      ),
                    ],
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
