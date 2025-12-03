import 'dart:io';
import 'dart:typed_data';

import 'package:bidbird/core/cloudinary_manager.dart';
import 'package:bidbird/core/supabase_manager.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bidbird/features/item_registration/data/item_registration_data.dart';
import 'package:bidbird/features/item_registration/viewmodel/item_registration_viewmodel.dart';
import 'package:bidbird/features/item_registration/ui/item_registration_detail_ui.dart';

import '../item_data/item_add_data.dart';

class ItemAddViewModel extends ChangeNotifier {
  ItemAddViewModel();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController startPriceController = TextEditingController();
  final TextEditingController instantPriceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  List<XFile> selectedImages = <XFile>[];
  final List<Map<String, dynamic>> keywordTypes = <Map<String, dynamic>>[];

  final List<String> durations = <String>['4시간', '12시간', '24시간'];

  String? editingItemId;
  int? selectedKeywordTypeId;
  String selectedDuration = '4시간';
  bool agreed = false;
  bool isLoadingKeywords = false;
  bool isSubmitting = false;
  bool useInstantPrice = false;

  void disposeControllers() {
    titleController.dispose();
    startPriceController.dispose();
    instantPriceController.dispose();
    descriptionController.dispose();
  }

  Future<void> init() async {
    await fetchKeywordTypes();
  }

  Future<void> fetchKeywordTypes() async {
    isLoadingKeywords = true;
    notifyListeners();

    try {
      final supabase = SupabaseManager.shared.supabase;
      final List<dynamic> data = await supabase
          .from('code_keyword_type')
          .select('id, title')
          .order('id');

      keywordTypes
        ..clear()
        ..addAll(data.cast<Map<String, dynamic>>());
    } on PostgrestException catch (e) {
      throw Exception('카테고리를 불러오는 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      throw Exception('카테고리를 불러오는 중 오류가 발생했습니다: $e');
    } finally {
      isLoadingKeywords = false;
      notifyListeners();
    }
  }

  Future<void> pickImagesFromGallery() async {
    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 80);
    if (images.isEmpty) {
      return;
    }

    final List<XFile> all = <XFile>[...selectedImages, ...images];
    if (all.length > 10) {
      selectedImages = all.take(10).toList();
    } else {
      selectedImages = all;
    }
    notifyListeners();
  }

  Future<void> pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (image == null) return;

    if (selectedImages.length >= 10) {
      return;
    }

    selectedImages = <XFile>[...selectedImages, image];
    notifyListeners();
  }

  String? validate() {
    final String title = titleController.text.trim();
    final String description = descriptionController.text.trim();

    if (title.isEmpty) {
      return '제목을 입력해주세요.';
    }

    if (title.length > 20) {
      return '제목은 20자 이하로 입력해주세요.';
    }

    if (selectedKeywordTypeId == null) {
      return '카테고리를 선택해주세요.';
    }

    final int? startPrice =
    int.tryParse(startPriceController.text.replaceAll(',', ''));
    final int? instantPrice =
    int.tryParse(instantPriceController.text.replaceAll(',', ''));

    if (startPrice == null) {
      return '시작가를 숫자로 입력해주세요.';
    }

    if (startPrice < 1000) {
      return '시작가는 1,000원 이상이어야 합니다.';
    }

    if (useInstantPrice) {
      if (instantPrice == null) {
        return '즉시 입찰가를 숫자로 입력해주세요.';
      }

      if (instantPrice <= startPrice) {
        return '즉시 입찰가는 시작가보다 높아야 합니다.';
      }
    }

    if (selectedImages.isEmpty) {
      return '상품 이미지를 최소 1장 이상 선택해주세요.';
    }

    if (description.isEmpty) {
      return '상품 설명을 입력해주세요.';
    }

    if (description.length > 1000) {
      return '상품 설명은 1000자 이하로 입력해주세요.';
    }

    return null;
  }

  void setSelectedKeywordTypeId(int? id) {
    selectedKeywordTypeId = id;
    notifyListeners();
  }

  void setSelectedDuration(String value) {
    selectedDuration = value;
    notifyListeners();
  }

  void setUseInstantPrice(bool value) {
    useInstantPrice = value;
    if (!value) {
      instantPriceController.clear();
    }
    notifyListeners();
  }

  String formatNumber(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final reverseIndex = digits.length - i;
      buffer.write(digits[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1 && i != digits.length - 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  Future<void> submit(BuildContext context) async {
    final String? error = validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    final String title = titleController.text.trim();
    final String description = descriptionController.text.trim();
    final int startPrice =
    int.parse(startPriceController.text.replaceAll(',', ''));
    final int instantPrice = useInstantPrice
        ? int.parse(instantPriceController.text.replaceAll(',', ''))
        : 0;

    isSubmitting = true;
    notifyListeners();

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final supabase = SupabaseManager.shared.supabase;
      final user = supabase.auth.currentUser;

      if (user == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('로그인 정보가 없습니다. 다시 로그인 해주세요.')),
        );
        return;
      }

      final DateTime now = DateTime.now();

      int auctionHours = 4;
      switch (selectedDuration) {
        case '12시간':
          auctionHours = 12;
          break;
        case '24시간':
          auctionHours = 24;
          break;
        default:
          auctionHours = 4;
      }

      final DateTime auctionStartAt = now;
      final DateTime auctionEndAt = now.add(Duration(hours: auctionHours));

      final List<String> imageUrls = await CloudinaryManager.shared
          .uploadImageListToCloudinary(selectedImages);

      if (imageUrls.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('이미지 업로드에 실패했습니다. 다시 시도해주세요.')),
        );
        return;
      }

      final ItemAddData data = ItemAddData(
        title: title,
        description: description,
        startPrice: startPrice,
        instantPrice: instantPrice,
        keywordTypeId: selectedKeywordTypeId!,
        auctionStartAt: auctionStartAt,
        auctionEndAt: auctionEndAt,
        auctionDurationHours: auctionHours,
        imageUrls: imageUrls,
        isAgree: agreed,
      );

      Map<String, dynamic> row;

      if (editingItemId == null) {
        final Map<String, dynamic> inserted = await supabase
            .from('items')
            .insert(data.toJson(sellerId: user.id))
            .select(
          'id, title, description, start_price, buy_now_price, keyword_type',
        )
            .single();
        row = inserted;
      } else {
        final Map<String, dynamic> updateJson =
            data.toJson(sellerId: user.id)
              ..remove('seller_id')
              ..remove('current_price')
              ..remove('bidding_count')
              ..remove('status')
              ..remove('locked');

        final Map<String, dynamic> updated = await supabase
            .from('items')
            .update(updateJson)
            .eq('id', editingItemId!)
            .select(
          'id, title, description, start_price, buy_now_price, keyword_type',
        )
            .single();
        row = updated;
      }

      final String itemId = row['id'].toString();

      if (editingItemId != null) {
        await supabase
            .from('item_images')
            .delete()
            .eq('item_id', itemId);
      }

      if (imageUrls.isNotEmpty) {
        final List<Map<String, dynamic>> imageRows = <Map<String, dynamic>>[];
        for (int i = 0; i < imageUrls.length && i < 10; i++) {
          imageRows.add(<String, dynamic>{
            'item_id': itemId,
            'image_url': imageUrls[i],
            'sort_order': i + 1,
          });
        }

        if (imageRows.isNotEmpty) {
          await supabase.from('item_images').insert(imageRows);
        }
      }

      // Edge Function을 호출하여 썸네일용 작은 이미지를 생성/저장
      try {
        if (imageUrls.isNotEmpty) {
          await supabase.functions.invoke(
            'create-thumbnail',
            body: <String, dynamic>{
              'itemId': itemId,
              'imageUrl': imageUrls.first,
            },
          );
        }
      } catch (e) {
        debugPrint('create-thumbnail error: $e');
      }

      final ItemRegistrationData registrationItem = ItemRegistrationData(
        id: itemId,
        title: row['title']?.toString() ?? title,
        description: row['description']?.toString() ?? description,
        startPrice: (row['start_price'] as num?)?.toInt() ?? startPrice,
        instantPrice:
        (row['buy_now_price'] as num?)?.toInt() ?? instantPrice,
        thumbnailUrl:
            imageUrls.isNotEmpty ? imageUrls.first : null,
        keywordTypeId: (row['keyword_type'] as num?)?.toInt(),
      );

      messenger.showSnackBar(
        const SnackBar(
          content: Text('매물이 저장되었습니다. 등록을 계속 진행해 주세요.'),
        ),
      );

      navigator.pushReplacement(
        PageRouteBuilder(
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) {
            final vm = ItemRegistrationViewModel();
            vm.items = <ItemRegistrationData>[registrationItem];
            return ChangeNotifierProvider<ItemRegistrationViewModel>.value(
              value: vm,
              child: ItemRegistrationDetailScreen(item: registrationItem),
            );
          },
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('등록 중 오류가 발생했습니다: $e')),
      );
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}


