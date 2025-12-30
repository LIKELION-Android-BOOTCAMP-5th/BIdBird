import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../../../core/utils/coch_mark/tutorial.dart';

void homeTutorial({
  required BuildContext context,
  required GlobalKey fabKey,
  required GlobalKey searchKey,
  required GlobalKey notificationKey,
  required GlobalKey currentPriceKey,
  required GlobalKey biddingCountKey,
  required GlobalKey finishTimeKey,
  // 나중에 다른 키가 필요하면 여기에 추가 (예: required GlobalKey searchKey)
}) {
  TutorialCoachMark(
    targets: _createHomeTargets(
      fabKey,
      searchKey,
      notificationKey,
      currentPriceKey,
      biddingCountKey,
      finishTimeKey,
    ), // 타겟 리스트 생성 함수 호출
    colorShadow: Colors.black,
    textSkip: "건너뛰기",
    alignSkip: Alignment.bottomLeft,
    paddingFocus: 0,
    opacityShadow: 0.8,
    onFinish: () => print("홈 튜토리얼 끝"),
    onSkip: () {
      print("건너뜀");
      return true;
    },
  ).show(context: context);
}

// 홈 화면용 타겟 리스트 구성
List<TargetFocus> _createHomeTargets(
  GlobalKey fabKey,
  GlobalKey searchKey,
  GlobalKey notificationKey,
  GlobalKey currentPriceKey,
  GlobalKey biddingCountKey,
  GlobalKey finishTimeKey,
) {
  return [
    // 플로팅 버튼
    coreTutorialTarget(
      identify: "floating_menu",
      key: fabKey,
      title: "판매를 시작해보세요!",
      description: "이 버튼을 눌러 내 물품을\n경매에 등록할 수 있습니다.",
      shape: ShapeLightFocus.Circle, // 플로팅 버튼이니까 원형
      contentAlign: ContentAlign.top, // 버튼 위에 설명 표시
    ),

    // 검색 버튼
    coreTutorialTarget(
      identify: "search_bar",
      key: searchKey, // 파라미터로 받아야 함
      title: "검색 기능",
      description: "원하는 물품을 검색해보세요.",
      shape: ShapeLightFocus.Circle,
      contentAlign: ContentAlign.bottom,
    ),

    //알림 버튼
    coreTutorialTarget(
      identify: "notification_bar",
      key: notificationKey, // 파라미터로 받아야 함
      title: "알림 기능",
      description: "중요한 알림을 확인해보세요.",
      shape: ShapeLightFocus.Circle,
      contentAlign: ContentAlign.bottom,
    ),

    //현재 가격
    coreTutorialTarget(
      identify: "current_price",
      key: currentPriceKey, // 파라미터로 받아야 함
      title: "현재 가격",
      description: "현재 가격이에요.",
      shape: ShapeLightFocus.RRect,
      contentAlign: ContentAlign.bottom,
    ),

    //입찰 수
    coreTutorialTarget(
      identify: "bidding_count",
      key: biddingCountKey, // 파라미터로 받아야 함
      title: "입찰 수",
      description: "현재 입찰 한 사람들이에요.",
      shape: ShapeLightFocus.Circle,
      contentAlign: ContentAlign.bottom,
    ),

    //남은 시간
    coreTutorialTarget(
      identify: "finish_time",
      key: finishTimeKey, // 파라미터로 받아야 함
      title: "종료 시간",
      description: "경매 종료까지 남은 시간이에요\n판매가 종료되기 전에 서두르세요!",
      shape: ShapeLightFocus.RRect,
      contentAlign: ContentAlign.bottom,
    ),
  ];
}
