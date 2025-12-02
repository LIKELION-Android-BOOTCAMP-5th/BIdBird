import 'dart:io';
import 'dart:typed_data';

import 'package:bidbird/core/supabase_manager.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  int? selectedKeywordTypeId;
  String selectedDuration = '4시간';
  bool agreed = false;
  bool isLoadingKeywords = false;
  bool isSubmitting = false;

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
          .from('keyword_type')
          .select('id, title')
          .order('id');

      keywordTypes
        ..clear()
        ..addAll(data.cast<Map<String, dynamic>>());
    } catch (e) {
      // 에러는 화면에서 처리할 수 있도록 throw
      throw Exception('키워드를 불러오는 중 오류가 발생했습니다: $e');
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

    if (instantPrice == null) {
      return '즉시 입찰가를 숫자로 입력해주세요.';
    }

    if (instantPrice <= startPrice) {
      return '즉시 입찰가는 시작가보다 높아야 합니다.';
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
    final int instantPrice =
        int.parse(instantPriceController.text.replaceAll(',', ''));

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

      final StorageFileApi storage = supabase.storage.from('item-images');
      final List<String> imageUrls = <String>[];

      for (int i = 0; i < selectedImages.length; i++) {
        final XFile xfile = selectedImages[i];
        final File file = File(xfile.path);
        final Uint8List bytes = await file.readAsBytes();
        final String path =
            '${user.id}/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';

        await storage.uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

        final String publicUrl = storage.getPublicUrl(path);
        imageUrls.add(publicUrl);
      }

      final ItemAddData data = ItemAddData(
        title: title,
        description: description,
        startPrice: startPrice,
        instantPrice: instantPrice,
        keywordTypeId: selectedKeywordTypeId!,
        auctionStartAt: auctionStartAt,
        auctionEndAt: auctionEndAt,
        imageUrls: imageUrls,
        isAgree: agreed,
      );

      await supabase.from('items').insert(data.toJson(sellerId: user.id));

      messenger.showSnackBar(
        const SnackBar(
          content: Text('매물이 저장되었습니다. 등록을 계속 진행해 주세요.'),
        ),
      );

      navigator.pop();
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

