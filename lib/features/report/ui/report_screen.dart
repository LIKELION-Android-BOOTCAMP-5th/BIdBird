import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportScreen extends StatefulWidget {
  final String itemId;
  final String targetUserId;
  final String targetUserNickname;

  const ReportScreen({
    super.key,
    required this.itemId,
    required this.targetUserId,
    required this.targetUserNickname,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final TextEditingController _contentController = TextEditingController();
  final SupabaseClient _client = Supabase.instance.client;

  String? _selectedReason;
  bool isLoading = false;

  final List<String> _reasonOptions = [
    '사기 / 안전거래 위반',
    '욕설 / 비매너',
    '광고 / 스팸',
    '부적절한 내용',
    '기타',
  ];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  /// 신고 사유 → code_report_type.id 매핑
  int _mapReasonToTypeId(String reason) {
    switch (reason) {
      case "사기 / 안전거래 위반":
        return 1;
      case "욕설 / 비매너":
        return 2;
      case "광고 / 스팸":
        return 3;
      case "부적절한 내용":
        return 4;
      default:
        return 99;
    }
  }

  Future<void> _onSubmit() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    setState(() => isLoading = true);

    try {
      final result = await _client.from("reports").insert({
        "item_id": widget.itemId,
        "target_user_id": widget.targetUserId,
        "target_user_nickname": widget.targetUserNickname,
        "user_id": user.id,
        "report_type_id": _mapReasonToTypeId(_selectedReason!),
        "report_content": _contentController.text.trim(),
      }).select("*");

      print(" 신고 성공: $result");

      setState(() => isLoading = false);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("신고 완료"),
          content: const Text("신고가 성공적으로 접수되었습니다."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("확인"),
            ),
          ],
        ),
      );
    } catch (e) {
      print(" 신고 오류: $e");

      setState(() => isLoading = false);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("오류 발생"),
          content: const Text("신고 처리 중 오류가 발생했습니다."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("확인"),
            ),
          ],
        ),
      );
    }
  }

  bool get _canSubmit =>
      _selectedReason != null && _contentController.text.trim().length >= 10;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text("신고하기")),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _infoBox(now),
                  const SizedBox(height: 20),
                  _formBox(),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: isLoading || !_canSubmit ? null : _onSubmit,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("신고하기"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(DateTime now) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _boxDeco(),
    child: Column(
      children: [
        _infoRow("신청일", "${now.year}.${now.month}.${now.day}"),
        _infoRow("상품ID", widget.itemId),
        _infoRow("피신고자", widget.targetUserNickname),
      ],
    ),
  );

  Widget _formBox() => Container(
    padding: const EdgeInsets.all(16),
    decoration: _boxDeco(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("신고 사유", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(border: OutlineInputBorder()),
          hint: const Text("신고 사유를 선택해주세요"),
          value: _selectedReason,
          items: _reasonOptions
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (value) => setState(() => _selectedReason = value),
        ),
        const SizedBox(height: 12),
        const Text("상세 내용 (10자 이상)"),
        const SizedBox(height: 6),
        TextField(
          controller: _contentController,
          maxLines: 8,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: "최소 10자 이상 입력해주세요",
          ),
          onChanged: (_) => setState(() {}),
        )
      ],
    ),
  );

  Widget _infoRow(String key, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(width: 80, child: Text(key)),
        Expanded(child: Text(value)),
      ],
    ),
  );

  BoxDecoration _boxDeco() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.grey.shade300),
  );
}
