import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/fonts_style.dart';
import 'package:flutter/material.dart';

class ShippingInfoInputPopup extends StatefulWidget {
  const ShippingInfoInputPopup({
    super.key,
    required this.onConfirm,
    this.initialCarrier,
    this.initialTrackingNumber,
  });

  final Future<void> Function(String carrier, String trackingNumber) onConfirm;
  final String? initialCarrier;
  final String? initialTrackingNumber;

  @override
  State<ShippingInfoInputPopup> createState() => _ShippingInfoInputPopupState();
}

class _ShippingInfoInputPopupState extends State<ShippingInfoInputPopup> {
  late final TextEditingController _carrierController;
  late final TextEditingController _trackingNumberController;
  bool _isEditing = false;
  bool _hasExistingData = false;

  @override
  void initState() {
    super.initState();
    _hasExistingData = widget.initialCarrier != null && 
                       widget.initialCarrier!.isNotEmpty &&
                       widget.initialTrackingNumber != null && 
                       widget.initialTrackingNumber!.isNotEmpty;
    
    _carrierController = TextEditingController(
      text: widget.initialCarrier ?? '',
    );
    _trackingNumberController = TextEditingController(
      text: widget.initialTrackingNumber ?? '',
    );
    
    _isEditing = !_hasExistingData;
  }

  @override
  void dispose() {
    _carrierController.dispose();
    _trackingNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.7;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목
                Text(
                  _hasExistingData ? '송장 정보' : '송장 정보 입력',
                  style: contentFontStyle.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 20),

                // 택배사 입력
                Text(
                  '택배사',
                  style: contentFontStyle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _carrierController,
                  enabled: _isEditing,
                  decoration: InputDecoration(
                    hintText: '택배사명을 입력하세요',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: blueColor, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 16),

                // 송장번호 입력
                Text(
                  '송장번호',
                  style: contentFontStyle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _trackingNumberController,
                  enabled: _isEditing && !_hasExistingData, // 기존 송장 번호가 있으면 수정 불가
                  decoration: InputDecoration(
                    hintText: '송장번호를 입력하세요',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: blueColor, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 24),

                // 버튼 영역
                if (_hasExistingData && !_isEditing)
                  // 기존 정보가 있고 편집 모드가 아닐 때: 닫기 버튼만 (송장 정보는 수정 불가)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(blueColor),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('닫기'),
                    ),
                  )
                else
                  // 편집 모드일 때: 취소 + 확인 버튼
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: FilledButton(
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                              Colors.grey.shade100,
                            ),
                          ),
                          onPressed: () {
                            if (_hasExistingData) {
                              // 기존 정보가 있으면 읽기 모드로 돌아가기
                              setState(() {
                                _isEditing = false;
                                _carrierController.text = widget.initialCarrier ?? '';
                                _trackingNumberController.text = widget.initialTrackingNumber ?? '';
                              });
                            } else {
                              Navigator.pop(context);
                            }
                          },
                          child: Text(
                            _hasExistingData ? '취소' : '취소',
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(blueColor),
                          ),
                          onPressed: () async {
                            if (_carrierController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('택배사를 입력해주세요'),
                                ),
                              );
                              return;
                            }
                            
                            // 송장 번호가 이미 있으면 기존 값 유지, 없으면 입력값 사용
                            final trackingNumber = _hasExistingData 
                                ? (widget.initialTrackingNumber ?? _trackingNumberController.text.trim())
                                : _trackingNumberController.text.trim();
                            
                            if (trackingNumber.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('송장번호를 입력해주세요'),
                                ),
                              );
                              return;
                            }
                            
                            await widget.onConfirm(
                              _carrierController.text.trim(),
                              trackingNumber,
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                          child: const Text('확인'),
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

