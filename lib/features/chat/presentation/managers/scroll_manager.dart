import 'dart:async';

import 'package:flutter/material.dart';

/// 스크롤 관리자
/// 채팅방의 스크롤 동작을 관리하는 클래스
class ScrollManager {
  final ScrollController scrollController;
  bool _hasScrolledToUnread = false;
  bool _isInitialLoad = true;
  bool _isUserScrolling = false;
  bool _isScrollPositionSet = false;
  bool _shouldScrollToBottom = false;
  bool _isScrollPositionReady = false;

  ScrollPhysics? listViewPhysics;

  bool get isScrollPositionReady => _isScrollPositionReady;
  bool get isInitialLoad => _isInitialLoad;
  bool get isUserScrolling => _isUserScrolling;
  bool get hasScrolledToUnread => _hasScrolledToUnread;

  ScrollManager(this.scrollController) {
    _setupScrollListeners();
  }

  /// 스크롤 리스너 설정
  void _setupScrollListeners() {
    // 초기 스크롤 위치 설정 리스너
    scrollController.addListener(() {
      if (_isInitialLoad &&
          !_isScrollPositionSet &&
          scrollController.hasClients) {
        final maxScroll = scrollController.position.maxScrollExtent;
        if (maxScroll > 0) {
          if (_shouldScrollToBottom) {
            _scrollToBottomInstant();
          } else {
            _scrollToTopInstant();
          }
          _isScrollPositionSet = true;
          _isInitialLoad = false;
        }
      }
    });

    // 사용자 스크롤 감지 리스너
    scrollController.addListener(() {
      if (!_isInitialLoad) {
        _isUserScrolling = true;
        // 스크롤이 멈춘 후 1초 뒤에 플래그 해제
        Future.delayed(const Duration(seconds: 1), () {
          _isUserScrolling = false;
        });
      }
    });
  }

  /// 스크롤 위치 초기화
  /// 
  /// [shouldScrollToBottom] 하단으로 스크롤할지 여부
  /// [messagesCount] 메시지 개수
  void initializeScrollPosition({
    required bool shouldScrollToBottom,
    required int messagesCount,
  }) {
    _shouldScrollToBottom = shouldScrollToBottom;
    _hasScrolledToUnread = false;
    _isScrollPositionSet = false;
    _isInitialLoad = true;
    _isScrollPositionReady = false;

    if (messagesCount > 0) {
      // ListView의 physics를 처음에 NeverScrollableScrollPhysics로 설정
      listViewPhysics = const NeverScrollableScrollPhysics();
      
      // 첫 번째 프레임에서 스크롤 위치 설정
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setScrollPositionAndShow();
      });

      // 여러 프레임에 걸쳐 시도
      for (int i = 0; i < 3; i++) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isScrollPositionReady) {
            _setScrollPositionAndShow();
          }
        });
      }

      // 약간의 지연 후에도 시도
      Future.delayed(const Duration(milliseconds: 10), () {
        if (!_isScrollPositionReady && _isInitialLoad) {
          _setScrollPositionAndShow();
        }
      });

      Future.delayed(const Duration(milliseconds: 50), () {
        if (!_isScrollPositionReady && _isInitialLoad) {
          _setScrollPositionAndShow();
        }
      });

      // 최대 200ms 후에는 강제로 화면 표시 (타임아웃)
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!_isScrollPositionReady && _isInitialLoad) {
          listViewPhysics = const ClampingScrollPhysics();
          _isScrollPositionSet = true;
          _isScrollPositionReady = true;
          _isInitialLoad = false;
        }
      });
    } else {
      _isScrollPositionReady = true;
    }
  }

  /// 스크롤 위치 설정 및 화면 표시
  void _setScrollPositionAndShow() {
    if (!_isInitialLoad || _isScrollPositionReady) {
      return;
    }

    if (!scrollController.hasClients) {
      return;
    }

    final maxScroll = scrollController.position.maxScrollExtent;

    // maxScrollExtent가 0이면 아직 레이아웃이 완료되지 않은 것
    if (maxScroll == 0) {
      return;
    }

    // 스크롤 위치 계산 및 즉시 적용 (애니메이션 없이)
    if (_shouldScrollToBottom) {
      scrollController.jumpTo(maxScroll);
    } else {
      scrollController.jumpTo(0);
    }

    // 스크롤 위치 설정 완료 후 즉시 physics를 ClampingScrollPhysics로 변경
    listViewPhysics = const ClampingScrollPhysics();
    _isScrollPositionSet = true;
    _isScrollPositionReady = true;
    _isInitialLoad = false;

    // 한 번 더 확인하여 확실하게 위치 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        final finalMaxScroll = scrollController.position.maxScrollExtent;
        final currentScroll = scrollController.position.pixels;

        if (_shouldScrollToBottom && currentScroll < finalMaxScroll - 1) {
          scrollController.jumpTo(finalMaxScroll);
        } else if (!_shouldScrollToBottom && currentScroll > 1) {
          scrollController.jumpTo(0);
        }
      }
    });
  }

  /// 하단으로 즉시 스크롤
  void _scrollToBottomInstant() {
    if (!scrollController.hasClients) return;
    final maxScroll = scrollController.position.maxScrollExtent;
    scrollController.jumpTo(maxScroll);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        final newMaxScroll = scrollController.position.maxScrollExtent;
        final newCurrentScroll = scrollController.position.pixels;
        if (newCurrentScroll < newMaxScroll - 1) {
          scrollController.jumpTo(newMaxScroll);
        }
      }
    });
  }

  /// 상단으로 즉시 스크롤
  void _scrollToTopInstant() {
    if (!scrollController.hasClients) return;
    scrollController.jumpTo(0);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        final newCurrentScroll = scrollController.position.pixels;
        if (newCurrentScroll > 1) {
          scrollController.jumpTo(0);
        }
      }
    });
  }

  /// 하단으로 스크롤
  /// 
  /// [force] 강제 스크롤 여부
  /// [instant] 즉시 스크롤 여부 (애니메이션 없음)
  void scrollToBottom({bool force = false, bool instant = false}) {
    if (!scrollController.hasClients) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        final maxScroll = scrollController.position.maxScrollExtent;
        final currentScroll = scrollController.position.pixels;

        // 이미 하단 근처(50px 이내)에 있고 force가 false면 스크롤하지 않음
        if (!force && (maxScroll - currentScroll) <= 50) {
          return;
        }
        if (instant) {
          scrollController.jumpTo(maxScroll);
        } else {
          scrollController.animateTo(
            maxScroll,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  /// 첫 번째 읽지 않은 메시지로 스크롤
  /// 
  /// [firstUnreadIndex] 첫 번째 읽지 않은 메시지 인덱스
  /// [instant] 즉시 스크롤 여부
  void scrollToFirstUnreadMessage(int firstUnreadIndex, {bool instant = false}) {
    if (_hasScrolledToUnread) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        // 메시지의 위치로 스크롤 (평균 메시지 높이로 추정)
        final position = firstUnreadIndex * 80.0;
        if (instant) {
          scrollController.jumpTo(position);
        } else {
          scrollController.animateTo(
            position,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
        _hasScrolledToUnread = true;
      }
    });
  }

  /// 읽지 않은 메시지로 스크롤 (인덱스가 없으면 하단으로)
  /// 
  /// [firstUnreadIndex] 첫 번째 읽지 않은 메시지 인덱스 (-1이면 하단으로)
  /// [instant] 즉시 스크롤 여부
  void scrollToUnreadOrBottom(int firstUnreadIndex, {bool instant = false}) {
    if (firstUnreadIndex >= 0) {
      scrollToFirstUnreadMessage(firstUnreadIndex, instant: instant);
    } else {
      scrollToBottom(force: true, instant: instant);
      _hasScrolledToUnread = true;
    }
  }

  /// 더 많은 메시지 로드 트리거 설정
  /// 
  /// [onLoadMore] 더 많은 메시지 로드 콜백
  /// [debounceMs] 디바운스 시간 (밀리초)
  void setupLoadMoreListener(
    void Function() onLoadMore, {
    int debounceMs = 150,
  }) {
    Timer? debounce;
    scrollController.addListener(() {
      if (debounce?.isActive ?? false) debounce!.cancel();

      // 리스트 상단 근처에 도달했을 때 이전 메시지 로딩 (디바운스 적용)
      debounce = Timer(Duration(milliseconds: debounceMs), () {
        if (scrollController.offset <= 40) {
          onLoadMore();
        }
      });
    });
  }

  /// 스크롤 위치 유지 (더 많은 메시지 로드 시)
  /// 
  /// [previousOffset] 이전 스크롤 오프셋
  /// [newMessagesCount] 새로 추가된 메시지 개수
  void maintainScrollPosition(double previousOffset, int newMessagesCount) {
    if (scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          // 새로 추가된 메시지의 예상 높이 계산 (평균 메시지 높이 * 추가된 메시지 수)
          final estimatedNewHeight = newMessagesCount * 80.0;
          final newOffset = previousOffset + estimatedNewHeight;
          scrollController.jumpTo(newOffset);
        }
      });
    }
  }

  /// 초기화 상태 리셋
  void resetInitialLoad() {
    _isInitialLoad = false;
    _isScrollPositionSet = false;
    _hasScrolledToUnread = false;
  }

  /// 리소스 정리
  void dispose() {
    scrollController.dispose();
  }
}

