import 'package:flutter/material.dart';
import 'package:bidbird/core/utils/item/item_registration_terms.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/fonts_style.dart';

class ItemRegistrationTermsPopup extends StatefulWidget {
  final String title;
  final List<TermSection> sections;
  final String checkLabel;
  final Function(bool) onConfirm;
  final VoidCallback onCancel;

  const ItemRegistrationTermsPopup({
    super.key,
    required this.title,
    required this.sections,
    required this.checkLabel,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<ItemRegistrationTermsPopup> createState() => _ItemRegistrationTermsPopupState();
}

class _ItemRegistrationTermsPopupState extends State<ItemRegistrationTermsPopup> {
  bool _isChecked = false;
  late List<bool> _isExpandedOnce;

  @override
  void initState() {
    super.initState();
    _isExpandedOnce = List.generate(widget.sections.length, (_) => false);
  }

  bool get _allSectionsRead => _isExpandedOnce.every((read) => read);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: titleFontStyle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.sections.asMap().entries.map((entry) {
                    final index = entry.key;
                    final section = entry.value;
                    return Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        title: Text(
                          section.title,
                          style: contentFontStyle.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _isExpandedOnce[index] ? blueColor : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          section.summary,
                          style: contentFontStyle.copyWith(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        childrenPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        onExpansionChanged: (expanded) {
                          if (expanded && !_isExpandedOnce[index]) {
                            setState(() {
                              _isExpandedOnce[index] = true;
                            });
                          }
                        },
                        children: [
                          Text(
                            section.content,
                            style: contentFontStyle.copyWith(
                              fontSize: 13,
                              color: TextPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (!_allSectionsRead)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Center(
                  child: Text(
                    '모든 약관 항목을 펼쳐서 확인해주세요',
                    style: TextStyle(
                      color: Colors.red[400],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            const Divider(),
            Opacity(
              opacity: _allSectionsRead ? 1.0 : 0.5,
              child: Row(
                children: [
                  Checkbox(
                    value: _isChecked,
                    activeColor: blueColor,
                    onChanged: _allSectionsRead
                        ? (value) {
                            setState(() {
                              _isChecked = value ?? false;
                            });
                          }
                        : null,
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: _allSectionsRead
                          ? () {
                              setState(() {
                                _isChecked = !_isChecked;
                              });
                            }
                          : null,
                      child: Text(
                        widget.checkLabel,
                        style: contentFontStyle.copyWith(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onCancel();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('취소', style: TextStyle(color: Colors.black)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_allSectionsRead && _isChecked)
                        ? () {
                            Navigator.pop(context);
                            widget.onConfirm(_isChecked);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blueColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('확인'),
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
