import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/report_viewmodel.dart';
import '../widgets/blocks/report_loading_block.dart';
import '../widgets/blocks/report_error_block.dart';
import '../widgets/sections/report_form_section.dart';

/// Report Screen - 순수 조립자
/// 
/// 책임:
/// - AppBar 표시
/// - 상태별 분기 (Loading/Error/Ready)
/// - 각 상태에 맞는 Widget 조립
/// 
/// 세부 UI 구현은 블록/섹션 위젯에 위임
class ReportScreen extends StatelessWidget {
  final String? itemId;
  final String? itemTitle;
  final String targetUserId;
  final String? targetNickname;

  const ReportScreen({
    super.key,
    this.itemId,
    this.itemTitle,
    required this.targetUserId,
    this.targetNickname,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReportViewModel()..loadReportTypes(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('신고하기'),
          centerTitle: true,
          backgroundColor: Colors.white,
        ),
        body: Consumer<ReportViewModel>(
          builder: (context, viewModel, _) {
            // 상태별 분기
            
            // Loading 상태
            if (viewModel.isLoading && viewModel.allReportTypes.isEmpty) {
              return ReportLoadingBlock(
                message: '신고 사유를 로드 중입니다...',
              );
            }

            // Error 상태
            if (viewModel.error != null && viewModel.allReportTypes.isEmpty) {
              return ReportErrorBlock(
                message: viewModel.error!,
                onRetry: () => viewModel.loadReportTypes(),
              );
            }

            // Ready 상태: Form 조립
            return ReportFormSection(
              viewModel: viewModel,
              itemId: itemId,
              itemTitle: itemTitle,
              targetUserId: targetUserId,
              targetNickname: targetNickname,
            );
          },
        ),
      ),
    );
  }
}
