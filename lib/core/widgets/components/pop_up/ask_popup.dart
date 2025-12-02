import 'package:bidbird/core/utils/ui_set/colors.dart';
import 'package:flutter/material.dart';

import '../../../utils/ui_set/fonts.dart';

class AskPopup extends StatelessWidget {
  final String content;
  final String noText;
  final String yesText;
  final TextStyle inputContentTextStyle;
  final Future<void> Function() yesLogic;

  const AskPopup({
    //기본값
    super.key,
    this.content = '계속하시겠습니까?',
    this.noText = '취소',
    this.yesText = '확인',
    this.inputContentTextStyle = contentFontStyle,
    required this.yesLogic,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // 팝업 모서리
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 20,
      ), // 외부 여백
      child: Padding(
        padding: const EdgeInsets.all(10), // 내부 여백
        child: Container(
          height: 200,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min, // 높이 조절
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: const SizedBox(height: 20)), // 내용, 버튼 사이 간격
                // // 본문 텍스트
                Text(
                  content,
                  textAlign: TextAlign.center,
                  style: inputContentTextStyle,
                ),

                Expanded(child: const SizedBox(height: 20)), // 내용, 버튼 사이 간격

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 확인 버튼
                    Expanded(
                      child: FilledButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(blueColor),
                        ),
                        onPressed: () async {
                          await yesLogic();
                        }, // 다음으로 넘어가기?
                        child: Text(yesText),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 취소버튼
                    Expanded(
                      child: FilledButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(
                            Colors.grey.shade100,
                          ),
                        ),

                        onPressed: () {
                          Navigator.pop(context); // 팝업 닫기
                        },
                        child: Text(
                          noText,
                          style: TextStyle(color: Colors.black),
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
