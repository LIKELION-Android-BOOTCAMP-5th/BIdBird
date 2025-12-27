import 'package:bidbird/core/utils/item/item_registration_terms.dart';
import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:flutter/material.dart';

class ItemRegistrationTermsPopup extends StatefulWidget {
  final String title;
  final List<TermSection> sections;
  final String checkLabel;
  final String confirmText;
  final String cancelText;
  final void Function(bool isChecked) onConfirm;
  final VoidCallback onCancel;

  const ItemRegistrationTermsPopup({
    super.key,
    required this.title,
    required this.sections,
    this.checkLabel = '',
    this.confirmText = '확인',
    this.cancelText = '취소',
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<ItemRegistrationTermsPopup> createState() =>
      _ItemRegistrationTermsPopupState();
}

class _ItemRegistrationTermsPopupState extends State<ItemRegistrationTermsPopup> {
  bool _checked = false;
  final Set<int> _readSections = {};
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final allRead = _readSections.length == widget.sections.length;
    
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: defaultBorder),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SafeArea(
        minimum: const EdgeInsets.all(0),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              
              // 약관 목록 (Dynamic Height)
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                       for (int i=0; i < widget.sections.length; i++)
                         _buildTermSection(widget.sections[i], i),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 체크박스
              InkWell(
                onTap: allRead ? () {
                  setState(() {
                    _checked = !_checked;
                  });
                } : null,
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _checked,
                        activeColor: blueColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: allRead ? (value) {
                          setState(() {
                            _checked = value ?? false;
                          });
                        } : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.checkLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: allRead ? Colors.black87 : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!allRead)
                Padding(
                 padding: const EdgeInsets.only(left: 32, top: 4),
                 child: Text(
                   "모든 약관을  확인해야 동의할 수 있습니다.",
                   style: TextStyle(
                     fontSize: 12,
                     color: Colors.red.shade400,
                   ),
                 ),
                ),
              
              const SizedBox(height: 24),
              
              // 버튼 영역
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onCancel();
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          widget.cancelText,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _checked && allRead
                            ? () {
                                Navigator.of(context).pop();
                                widget.onConfirm(_checked);
                              }
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: blueColor,
                          disabledBackgroundColor: const Color(0xFFE0E0E0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          widget.confirmText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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
    );
  }

  Widget _buildTermSection(TermSection section, int index) {
    final bool isExpanded = _expandedIndex == index;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: Key('section_${index}_$isExpanded'), 
          initiallyExpanded: isExpanded,
          onExpansionChanged: (expanded) {
            if (expanded) {
              setState(() {
                _expandedIndex = index;
                _readSections.add(index);
              });
            } else {
               setState(() {
                 if (_expandedIndex == index) _expandedIndex = null;
               });
            }
          },
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                   if (_readSections.contains(index))
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(Icons.check_circle, size: 14, color: blueColor),
                      ),
                  Expanded(
                    child: Text(
                      section.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isExpanded ? blueColor : const Color(0xFF333333),
                      ),
                    ),
                  ),
                ],
              ),
              if (!isExpanded) ...[
                const SizedBox(height: 4),
                 Text(
                   section.summary,
                   style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                    fontWeight: FontWeight.normal,
                   ),
                   maxLines: 1,
                   overflow: TextOverflow.ellipsis,
                 ),
              ]
            ],
          ),
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
             // Divider between title/summary and content
             const Divider(height: 1, color: Color(0xFFEEEEEE)),
             const SizedBox(height: 12),
            Text(
              section.content,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF555555),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
