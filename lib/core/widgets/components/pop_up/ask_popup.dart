import 'package:bidbird/core/utils/ui_set/colors.dart';
import 'package:flutter/material.dart';

import '../../../utils/ui_set/fonts.dart';

class AskPopup extends StatelessWidget {
  final String content;
  final String? noText;
  final String yesText;
  final TextStyle inputContentTextStyle;
  final Future<void> Function() yesLogic;

  const AskPopup({
    super.key,
    this.content = '계속하시겠습니까?',
    this.noText,
    this.yesText = '확인',
    this.inputContentTextStyle = contentFontStyle,
    required this.yesLogic,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: SizedBox(
          height: 150,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(child: SizedBox(height: 20)),

                // 내용 텍스트
                Text(
                  content,
                  textAlign: TextAlign.center,
                  style: inputContentTextStyle,
                ),

                const Expanded(child: SizedBox(height: 20)),

                // 버튼 영역
                if (noText == null)
                  // 확인 하나만
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(blueColor),
                          ),
                          onPressed: () async {
                            await yesLogic();
                          },
                          child: Text(yesText),
                        ),
                      ),
                    ],
                  )
                else
                  // 확인 + 취소
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: FilledButton(
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(blueColor),
                          ),
                          onPressed: () async {
                            await yesLogic();
                          },
                          child: Text(yesText),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                              Colors.grey.shade100,
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            noText!,
                            style: const TextStyle(color: Colors.black),
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
