import 'package:flutter/material.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';

/// 모던한 스타일의 입찰 버튼
/// 반응형 디자인과 부드러운 애니메이션을 제공
class ModernBidButton extends StatefulWidget {
  const ModernBidButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor = Colors.white,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.gradient,
  });

  /// 버튼 텍스트
  final String text;

  /// 버튼 클릭 콜백
  final VoidCallback? onPressed;

  /// 배경색 (gradient가 있으면 무시됨)
  final Color? backgroundColor;

  /// 텍스트 색상
  final Color textColor;

  /// 로딩 상태
  final bool isLoading;

  /// 활성화 상태
  final bool isEnabled;

  /// 좌측 아이콘
  final Widget? icon;

  /// 그라데이션 배경
  final Gradient? gradient;

  @override
  State<ModernBidButton> createState() => _ModernBidButtonState();
}

class _ModernBidButtonState extends State<ModernBidButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.isEnabled && !widget.isLoading) {
      setState(() => _isPressed = true);
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _handleTapEnd();
  }

  void _handleTapCancel() {
    _handleTapEnd();
  }

  void _handleTapEnd() {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  Color get _effectiveBackgroundColor {
    if (!widget.isEnabled || widget.isLoading) {
      return Colors.grey.shade300;
    }
    return widget.backgroundColor ?? blueColor;
  }

  Color get _effectiveTextColor {
    if (!widget.isEnabled || widget.isLoading) {
      return Colors.grey.shade600;
    }
    return widget.textColor;
  }

  @override
  Widget build(BuildContext context) {
    final buttonHeight = context.buttonHeight;
    final fontSize = context.buttonFontSize;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            height: buttonHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: widget.isEnabled && !widget.isLoading
                  ? widget.gradient
                  : null,
              color: widget.gradient == null ? _effectiveBackgroundColor : null,
              borderRadius: BorderRadius.circular(defaultRadius + 7), // 더 둥글게
              boxShadow: widget.isEnabled && !widget.isLoading
                  ? [
                      BoxShadow(
                        color: _effectiveBackgroundColor.withOpacity(0.3),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                      const BoxShadow(
                        color: Colors.black12,
                        offset: Offset(0, 1),
                        blurRadius: 3,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(defaultRadius + 7),
              child: InkWell(
                borderRadius: BorderRadius.circular(defaultRadius + 7),
                onTap: (widget.isEnabled && !widget.isLoading)
                    ? widget.onPressed
                    : null,
                onTapDown: _handleTapDown,
                onTapUp: _handleTapUp,
                onTapCancel: _handleTapCancel,
                splashColor: Colors.white.withOpacity(0.2),
                highlightColor: Colors.white.withOpacity(0.1),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: context.hPadding),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null && !widget.isLoading) ...[
                        widget.icon!,
                        SizedBox(width: context.spacingSmall),
                      ],
                      if (widget.isLoading)
                        SizedBox(
                          width: context.iconSizeSmall,
                          height: context.iconSizeSmall,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _effectiveTextColor,
                            ),
                          ),
                        )
                      else
                        Flexible(
                          child: Text(
                            widget.text,
                            style: TextStyle(
                              color: _effectiveTextColor,
                              fontSize: fontSize,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 기본 입찰 버튼 프리셋
class PrimaryBidButton extends StatelessWidget {
  const PrimaryBidButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return ModernBidButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isEnabled: isEnabled,
      gradient: isEnabled && !isLoading
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [blueColor.withOpacity(0.9), blueColor],
            )
          : null,
      icon: Icon(Icons.gavel, size: context.iconSizeSmall, color: Colors.white),
    );
  }
}

/// 아웃라인 스타일의 버튼
class OutlineButton extends StatelessWidget {
  const OutlineButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isEnabled = true,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final buttonHeight = context.buttonHeight;
    final fontSize = context.buttonFontSize;

    return Container(
      height: buttonHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: isEnabled ? blueColor : Colors.grey.shade300,
          width: context.borderWidth,
        ),
        borderRadius: BorderRadius.circular(defaultRadius + 7),
        color: Colors.white,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(defaultRadius + 7),
        child: InkWell(
          borderRadius: BorderRadius.circular(defaultRadius + 7),
          onTap: isEnabled ? onPressed : null,
          splashColor: blueColor.withOpacity(0.1),
          highlightColor: blueColor.withOpacity(0.05),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: context.hPadding),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  color: isEnabled ? blueColor : Colors.grey.shade600,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 상태 메시지를 위한 컨테이너
class ModernStatusContainer extends StatelessWidget {
  const ModernStatusContainer({
    super.key,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.borderColor,
  });

  final String text;
  final Color? backgroundColor;
  final Color? textColor;
  final Widget? icon;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final buttonHeight = context.buttonHeight;
    final fontSize = context.fontSizeMedium;

    return Container(
      height: buttonHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        borderRadius: BorderRadius.circular(defaultRadius + 7),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: context.borderWidth)
            : Border.all(color: BorderColor, width: context.borderWidth),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: context.hPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[icon!, SizedBox(width: context.spacingSmall)],
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  color: textColor ?? TopBidderTextColor,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.3,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
