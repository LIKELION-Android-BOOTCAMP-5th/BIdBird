import 'package:flutter/material.dart';

import '../domain/entities/blacklisted_user_entity.dart';
import '../domain/usecases/block_user.dart';
import '../domain/usecases/get_blacklist.dart';
import '../domain/usecases/unblock_user.dart';

class BlacklistViewModel extends ChangeNotifier {
  BlacklistViewModel({
    required GetBlacklist getBlacklist,
    required BlockUser blockUser,
    required UnblockUser unblockUser,
  })  : _getBlacklist = getBlacklist,
        _blockUser = blockUser,
        _unblockUser = unblockUser;

  final GetBlacklist _getBlacklist;
  final BlockUser _blockUser;
  final UnblockUser _unblockUser;

  List<BlacklistedUserEntity> users = [];
  bool isLoading = false;
  String? errorMessage;
  final Set<String> _processingIds = {};

  Future<void> loadBlacklist() async {
    if (isLoading) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      users = await _getBlacklist();
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

  Future<void> toggleBlock(BlacklistedUserEntity user) async {
    final targetId = user.targetUserId;
    if (_processingIds.contains(targetId)) return;

    _processingIds.add(targetId);
    notifyListeners();

    try {
      if (user.isBlocked) {
        await _unblockUser(targetId);
        _updateUser(
          user.copyWith(
            isBlocked: false,
            registerUserId: null,
            createdAt: null,
          ),
        );
      } else {
        final String? registerUserId = await _blockUser(targetId);
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

  void _updateUser(BlacklistedUserEntity updated) {
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
