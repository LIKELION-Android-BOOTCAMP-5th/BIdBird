import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

/// 재사용 가능한 타겟 생성 함수
TargetFocus coreTutorialTarget({
  required GlobalKey key, // 강조할 위젯의 키 (필수)
  required String identify, // 타겟 구분용 ID (필수)
  required String title, // 굵은 제목 텍스트 (필수)
  required String description, // 설명 텍스트 (필수)
  ContentAlign contentAlign = ContentAlign.bottom, // 설명창 위치 (기본값: 아래)
  ShapeLightFocus shape = ShapeLightFocus.RRect, // 모양 (기본값: 둥근 사각형)
  CrossAxisAlignment textAlign = CrossAxisAlignment.start, // 텍스트 정렬
}) {
  return TargetFocus(
    identify: identify,
    keyTarget: key,
    shape: shape,
    radius: 10,
    focusAnimationDuration: const Duration(milliseconds: 500),
    unFocusAnimationDuration: const Duration(milliseconds: 400),
    contents: [
      TargetContent(
        align: contentAlign,
        builder: (context, controller) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: textAlign,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 20.0,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  description,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    ],
  );
}
