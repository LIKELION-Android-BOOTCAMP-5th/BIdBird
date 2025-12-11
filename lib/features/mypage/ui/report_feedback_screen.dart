import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/features/mypage/model/report_feedback_model.dart';
import 'package:bidbird/features/mypage/viewmodel/report_feedback_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ReportFeedbackScreen extends StatelessWidget {
  const ReportFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = context.watch<ReportFeedbackViewModel>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('신고 내역'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _ReportItemList(vm: vm),
        ),
      ),
    );
  }
}

class _ReportItemList extends StatelessWidget {
  final ReportFeedbackViewModel vm;

  const _ReportItemList({required this.vm});

  @override
  Widget build(BuildContext context) {
    //이부분모든스크린에적용하기
    //로딩할떄나옴
    if (vm.isLoading) {
      return const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (vm.errorMessage != null) {
      //나중에팝업띄울거임
    }

    if (vm.reports.isEmpty) {
      return const Center(child: Text('등록된 신고 내역이 없습니다.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final report = vm.reports[index];
        return _Item(report: report);
      },
      separatorBuilder: (_, __) =>
          const SizedBox(height: 6), //마지막아이템에는넣지않는효과가있음//ListView.separated
      itemCount: vm.reports.length,
    );
  }
}

class _Item extends StatelessWidget {
  final ReportFeedbackModel report;

  const _Item({required this.report});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.go(
          '/mypage/service_center/report_feedback/${report.id}',
          extra: report,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: BorderColor,
          borderRadius: defaultBorder,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    report.reportTypeName,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                _ReportStatus(status: report.status),
              ],
            ),

            //어떤상품에대한것인지도추가하면좋을것
            const SizedBox(height: 10),
            Text(
              report.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              //style
            ),
            const SizedBox(height: 12),
            Text(
              _formatListDate(report.createdAt),
              //style
            ),
          ],
        ),
      ),
    );
  }

  //utc수정해야함
  String _formatListDate(DateTime date) {
    final month = date.month.toString();
    final day = date.day.toString();
    return '${date.year}. $month. $day.';
  }
}

class _ReportStatus extends StatelessWidget {
  final int status;

  const _ReportStatus({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: getReportStatusColor(status),
        borderRadius: defaultBorder,
      ),
      child: Text(getReportStatusString(status)),
    );
  }
}
