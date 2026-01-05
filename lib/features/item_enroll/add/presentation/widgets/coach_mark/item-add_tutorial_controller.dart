import 'package:flutter/cupertino.dart';

import 'item_add_tutorial_utils.dart';

class ItemAddTutorialController {
  final Set<int> _shownSteps = {};
  bool _isDisabled = false;

  void disable() {
    _isDisabled = true;
  }

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
    required VoidCallback onSkipAll,
  }) {
    if (_isDisabled) return;

    if (_shownSteps.contains(step)) return;
    _shownSteps.add(step);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted || _isDisabled) return;

      switch (step) {
        case 0:
          itemAddTutorialStep0(
            cycleKey: cycleKey,
            context: context,
            addPhotoKey: addPhotoKey,
            addTitleKey: addTitleKey,
            onSkipALl: onSkipAll,
          );
          break;

        case 1:
          itemAddTutorialStep1(
            context: context,
            startPriceKey: startPriceKey,
            bidScheduleKey: bidScheduleKey,
            categoryKey: categoryKey,
            onSkipAll: onSkipAll,
          );
          break;

        case 2:
          itemAddTutorialStep2(
            context: context,
            addContentKey: addContentKey,
            addPDFKey: addPDFKey,
            onSkipALl: onSkipAll,
          );
          break;
      }
    });
  }
}
