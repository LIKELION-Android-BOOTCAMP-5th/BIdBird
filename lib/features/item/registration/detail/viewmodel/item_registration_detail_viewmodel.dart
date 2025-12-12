import 'package:bidbird/core/utils/item/item_registration_error_messages.dart';
import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
import 'package:bidbird/features/item/registration/detail/data/repository/item_registration_detail_repository.dart';
import 'package:bidbird/features/item/registration/list/model/item_registration_entity.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ItemRegistrationDetailViewModel extends ChangeNotifier {
  ItemRegistrationDetailViewModel({
    required ItemRegistrationData item,
    ItemRegistrationDetailRepository? repository,
  })  : _item = item,
        _repository = repository ?? ItemRegistrationDetailRepository();

  final ItemRegistrationDetailRepository _repository;

  final ItemRegistrationData _item;
  ItemRegistrationData get item => _item;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _termsText;
  String? get termsText => _termsText;

  Future<void> loadTerms() async {
    try {
      _termsText = await _repository.fetchTermsText();
    } catch (_) {
    } finally {
      notifyListeners();
    }
  }

  String _formatScheduledAt(DateTime dt) {
    final String month = dt.month.toString().padLeft(2, '0');
    final String day = dt.day.toString().padLeft(2, '0');
    final String hour = dt.hour.toString().padLeft(2, '0');
    final String minute = dt.minute.toString().padLeft(2, '0');
    return '$month월 $day일 $hour시 $minute분';
  }

  Future<void> confirmRegistration(BuildContext context) async {
    if (_isSubmitting) return;
    _isSubmitting = true;
    notifyListeners();

    final messenger = ScaffoldMessenger.of(context);

    try {
      final DateTime scheduledAt = await _repository.confirmRegistration(_item.id);

      if (!context.mounted) return;

      final String formatted = _formatScheduledAt(scheduledAt);

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AskPopup(
            content: '$formatted 에 등록될 예정입니다.',
            yesText: '확인',
            yesLogic: () async {
              Navigator.of(dialogContext).pop();
              if (context.mounted) {
                context.go('/home');
              }
            },
          );
        },
      );
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(ItemRegistrationErrorMessages.registrationError(e))),
        );
      }
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> deleteItem(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          return AskPopup(
            content: '해당 매물을 삭제하시겠습니까?',
            yesText: '삭제하기',
            noText: '취소',
            yesLogic: () async {
              Navigator.of(dialogContext).pop();
              await _repository.deleteItem(_item.id);
              if (context.mounted) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('매물이 삭제되었습니다.')),
                );
                Navigator.of(context).pop(true);
              }
            },
          );
        },
      );
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(ItemRegistrationErrorMessages.deletionError(e))),
        );
      }
    }
  }
}
