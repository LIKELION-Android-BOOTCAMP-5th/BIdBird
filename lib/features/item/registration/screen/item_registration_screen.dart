import 'package:flutter/material.dart';
import 'package:bidbird/core/utils/ui_set/border_radius.dart';
import 'package:bidbird/core/utils/ui_set/colors.dart';
import 'package:provider/provider.dart';
import '../viewmodel/item_registration_viewmodel.dart';
import 'item_registration_detail_screen.dart';

class ItemRegistrationScreen extends StatelessWidget {
  const ItemRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ItemRegistrationViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('매물 등록 확인'),
        centerTitle: true,
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.items.isEmpty
              ? const Center(
                  child: Text('등록할 매물이 없습니다.'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemBuilder: (context, index) {
                    final item = vm.items[index];
                    return InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero,
                            pageBuilder:
                                (context, animation, secondaryAnimation) {
                              return ChangeNotifierProvider<
                                  ItemRegistrationViewModel>.value(
                                value: vm,
                                child:
                                    ItemRegistrationDetailScreen(item: item),
                              );
                            },
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: itemRegistrationCardBackgroundColor,
                          borderRadius: BorderRadius.circular(defaultRadius),
                          boxShadow: const [
                            BoxShadow(
                              color: itemRegistrationCardShadowColor,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: itemRegistrationThumbnailBackgroundColor,
                                borderRadius: BorderRadius.circular(defaultRadius),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: item.thumbnailUrl != null
                                  ? Image.network(
                                      item.thumbnailUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: Color(0xffD1D4DD),
                                          ),
                                        );
                                      },
                                    )
                                  : const DecoratedBox(
                                      decoration: BoxDecoration(
                                        color:
                                            itemRegistrationThumbnailPlaceholderColor,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '시작가 ${_formatPrice(item.startPrice)}원',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: itemRegistrationPriceTextColor,
                                    ),
                                  ),
                                  if (item.instantPrice > 0)
                                    Text(
                                      '즉시 ${_formatPrice(item.instantPrice)}원',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: itemRegistrationPriceTextColor,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: vm.items.length,
                ),
    );
  }
}

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
