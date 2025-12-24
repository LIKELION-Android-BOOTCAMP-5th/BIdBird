import 'package:flutter/services.dart';
import 'package:bidbird/core/utils/item/item_price_utils.dart';

/// 가격 입력을 위한 TextInputFormatter
/// onChanged에서 controller.value를 직접 수정하는 대신
/// TextInputFormatter를 사용하여 성능을 최적화합니다.
class PriceInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 빈 문자열인 경우 그대로 반환
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // 숫자 포맷팅 적용
    final formatted = formatNumber(newValue.text);

    // 포맷팅된 텍스트가 동일하면 그대로 반환
    if (formatted == newValue.text) {
      return newValue;
    }

    // 포맷팅된 텍스트로 변경하고 커서를 끝으로 이동
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
