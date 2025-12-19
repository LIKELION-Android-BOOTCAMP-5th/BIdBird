import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/fonts_style.dart';
import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
import 'package:flutter/material.dart';

/// 판매자가 구매자에게 결제 정보(은행 정보)를 입력하거나 직거래를 선택하는 팝업
class PaymentInfoInputPopup extends StatefulWidget {
  const PaymentInfoInputPopup({
    super.key,
    required this.onConfirm,
    this.initialBankName,
    this.initialAccountNumber,
    this.initialAccountHolder,
    this.isDirectTrade = false,
  });

  final Future<void> Function({
    required String bankName,
    required String accountNumber,
    required String accountHolder,
    required bool isDirectTrade,
  }) onConfirm;
  final String? initialBankName;
  final String? initialAccountNumber;
  final String? initialAccountHolder;
  final bool isDirectTrade;

  @override
  State<PaymentInfoInputPopup> createState() => _PaymentInfoInputPopupState();
}

class _PaymentInfoInputPopupState extends State<PaymentInfoInputPopup> {
  late final TextEditingController _bankNameController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _accountHolderController;
  bool _isEditing = false;
  bool _hasExistingData = false;
  bool _isFormValid = false;
  bool _isDirectTrade = false;
  bool _isUpdatingDirectTrade = false;

  @override
  void initState() {
    super.initState();
    _hasExistingData = widget.initialBankName != null && 
                       widget.initialBankName!.isNotEmpty &&
                       widget.initialAccountNumber != null && 
                       widget.initialAccountNumber!.isNotEmpty;
    
    _isDirectTrade = widget.isDirectTrade;
    
    _bankNameController = TextEditingController(
      text: widget.initialBankName ?? '',
    );
    _accountNumberController = TextEditingController(
      text: widget.initialAccountNumber ?? '',
    );
    _accountHolderController = TextEditingController(
      text: widget.initialAccountHolder ?? '',
    );
    
    _isEditing = !_hasExistingData;
    
    _checkFormValidity();
    
    _bankNameController.addListener(_checkFormValidity);
    _accountNumberController.addListener(_checkFormValidity);
    _accountHolderController.addListener(_checkFormValidity);
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
    
    final bankNameValid = _bankNameController.text.trim().isNotEmpty;
    final accountNumberValid = _accountNumberController.text.trim().isNotEmpty;
    final accountHolderValid = _accountHolderController.text.trim().isNotEmpty;
    
    final isValid = bankNameValid && accountNumberValid && accountHolderValid;
    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  @override
  void dispose() {
    _bankNameController.removeListener(_checkFormValidity);
    _accountNumberController.removeListener(_checkFormValidity);
    _accountHolderController.removeListener(_checkFormValidity);
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.8;

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
                  _hasExistingData ? '결제 정보' : '결제 정보 입력',
                  style: contentFontStyle.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '구매자에게 전달할 계좌 정보를 입력해주세요.',
                  style: contentFontStyle.copyWith(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),

                // 직거래 체크박스
                if (_isEditing && !_hasExistingData)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isDirectTrade ? blueColor.withOpacity(0.1) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isDirectTrade ? blueColor : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _isDirectTrade,
                          onChanged: (value) {
                            if (!mounted) return;
                            
                            final newValue = value ?? false;
                            
                            _bankNameController.removeListener(_checkFormValidity);
                            _accountNumberController.removeListener(_checkFormValidity);
                            _accountHolderController.removeListener(_checkFormValidity);
                            
                            _isUpdatingDirectTrade = true;
                            
                            if (newValue) {
                              _bankNameController.clear();
                              _accountNumberController.clear();
                              _accountHolderController.clear();
                            }
                            
                            setState(() {
                              _isDirectTrade = newValue;
                            });
                            
                            _bankNameController.addListener(_checkFormValidity);
                            _accountNumberController.addListener(_checkFormValidity);
                            _accountHolderController.addListener(_checkFormValidity);
                            
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                _isUpdatingDirectTrade = false;
                                _checkFormValidity();
                              }
                            });
                          },
                          activeColor: blueColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '직거래로 진행',
                                style: contentFontStyle.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '계좌 정보 없이 직접 만나서 거래합니다',
                                style: contentFontStyle.copyWith(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // 은행명 입력
                if (!_isDirectTrade) ...[
                  Text(
                    '은행명',
                    style: contentFontStyle.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bankNameController,
                    enabled: _isEditing && !_isDirectTrade,
                    decoration: InputDecoration(
                      hintText: '예: 국민은행, 신한은행',
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
                          color: (_isEditing && !_isDirectTrade) ? blueColor : Colors.grey.shade300,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: (_isEditing && !_isDirectTrade) ? blueColor : Colors.grey.shade300,
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
                      fillColor: (_isEditing && !_isDirectTrade) ? Colors.white : Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 계좌번호 입력
                  Text(
                    '계좌번호',
                    style: contentFontStyle.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _accountNumberController,
                    enabled: _isEditing && !_isDirectTrade,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '- 없이 숫자만 입력',
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
                          color: (_isEditing && !_isDirectTrade) ? blueColor : Colors.grey.shade300,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: (_isEditing && !_isDirectTrade) ? blueColor : Colors.grey.shade300,
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
                      fillColor: (_isEditing && !_isDirectTrade) ? Colors.white : Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 예금주 입력
                  Text(
                    '예금주',
                    style: contentFontStyle.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _accountHolderController,
                    enabled: _isEditing && !_isDirectTrade,
                    decoration: InputDecoration(
                      hintText: '예금주명을 입력하세요',
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
                          color: (_isEditing && !_isDirectTrade) ? blueColor : Colors.grey.shade300,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: (_isEditing && !_isDirectTrade) ? blueColor : Colors.grey.shade300,
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
                      fillColor: (_isEditing && !_isDirectTrade) ? Colors.white : Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // 버튼 영역
                if (_hasExistingData && !_isEditing)
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
                              setState(() {
                                _isEditing = false;
                                _bankNameController.text = widget.initialBankName ?? '';
                                _accountNumberController.text = widget.initialAccountNumber ?? '';
                                _accountHolderController.text = widget.initialAccountHolder ?? '';
                              });
                            } else {
                              Navigator.pop(context);
                            }
                          },
                          child: const Text(
                            '취소',
                            style: TextStyle(color: Colors.black),
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
                          onPressed: _isFormValid ? () async {
                            if (!context.mounted) return;
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (dialogContext) => AskPopup(
                                content: _isDirectTrade 
                                    ? '직거래로 진행하시겠습니까?\n구매자에게 직거래 안내가 전송됩니다.'
                                    : '계좌 정보를 구매자에게 전송하시겠습니까?',
                                yesText: '확인',
                                noText: '취소',
                                yesLogic: () async {
                                  if (dialogContext.mounted) {
                                    Navigator.pop(dialogContext);
                                  }
                                  
                                  if (!context.mounted) return;
                                  
                                  try {
                                    await widget.onConfirm(
                                      bankName: _isDirectTrade ? '직거래' : _bankNameController.text.trim(),
                                      accountNumber: _isDirectTrade ? '' : _accountNumberController.text.trim(),
                                      accountHolder: _isDirectTrade ? '' : _accountHolderController.text.trim(),
                                      isDirectTrade: _isDirectTrade,
                                    );
                                    
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                    }
                                    rethrow;
                                  }
                                },
                              ),
                            );
                          } : null,
                          child: Text(_isDirectTrade ? '직거래 선택' : '전송하기'),
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
