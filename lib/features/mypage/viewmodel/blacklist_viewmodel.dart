import 'package:flutter/material.dart';

import '../data/blacklist_repository.dart';
import '../model/blacklist_user_model.dart';

class BlacklistViewModel extends ChangeNotifier {
  BlacklistViewModel({required this.repository});

  final BlacklistRepository repository;

  List<BlacklistedUser> users = [];
  bool isLoading = false;
  String? errorMessage;
  final Set<String> _processingIds = {};

  Future<void> loadBlacklist() async {
    if (isLoading) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      users = await repository.fetchBlacklist();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  //중복방지
  bool isProcessing(String targetUserId) =>
      _processingIds.contains(targetUserId);

  Future<void> toggleBlock(BlacklistedUser user) async {
    final targetId = user.targetUserId;
    if (_processingIds.contains(targetId)) return;

    _processingIds.add(targetId);
    notifyListeners();

    try {
      if (user.isBlocked) {
        await repository.unblockUser(targetId);
        _updateUser(
          user.copyWith(
            isBlocked: false,
            registerUserId: null,
            createdAt: null,
          ),
        );
      } else {
        final String? registerUserId = await repository.blockUser(targetId);
        _updateUser(
          user.copyWith(
            isBlocked: true,
            registerUserId: registerUserId ?? user.registerUserId,
            createdAt: user.createdAt ?? DateTime.now(),
          ),
        );
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      _processingIds.remove(targetId);
      notifyListeners();
    }
  }

  void _updateUser(BlacklistedUser updated) {
    final index = users.indexWhere(
      (element) => element.targetUserId == updated.targetUserId,
    );
    if (index >= 0) {
      users[index] = updated;
    } else {
      users.insert(0, updated); //최신목록
    }
  }
}
