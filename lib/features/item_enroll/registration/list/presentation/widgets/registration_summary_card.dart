import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
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
    final hoverBg = const Color(0xFFF0F2F5);

    final (badgeBg, badgeFg) = _statusColors(widget.statusText);

    return Material(
      color: _hovered ? hoverBg : Colors.white,
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
              color: _hovered ? hoverBg : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000), // Opacity 8%
                  offset: Offset(0, 2),
                  blurRadius: 8,
                )
              ],
            ),
            padding: const EdgeInsets.all(12),
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        return (const Color(0xFFE9EEF5), const Color(0xFF4A6CF7));
      case '수정 필요':
        return (const Color(0xFFFFF4E5), const Color(0xFFD97A00));
      case '오류 있음':
        return (const Color(0xFFFFECEC), const Color(0xFFD14343));
      default:
        return (const Color(0xFFE9EEF5), const Color(0xFF4A6CF7));
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
              ? Container(color: const Color(0xFFE5E7EB))
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
      color: Color(0xFF111111),
    );
    final metaStyle = const TextStyle(
      fontSize: 13,
      color: Color(0xFF666666),
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
