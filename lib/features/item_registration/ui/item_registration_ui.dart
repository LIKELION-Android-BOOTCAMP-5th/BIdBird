import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/item_registration_viewmodel.dart';
import 'item_registration_detail_ui.dart';

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
                  padding: const EdgeInsets.all(16),
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          item.thumbnailUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item.thumbnailUrl!,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const SizedBox(
                                        width: 40,
                                        height: 40,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : const SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: DecoratedBox(
                                    decoration:
                                        BoxDecoration(color: Colors.grey),
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
                                  '시작가 ${item.startPrice}원 · 즉시 ${item.instantPrice}원',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemCount: vm.items.length,
                ),
    );
  }
}


