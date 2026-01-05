import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../../../../../core/utils/coch_mark/tutorial.dart';

void itemAddTutorialStep0({
  required BuildContext context,
  required GlobalKey cycleKey,
  required GlobalKey addPhotoKey,
  required GlobalKey addTitleKey,
  required VoidCallback onSkipALl,
}) {
  TutorialCoachMark(
    targets: [
      coreTutorialTarget(
        identify: "add_cycle",
        key: cycleKey,
        title: "현재 상태",
        description: "상품 등록의 단계를 보여줍니다.",
        shape: ShapeLightFocus.RRect,
        contentAlign: ContentAlign.bottom,
      ),
      coreTutorialTarget(
        identify: "add_photo",
        key: addPhotoKey,
        title: "사진 추가",
        description: "상품의 사진을 최대 10장까지 등록할 수 있습니다.",
        shape: ShapeLightFocus.RRect,
        contentAlign: ContentAlign.bottom,
      ),
      coreTutorialTarget(
        identify: "title",
        key: addTitleKey,
        title: "상품 제목",
        description: "상품의 제목을 입력해주세요\n최대 20자까지 작성할 수 있습니다.",
        shape: ShapeLightFocus.RRect,
        contentAlign: ContentAlign.top,
      ),
    ],
    colorShadow: Colors.black,
    opacityShadow: 0.8,
    paddingFocus: 0,
    textSkip: "건너뛰기",
    alignSkip: Alignment.bottomLeft,
    onFinish: () => debugPrint("Step 0 튜토리얼 종료"),
    onSkip: () {
      debugPrint("Step 0 튜토리얼 스킵");
      onSkipALl();
      return true;
    },
  ).show(context: context);
}

void itemAddTutorialStep1({
  required BuildContext context,
  required GlobalKey startPriceKey,
  required GlobalKey bidScheduleKey,
  required GlobalKey categoryKey,
  required VoidCallback onSkipAll,
}) {
  TutorialCoachMark(
    targets: [
      coreTutorialTarget(
        identify: "start_price",
        key: startPriceKey,
        title: "시작 가격",
        description: "시작하는 가격을 설정할 수 있습니다\n최소 가격이니 신중하게 결정해주세요.",
        shape: ShapeLightFocus.RRect,
        contentAlign: ContentAlign.bottom,
      ),
      coreTutorialTarget(
        identify: "bid_schedule",
        key: bidScheduleKey,
        title: "경매 기간",
        description: "원하는 경매 기간을 설정해주세요.",
        shape: ShapeLightFocus.RRect,
        contentAlign: ContentAlign.bottom,
      ),
      coreTutorialTarget(
        identify: "category",
        key: categoryKey,
        title: "카테고리",
        description: "카테고리를 설정할 수 있습니다\n홈 화면에서 검색 시 카테고리별로 노출됩니다.",
        shape: ShapeLightFocus.RRect,
        contentAlign: ContentAlign.bottom,
      ),
    ],
    colorShadow: Colors.black,
    opacityShadow: 0.8,
    paddingFocus: 0,
    textSkip: "건너뛰기",
    alignSkip: Alignment.bottomLeft,
    onFinish: () => debugPrint("Step 1 튜토리얼 종료"),
    onSkip: () {
      debugPrint("Step 1 튜토리얼 스킵");
      onSkipAll();
      return true;
    },
  ).show(context: context);
}

void itemAddTutorialStep2({
  required BuildContext context,
  required GlobalKey addContentKey,
  required GlobalKey addPDFKey,
  required VoidCallback onSkipALl,
}) {
  TutorialCoachMark(
    targets: [
      coreTutorialTarget(
        identify: "content",
        key: addContentKey,
        title: "상품 설명",
        description:
            "상품을 자세하게 설명해주세요\n최대 1000자까지 입력할 수 있습니다\n자세할수록 판매 확률이 올라가요!",
        shape: ShapeLightFocus.RRect,
        contentAlign: ContentAlign.bottom,
      ),
      coreTutorialTarget(
        identify: "pdf",
        key: addPDFKey,
        title: "보증서 (선택)",
        description: "보증서 PDF 파일을 업로드할 수 있습니다\n정품을 인증하면 판매 확률이 올라가요!",
        shape: ShapeLightFocus.RRect,
        contentAlign: ContentAlign.bottom,
      ),
    ],
    colorShadow: Colors.black,
    opacityShadow: 0.8,
    paddingFocus: 0,
    textSkip: "건너뛰기",
    alignSkip: Alignment.bottomLeft,
    onFinish: () {
      debugPrint("Step 2 튜토리얼 종료");
      onSkipALl();
    },
    onSkip: () {
      debugPrint("Step 2 튜토리얼 스킵");
      onSkipALl();
      return true;
    },
  ).show(context: context);
}
