import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/fonts_style.dart';
import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
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
  bool _isFormValid = false;
  bool _isDirectTrade = false;
  bool _isUpdatingDirectTrade = false;

  @override
  void initState() {
    super.initState();
    _hasExistingData =
        widget.initialCarrier != null &&
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

    // 초기 상태에서 폼 유효성 검사
    _checkFormValidity();

    // 텍스트 변경 리스너 추가
    _carrierController.addListener(_checkFormValidity);
    _trackingNumberController.addListener(_checkFormValidity);
  }

  void _checkFormValidity() {
    if (!mounted || _isUpdatingDirectTrade) return;

    // 직거래 모드일 때는 항상 유효
    if (_isDirectTrade) {
      if (!_isFormValid) {
        setState(() {
          _isFormValid = true;
        });
      }
      return;
    }

    final carrierValid = _carrierController.text.trim().isNotEmpty;
    final trackingNumberValid = _hasExistingData
        ? (widget.initialTrackingNumber != null &&
              widget.initialTrackingNumber!.isNotEmpty)
        : _trackingNumberController.text.trim().isNotEmpty;

    final isValid = carrierValid && trackingNumberValid;
    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  @override
  void dispose() {
    _carrierController.removeListener(_checkFormValidity);
    _trackingNumberController.removeListener(_checkFormValidity);
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
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                  style: contentFontStyle.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _carrierController,
                  enabled: _isEditing && !_isDirectTrade,
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
                      borderSide: BorderSide(
                        color: (_isEditing && !_isDirectTrade)
                            ? blueColor
                            : Colors.grey.shade300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: (_isEditing && !_isDirectTrade)
                            ? blueColor
                            : Colors.grey.shade300,
                      ),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: blueColor, width: 2),
                    ),
                    filled: true,
                    fillColor: (_isEditing && !_isDirectTrade)
                        ? Colors.white
                        : Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 16),

                // 송장번호 입력
                Text(
                  '송장번호',
                  style: contentFontStyle.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _trackingNumberController,
                        enabled:
                            _isEditing &&
                            !_hasExistingData &&
                            !_isDirectTrade, // 기존 송장 번호가 있으면 수정 불가, 직거래 모드일 때도 비활성화
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
                            borderSide: BorderSide(
                              color:
                                  (_isEditing &&
                                      !_hasExistingData &&
                                      !_isDirectTrade)
                                  ? blueColor
                                  : Colors.grey.shade300,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color:
                                  (_isEditing &&
                                      !_hasExistingData &&
                                      !_isDirectTrade)
                                  ? blueColor
                                  : Colors.grey.shade300,
                            ),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: blueColor,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor:
                              (_isEditing &&
                                  !_hasExistingData &&
                                  !_isDirectTrade)
                              ? Colors.white
                              : Colors.grey.shade50,
                        ),
                      ),
                    ),
                    if (_isEditing && !_hasExistingData) ...[
                      const SizedBox(width: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '직거래',
                            style: contentFontStyle.copyWith(fontSize: 14),
                          ),
                          const SizedBox(width: 8),
                          Checkbox(
                            value: _isDirectTrade,
                            onChanged: (value) {
                              if (!mounted) return;

                              final newValue = value ?? false;

                              // 리스너를 일시적으로 제거하여 clear 시 리스너 트리거 방지
                              _carrierController.removeListener(
                                _checkFormValidity,
                              );
                              _trackingNumberController.removeListener(
                                _checkFormValidity,
                              );

                              // 업데이트 플래그 설정
                              _isUpdatingDirectTrade = true;

                              if (newValue) {
                                // 직거래 선택 시 입력 필드 비활성화
                                _carrierController.clear();
                                _trackingNumberController.clear();
                              }

                              setState(() {
                                _isDirectTrade = newValue;
                              });

                              // 리스너 다시 추가
                              _carrierController.addListener(
                                _checkFormValidity,
                              );
                              _trackingNumberController.addListener(
                                _checkFormValidity,
                              );

                              // 플래그 해제 및 폼 유효성 검사
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  _isUpdatingDirectTrade = false;
                                  _checkFormValidity();
                                }
                              });
                            },
                            activeColor: blueColor,
                          ),
                        ],
                      ),
                    ],
                  ],
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
                                _carrierController.text =
                                    widget.initialCarrier ?? '';
                                _trackingNumberController.text =
                                    widget.initialTrackingNumber ?? '';
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
                            backgroundColor: WidgetStateProperty.all(
                              _isFormValid ? blueColor : Colors.grey.shade300,
                            ),
                          ),
                          onPressed: _isFormValid
                              ? () async {
                                  // 확인 다이얼로그 표시
                                  if (!context.mounted) return;
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (dialogContext) => AskPopup(
                                      content: _isDirectTrade
                                          ? '직거래를 하시겠습니까?'
                                          : '등록 후에는 수정할 수 없습니다. 계속하시겠습니까?',
                                      yesText: '확인',
                                      noText: '취소',
                                      yesLogic: () async {
                                        // AskPopup 닫기
                                        if (dialogContext.mounted) {
                                          Navigator.pop(dialogContext);
                                        }

                                        if (!context.mounted) return;

                                        try {
                                          String carrier;
                                          String trackingNumber;

                                          if (_isDirectTrade) {
                                            // 직거래 모드: 택배사는 "직거래", 송장번호는 "0000"
                                            carrier = '직거래';
                                            trackingNumber = '0000';
                                          } else {
                                            // 일반 모드: 입력값 사용
                                            carrier = _carrierController.text
                                                .trim();
                                            // 송장 번호가 이미 있으면 기존 값 유지, 없으면 입력값 사용
                                            trackingNumber = _hasExistingData
                                                ? (widget.initialTrackingNumber ??
                                                      _trackingNumberController
                                                          .text
                                                          .trim())
                                                : _trackingNumberController.text
                                                      .trim();
                                          }

                                          await widget.onConfirm(
                                            carrier,
                                            trackingNumber,
                                          );

                                          // onConfirm 완료 후 팝업 닫기 (onConfirm 내부에서 이미 닫았을 수도 있으므로 mounted 체크)
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                          }
                                        } catch (e) {
                                          // 에러 발생 시에도 팝업은 닫기
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                          }
                                          rethrow;
                                        }
                                      },
                                    ),
                                  );
                                }
                              : null,
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
