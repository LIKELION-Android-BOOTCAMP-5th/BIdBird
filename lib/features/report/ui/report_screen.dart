import 'package:flutter/material.dart';

class ReportScreen extends StatefulWidget {

  final String itemTitle;
  final String targetNickname; // 피신고인
  final String sellerNickname; // 판매자

  const ReportScreen({
    super.key,
    this.itemTitle = '상품명',
    this.targetNickname = '홍길동',
    this.sellerNickname = '김판매',
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final TextEditingController _contentController = TextEditingController();
  String? _selectedReason;
  bool get _canSubmit =>
      _selectedReason != null && _contentController.text.trim().length >= 10;

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

  void _onSubmit() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('신고 완료'),
        content: const Text('신고가 접수되었습니다.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateString =
        '${now.year}년 ${now.month}월 ${now.day}일';

    return Scaffold(
      appBar: AppBar(
        title: const Text('신고하기'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 상단 정보 영역
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border:
                        Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoRow('신청 일자', dateString),
                          const SizedBox(height: 8),
                          _infoRow('상품명', widget.itemTitle),
                          const SizedBox(height: 8),
                          _infoRow('피신고인', widget.targetNickname),
                          const SizedBox(height: 8),
                          _infoRow('판매자', widget.sellerNickname),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 신고 사유 / 상세 내용
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border:
                        Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '상세 내용을 작성해주세요',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '신고 사유 선택',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            hint: const Text('신고 사유를 선택해주세요'),
                            value: _selectedReason,
                            items: _reasonOptions
                                .map(
                                  (e) => DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              ),
                            )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedReason = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '어떤 상황 또는 이유로 이 사용자를 신고하시나요?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 160,
                            child: TextField(
                              controller: _contentController,
                              maxLines: null,
                              expands: true,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: '최소 10자 이상 입력해주세요',
                                alignLabelWithHint: true,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${_contentController.text.length} / 1000',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '허위 신고 시 서비스 이용이 제한될 수 있습니다.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 하단 버튼
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _canSubmit ? _onSubmit : null,
                  child: const Text('신고하기'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
