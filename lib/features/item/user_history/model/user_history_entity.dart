import 'package:flutter/material.dart';

class UserTradeSummary {
  UserTradeSummary({
    required this.title,
    required this.price,
    required this.date,
    required this.statusLabel,
    required this.statusColor,
    this.thumbnailUrl,
  });

  final String title;
  final String price;
  final String date;
  final String statusLabel;
  final Color statusColor;
  final String? thumbnailUrl;
}
