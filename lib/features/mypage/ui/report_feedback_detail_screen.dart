import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/fonts_style.dart';
import 'package:bidbird/core/utils/ui_set/icons_style.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bidbird/features/mypage/model/report_feedback_model.dart';

class ReportFeedbackDetailScreen extends StatelessWidget {
  final ReportFeedbackModel? report;
  final String feedbackId;

  const ReportFeedbackDetailScreen({
    super.key,
    required this.feedbackId,
    this.report,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = report;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('신고내역 상세'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: data == null
            ? _MissingReport(feedbackId: feedbackId)
            : _DetailBody(report: data),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final ReportFeedbackModel report;

  const _DetailBody({required this.report});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text('신고 사유: ${report.reportCodeName}'),
                    // const SizedBox(height: 8),
                    // Text('신고 사용자: ${report.targetUserId}'), //일단주석처리//공개user정보테이블이생기면그때nickname으로추가
                    // const SizedBox(height: 4),
                    Text(report.itemTitle ?? ''),
                    const SizedBox(height: 8),
                    Text(_formatFullDate(report.createdAt)),
                  ],
                ),
              ),
              _ReportCode(reportCode: report.reportCode),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _InfoSection(title: '내용', content: report.content),
          const SizedBox(height: 16),
          _InfoSection(
            title: '관리자 답변',
            content: report.feedback ?? '관리자 답변이 등록되지 않았습니다.',
          ),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    final month = date.month.toString();
    final day = date.day.toString();
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');
    final period = hour >= 12 ? '오후' : '오전';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '${date.year}. $month. $day. $period $hour12:$minute:$second';
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final String content;

  const _InfoSection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white, //앱칼라가없어서그냥이렇게씀,,
            borderRadius: defaultBorder,
          ),
          child: Text(content),
        ),
      ],
    );
  }
}

class _ReportCode extends StatelessWidget {
  final String reportCode;

  const _ReportCode({required this.reportCode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: getReportCodeColor(reportCode).withValues(alpha: 0.1),
        borderRadius: defaultBorder,
      ),
      child: Text(
        getReportCodeName(reportCode),
        style: TextStyle(color: getReportCodeColor(reportCode)),
      ),
    );
  }
}

class _MissingReport extends StatelessWidget {
  final String feedbackId;

  const _MissingReport({required this.feedbackId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(height: 12),
            Text(
              '신고 상세 정보를 찾을 수 없습니다.\n(feedbackId: $feedbackId)',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
