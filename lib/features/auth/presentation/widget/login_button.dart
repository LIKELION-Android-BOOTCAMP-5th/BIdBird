import 'package:flutter/material.dart';

import '../../../../core/utils/ui_set/responsive_utils.dart';

class LoginButton extends StatelessWidget {
  const LoginButton({
    super.key,
    required this.buttonHeight,
    required this.buttonFontSize,
    required this.buttonLogic,
    required this.logoImage,
    required this.buttonText,
    required this.backgroundColor,
    required this.textColor,
  });

  final double buttonHeight;
  final double buttonFontSize;
  final Future<void> Function() buttonLogic;
  final String logoImage;
  final String buttonText;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: buttonHeight,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.7),
          ),
          elevation: 0,
        ),
        onPressed: () async {
          await buttonLogic();
        },
        child: Align(
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(logoImage),
              Text(
                buttonText,
                style: TextStyle(
                  fontSize: buttonFontSize,
                  color: textColor,
                  fontFamily: 'GoogleFont',
                ),
              ),
              SizedBox(
                width: context.widthRatio(0.025, min: 8.0, max: 14.0),
              ), // 특수 케이스: 버튼 내부 간격
            ],
          ),
        ),
      ),
    );
  }
}
