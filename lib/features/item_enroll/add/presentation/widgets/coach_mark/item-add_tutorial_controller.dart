import 'package:flutter/cupertino.dart';

import 'item_add_tutorial_utils.dart';

class ItemAddTutorialController {
  final Set<int> _shownSteps = {};

  void show({
    required BuildContext context,
    required int step,
    required GlobalKey cycleKey,
    required GlobalKey addPhotoKey,
    required GlobalKey addTitleKey,
    required GlobalKey startPriceKey,
    required GlobalKey bidScheduleKey,
    required GlobalKey categoryKey,
    required GlobalKey addContentKey,
    required GlobalKey addPDFKey,
  }) {
    if (_shownSteps.contains(step)) return;
    _shownSteps.add(step);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      switch (step) {
        case 0:
          itemAddTutorialStep0(
            context: context,
            cycleKey: cycleKey,
            addPhotoKey: addPhotoKey,
            addTitleKey: addTitleKey,
          );
          break;

        case 1:
          itemAddTutorialStep1(
            context: context,
            startPriceKey: startPriceKey,
            bidScheduleKey: bidScheduleKey,
            categoryKey: categoryKey,
          );
          break;

        case 2:
          itemAddTutorialStep2(
            context: context,
            addContentKey: addContentKey,
            addPDFKey: addPDFKey,
          );
          break;
      }
    });
  }
}
