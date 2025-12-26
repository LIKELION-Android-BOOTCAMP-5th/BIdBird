import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:flutter/material.dart';

class RegistrationSummaryCard extends StatefulWidget {
  const RegistrationSummaryCard({
    super.key,
    required this.title,
    required this.startPriceText,
    required this.auctionDurationText,
    this.instantPriceText,
    this.thumbnailUrl,
    required this.statusText,
    required this.onTap,
  });

  final String title;
  final String startPriceText;
  final String auctionDurationText;
  final String? instantPriceText;
  final String? thumbnailUrl;
  final String statusText; // 예: 등록 대기 / 수정 필요 / 오류 있음
  final VoidCallback onTap;

  @override
  State<RegistrationSummaryCard> createState() => _RegistrationSummaryCardState();
}

class _RegistrationSummaryCardState extends State<RegistrationSummaryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacingSmall;
    final hoverBg = chatItemSectionBackground;

    final (badgeBg, badgeFg) = _statusColors(widget.statusText);

    return Material(
      color: _hovered ? hoverBg : chatItemCardBackground,
      elevation: 0,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: Container(
            decoration: BoxDecoration(
              color: _hovered ? hoverBg : chatItemCardBackground,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: shadowLow,
                  offset: Offset(0, 2),
                  blurRadius: 8,
                )
              ],
            ),
            padding: EdgeInsets.all(context.spacingSmall * 1.5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _Thumbnail(url: widget.thumbnailUrl),
                SizedBox(width: spacing),
                Expanded(
                  child: Stack(
                    children: [
                      _SummaryTexts(
                        title: widget.title,
                        startPriceText: widget.startPriceText,
                        auctionDurationText: widget.auctionDurationText,
                        instantPriceText: widget.instantPriceText,
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: context.spacingSmall, vertical: context.spacingSmall * 0.5),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            widget.statusText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: badgeFg,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (Color, Color) _statusColors(String status) {
    switch (status) {
      case '등록 대기':
        return (rolePurchaseSub, rolePurchasePrimary);
      case '수정 필요':
        return (yellowColor.withValues(alpha: 0.12), yellowColor);
      case '오류 있음':
        return (RedColor.withValues(alpha: 0.12), RedColor);
      default:
        return (rolePurchaseSub, rolePurchasePrimary);
    }
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final size = 72.0; // 64–72px 권장에서 상한 사용
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 1,
        child: SizedBox(
          width: size,
          height: size,
          child: url == null || url!.isEmpty
              ? Container(color: LightBorderColor)
              : Image.network(
                  url!,
                  fit: BoxFit.cover,
                ),
        ),
      ),
    );
  }
}

class _SummaryTexts extends StatelessWidget {
  const _SummaryTexts({
    required this.title,
    required this.startPriceText,
    required this.auctionDurationText,
    this.instantPriceText,
  });

  final String title;
  final String startPriceText;
  final String auctionDurationText;
  final String? instantPriceText;

  @override
  Widget build(BuildContext context) {
    final titleStyle = const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: TextPrimary,
    );
    final metaStyle = const TextStyle(
      fontSize: 13,
      color: TextSecondary,
    );

    final parts = <String>[
      '시작가 $startPriceText원',
      '경매기간 $auctionDurationText',
      if (instantPriceText != null && instantPriceText!.isNotEmpty)
        '즉시입찰가 ${instantPriceText!}원',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 96), // 배지 자리 확보
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: titleStyle,
          ),
        ),
        const SizedBox(height: 6),
        Text(parts.join(' · '), style: metaStyle),
      ],
    );
  }
}
