import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
import 'package:bidbird/features/item/item_registration_detail/data/repository/item_registration_detail_repository.dart';
import 'package:bidbird/features/item/item_registration_list/model/item_registration_entity.dart';
import 'package:bidbird/features/feed/ui/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ItemRegistrationDetailViewModel extends ChangeNotifier {
  ItemRegistrationDetailViewModel({
    required ItemRegistrationData item,
    ItemRegistrationDetailRepository? repository,
  })  : _item = item,
        _repository = repository ?? ItemRegistrationDetailRepository();

  final ItemRegistrationDetailRepository _repository;

  ItemRegistrationData _item;
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
    return '${month}월 ${day}일 ${hour}시 ${minute}분';
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
          SnackBar(content: Text('등록 중 오류가 발생했습니다: $e')),
        );
      }
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
