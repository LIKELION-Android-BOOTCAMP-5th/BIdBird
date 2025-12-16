import 'package:flutter/material.dart';
import 'dart:async';

/// 정보 박스 컴포넌트
/// 결제 기한 타이머를 포함한 정보 표시용 박스
class InfoBox extends StatefulWidget {
  /// 표시할 메시지 (결제 기한 타이머가 없을 때 사용)
  final String? message;
  
  /// 결제 기한 (auction_end_at + 24시간)
  final DateTime? paymentDeadline;
  
  /// 가운데 정렬 여부 (판매자용)
  final bool centerAlign;
  
  /// 아이콘 표시 여부
  final bool showIcon;

  const InfoBox({
    super.key,
    this.message,
    this.paymentDeadline,
    this.centerAlign = false,
    this.showIcon = true,
  });

  @override
  State<InfoBox> createState() => _InfoBoxState();
}

class _InfoBoxState extends State<InfoBox> {
  Timer? _timer;
  Duration? _remainingTime;

  @override
  void initState() {
    super.initState();
    if (widget.paymentDeadline != null) {
      _updateRemainingTime();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          _updateRemainingTime();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateRemainingTime() {
    if (widget.paymentDeadline == null) return;
    
    final now = DateTime.now();
    final deadline = widget.paymentDeadline!;
    final difference = deadline.difference(now);
    
    if (difference.isNegative) {
      setState(() {
        _remainingTime = Duration.zero;
      });
    } else {
      setState(() {
        _remainingTime = difference;
      });
    }
  }

  String _formatRemainingTime(Duration duration) {
    if (duration.isNegative || duration.inSeconds <= 0) {
      return '기한 만료';
    }

    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (days > 0) {
      return '${days}일 ${hours}시간 ${minutes}분';
    } else if (hours > 0) {
      return '${hours}시간 ${minutes}분 ${seconds}초';
    } else if (minutes > 0) {
      return '${minutes}분 ${seconds}초';
    } else {
      return '${seconds}초';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA), // Background: #F5F7FA
        border: Border.all(
          color: const Color(0xFFD2E3FC), // Border: 1dp solid #D2E3FC
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12), // Radius: 12dp
      ),
      child: widget.centerAlign
          ? _buildCenterAlignedContent()
          : _buildLeftAlignedContent(),
    );
  }

  Widget _buildCenterAlignedContent() {
    if (widget.paymentDeadline != null && _remainingTime != null) {
      final isExpired = _remainingTime!.isNegative || _remainingTime!.inSeconds <= 0;
      return Center(
        child: Text(
          isExpired
              ? '결제 기한이 만료되었습니다'
              : '결제 기한: ${_formatRemainingTime(_remainingTime!)}',
          style: TextStyle(
            fontSize: 13,
            color: isExpired ? const Color(0xFFE53935) : const Color(0xFF3C4043),
            fontWeight: FontWeight.normal,
            height: 1.4,
          ),
        ),
      );
    }
    
    if (widget.message != null) {
      return Center(
        child: Text(
          widget.message!,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF3C4043),
            fontWeight: FontWeight.normal,
            height: 1.4,
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildLeftAlignedContent() {
    return Row(
      children: [
        if (widget.showIcon) ...[
          const Icon(
            Icons.info_outline,
            size: 16, // Size: 16dp
            color: Color(0xFF1A73E8), // Icon color: #1A73E8
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (widget.paymentDeadline != null && _remainingTime != null) {
      final isExpired = _remainingTime!.isNegative || _remainingTime!.inSeconds <= 0;
      return Text(
        isExpired
            ? '결제 기한이 만료되었습니다'
            : '결제 기한: ${_formatRemainingTime(_remainingTime!)}',
        style: TextStyle(
          fontSize: 13,
          color: isExpired ? const Color(0xFFE53935) : const Color(0xFF3C4043),
          fontWeight: FontWeight.normal,
          height: 1.4,
        ),
      );
    }
    
    if (widget.message != null) {
      return Text(
        widget.message!,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF3C4043), // Text color: #3C4043
          fontWeight: FontWeight.normal, // Regular
          height: 1.4, // Line height: 1.4
        ),
      );
    }
    
    return const SizedBox.shrink();
  }
}
