import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/ui_set/border_radius.dart';
import 'package:bidbird/core/utils/ui_set/colors.dart';
import 'package:bidbird/core/widgets/components/pop_up/confirm_check_cancel_popup.dart';
import 'package:bidbird/features/item/add/screen/item_add_screen.dart';
import 'package:bidbird/features/item/add/viewmodel/item_add_viewmodel.dart';
import 'package:bidbird/features/item/registration/model/item_registration_entity.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/item_registration_viewmodel.dart';

class ItemRegistrationDetailScreen extends StatefulWidget {
  const ItemRegistrationDetailScreen({super.key, required this.item});

  final ItemRegistrationData item;

  @override
  State<ItemRegistrationDetailScreen> createState() =>
      _ItemRegistrationDetailScreenState();
}

class _ItemRegistrationDetailScreenState
    extends State<ItemRegistrationDetailScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ItemRegistrationViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('매물 등록 확인'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              final editViewModel = ItemAddViewModel();
              editViewModel.editingItemId = widget.item.id;
              editViewModel.titleController.text = widget.item.title;
              editViewModel.startPriceController.text = editViewModel
                  .formatNumber(widget.item.startPrice.toString());

              if (widget.item.instantPrice > 0) {
                editViewModel.instantPriceController.text = editViewModel
                    .formatNumber(widget.item.instantPrice.toString());
                editViewModel.setUseInstantPrice(true);
              }

              editViewModel.descriptionController.text =
                  widget.item.description;

              // 카테고리(id)가 있다면 선택값으로 설정
              editViewModel.selectedKeywordTypeId = widget.item.keywordTypeId;

              // 카테고리 목록을 불러오도록 초기화
              editViewModel.init();

              // 기존 이미지 로딩
              editViewModel.loadExistingImages(widget.item.id);

              Navigator.of(context).push(
                PageRouteBuilder(
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return ChangeNotifierProvider<ItemAddViewModel>.value(
                      value: editViewModel,
                      child: const ItemAddScreen(),
                    );
                  },
                ),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.only(
                left: 8,
                right: 16,
                top: 4,
                bottom: 4,
              ),
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              '수정',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: blueColor,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ConfirmImageSection(
                    itemId: widget.item.id,
                    thumbnailUrl: widget.item.thumbnailUrl,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _ConfirmMainInfoSection(item: widget.item),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _ConfirmDescriptionSection(
                      description: widget.item.description,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: vm.isRegistering
                  ? null
                  : () async {
                      debugPrint('[ItemRegistrationDetail] onPressed 등록하기');
                      await showDialog(
                        context: context,
                        builder: (dialogContext) => ConfirmCheckCancelPopup(
                          title: '약관 동의',
                          description:
                              '1. 판매자는 시작가와 즉시 구매가(선택 입력)를 정확하게 입력해야 합니다. 허위 정보 입력은 금지됩니다.\n'
                              '2. 등록된 매물은 경매 시작 시점부터 경매 종료까지 임의 수정 또는 삭제가 제한될 수 있습니다.\n'
                              '3. 경매 종료 후 낙찰자가 존재할 경우, 판매자는 해당 낙찰자에게 매물을 반드시 인도해야 합니다. 임의 취소는 허용되지 않습니다.\n'
                              '4. 낙찰 금액 또는 즉시 구매 금액은 플랫폼 정책에 따라 결제·정산 절차가 진행됩니다. 판매자는 이에 동의한 것으로 간주됩니다.\n'
                              '5. 매물 설명, 사진, 상태 정보 등 모든 기재 내용은 사실에 기반해야 합니다. 허위 또는 과장 기재로 인해 발생하는 문제는 판매자 책임입니다.\n'
                              '6. 불법 물품, 타인의 권리를 침해하는 물품, 거래가 제한된 물품은 등록이 금지됩니다. 위반 시 매물 삭제 및 서비스 이용 제한이 적용될 수 있습니다.\n'
                              '7. 거래 과정에서 분쟁이 발생할 경우, 플랫폼의 분쟁 처리 기준 및 검증 절차가 우선 적용됩니다. 판매자는 관련 자료 제출 요청에 협조해야 합니다.\n'
                              '8. 매물 등록 시점부터 거래 종료까지 모든 기록은 운영 정책에 따라 보관·검토될 수 있습니다.\n'
                              '9. 약관에 위배되는 행위가 확인될 경우, 플랫폼은 매물 삭제, 거래 중단, 계정 제재 등의 조치를 시행할 수 있습니다.\n'
                              '10. 본 약관은 등록 시점 기준으로 적용되며, 운영 정책에 따라 변경될 수 있습니다.',
                          checkLabel: '동의합니다',
                          onConfirm: (checked) {
                            debugPrint(
                              '[ItemRegistrationDetail] onConfirm 호출, checked=$checked',
                            );
                            if (!checked) return;
                            Navigator.of(dialogContext).pop();
                            _handleRegistration(context, vm);
                          },
                          onCancel: () {
                            Navigator.of(dialogContext).pop();
                          },
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: blueColor,
                disabledBackgroundColor: itemRegistrationButtonDisabledColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(defaultRadius),
                ),
              ),
              child: const Text(
                '등록하기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRegistration(
    BuildContext context,
    ItemRegistrationViewModel vm,
  ) async {
    debugPrint('[ItemRegistrationDetail] _handleRegistration start');
    if (_isLoading) return;

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    setState(() {
      _isLoading = true;
    });

    try {
      final DateTime auctionStartAt = vm.getNextAuctionStartTime();
      final bool success = await vm.registerItem(
        context,
        widget.item.id,
        auctionStartAt,
      );

      debugPrint('[ItemRegistrationDetail] registerItem success=$success');

      if (success) {
        debugPrint('[ItemRegistrationDetail] pop detail & list screens');
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // 디테일 화면 pop
          navigator.pop();
          // 리스트 화면도 함께 닫아서 이전 화면으로 돌아가기
          if (navigator.canPop()) navigator.pop();
        });
      } else {
        debugPrint('[ItemRegistrationDetail] registerItem failed');
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('매물 등록에 실패했습니다. 다시 시도해 주세요.')),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('등록 중 오류가 발생했습니다.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class _ConfirmImageSection extends StatefulWidget {
  const _ConfirmImageSection({
    required this.itemId,
    required this.thumbnailUrl,
  });

  final String itemId;
  final String? thumbnailUrl;

  @override
  State<_ConfirmImageSection> createState() => _ConfirmImageSectionState();
}

class _ConfirmImageSectionState extends State<_ConfirmImageSection> {
  late final PageController _pageController;
  int _currentIndex = 0;
  late Future<List<String>> _imagesFuture;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _imagesFuture = _loadImages();
  }

  Future<List<String>> _loadImages() async {
    final supabase = SupabaseManager.shared.supabase;
    final List<dynamic> data = await supabase
        .from('item_images')
        .select('image_url, sort_order')
        .eq('item_id', widget.itemId)
        .order('sort_order');

    return data
        .map(
          (dynamic row) => (row as Map<String, dynamic>)['image_url'] as String,
        )
        .toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: SizedBox(
        height: 240,
        child: FutureBuilder<List<String>>(
          future: _imagesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }

            final images = snapshot.data ?? <String>[];

            if (images.isEmpty) {
              return Container(
                decoration: BoxDecoration(
                  color: itemRegistrationImageBackgroundColor,
                  borderRadius: BorderRadius.circular(defaultRadius),
                ),
                child: const Center(
                  child: Text('상품 사진', style: TextStyle(color: Colors.grey)),
                ),
              );
            }

            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(defaultRadius),
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: images.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Image.network(
                        images[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Text(
                              '이미지를 불러올 수 없습니다.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentIndex + 1}/${images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ConfirmMainInfoSection extends StatelessWidget {
  const _ConfirmMainInfoSection({required this.item});

  final ItemRegistrationData item;

  String _formatPrice(int price) {
    final buffer = StringBuffer();
    final text = price.toString();
    for (int i = 0; i < text.length; i++) {
      final reverseIndex = text.length - i;
      buffer.write(text[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1 && i != text.length - 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(defaultRadius),
          topRight: Radius.circular(defaultRadius),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            '시작가 ₩${_formatPrice(item.startPrice)}',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 2),
          Text(
            item.instantPrice > 0
                ? '즉시 입찰가 ₩${_formatPrice(item.instantPrice)}'
                : '즉시 입찰가: 없음',
            style: TextStyle(
              fontSize: 13,
              fontWeight: item.instantPrice > 0
                  ? FontWeight.w600
                  : FontWeight.w400,
              color: item.instantPrice > 0 ? blueColor : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmDescriptionSection extends StatelessWidget {
  const _ConfirmDescriptionSection({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '상품 설명',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }
}
