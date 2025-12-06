import 'dart:io';

import 'package:bidbird/core/managers/cloudinary_manager.dart';
import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/ui_set/colors.dart';
import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repository/item_add_repository.dart';
import '../model/add_item_usecase.dart';
import '../model/item_add_entity.dart';

class ItemAddViewModel extends ChangeNotifier {
  ItemAddViewModel()
    : _addItemUseCase = AddItemUseCase(ItemAddRepositoryImpl());

  final AddItemUseCase _addItemUseCase;

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
  int primaryImageIndex = 0;

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

  void removeImageAt(int index) {
    if (index < 0 || index >= selectedImages.length) return;
    final List<XFile> list = List<XFile>.from(selectedImages);
    list.removeAt(index);
    selectedImages = list;

    if (selectedImages.isEmpty) {
      primaryImageIndex = 0;
    } else {
      if (primaryImageIndex == index) {
        primaryImageIndex = 0;
      } else if (index < primaryImageIndex) {
        primaryImageIndex = primaryImageIndex - 1;
      }
    }
    notifyListeners();
  }

  /// 대표 이미지는 selectedImages[0] 으로 간주합니다.
  void setPrimaryImage(int index) {
    if (index < 0 || index >= selectedImages.length) return;
    primaryImageIndex = index;
    notifyListeners();
  }

  /// 기존 매물을 수정하기 위해 items / item_images 데이터를 폼에 채웁니다.
  Future<void> startEdit(String itemId) async {
    editingItemId = itemId;

    final supabase = SupabaseManager.shared.supabase;
    try {
      final Map<String, dynamic> row = await supabase
          .from('items')
          .select(
            'title, description, start_price, buy_now_price, keyword_type, auction_duration_hours',
          )
          .eq('id', itemId)
          .single();

      titleController.text = (row['title'] ?? '').toString();
      descriptionController.text = (row['description'] ?? '').toString();

      final int? startPrice = (row['start_price'] as num?)?.toInt();
      if (startPrice != null) {
        startPriceController.text = formatNumber(startPrice.toString());
      }

      final int? buyNowPrice = (row['buy_now_price'] as num?)?.toInt();
      if (buyNowPrice != null && buyNowPrice > 0) {
        useInstantPrice = true;
        instantPriceController.text = formatNumber(buyNowPrice.toString());
      } else {
        useInstantPrice = false;
        instantPriceController.clear();
      }

      selectedKeywordTypeId = (row['keyword_type'] as num?)?.toInt();

      final int durationHours =
          (row['auction_duration_hours'] as num?)?.toInt() ?? 4;
      if (durationHours == 12) {
        selectedDuration = '12시간';
      } else if (durationHours == 24) {
        selectedDuration = '24시간';
      } else {
        selectedDuration = '4시간';
      }

      notifyListeners();

      await loadExistingImages(itemId);
    } catch (_) {
      // 실패해도 새로 작성할 수 있도록 조용히 무시
    }
  }

  /// 수정 모드에서 기존 이미지를 불러와 selectedImages에 채웁니다.
  Future<void> loadExistingImages(String itemId) async {
    try {
      final supabase = SupabaseManager.shared.supabase;
      final List<dynamic> data = await supabase
          .from('item_images')
          .select('image_url, sort_order')
          .eq('item_id', itemId)
          .order('sort_order');

      if (data.isEmpty) return;

      final dio = Dio();
      final List<XFile> files = <XFile>[];

      for (final dynamic row in data) {
        final map = row as Map<String, dynamic>;
        final String url = map['image_url'] as String;

        try {
          final response = await dio.get<List<int>>(
            url,
            options: Options(responseType: ResponseType.bytes),
          );

          final String fileName =
              '${DateTime.now().millisecondsSinceEpoch}_${files.length}.jpg';
          final String tempPath = '${Directory.systemTemp.path}/$fileName';
          final file = File(tempPath);
          await file.writeAsBytes(response.data ?? <int>[]);

          files.add(XFile(file.path));
        } catch (_) {}
      }

      if (files.isNotEmpty) {
        selectedImages = files;
        notifyListeners();
      }
    } catch (_) {}
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

    final int? startPrice = int.tryParse(
      startPriceController.text.replaceAll(',', ''),
    );
    final int? instantPrice = int.tryParse(
      instantPriceController.text.replaceAll(',', ''),
    );

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
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final String? error = validate();
    if (error != null) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text(error)));
      }
      return;
    }

    final String title = titleController.text.trim();
    final String description = descriptionController.text.trim();
    final int startPrice = int.parse(
      startPriceController.text.replaceAll(',', ''),
    );
    final int instantPrice = useInstantPrice
        ? int.parse(instantPriceController.text.replaceAll(',', ''))
        : 0;

    isSubmitting = true;
    notifyListeners();

    bool loadingDialogOpen = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(blueColor),
          ),
        );
      },
    );

    try {
      final supabase = SupabaseManager.shared.supabase;
      final user = supabase.auth.currentUser;

      if (user == null) {
        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('로그인 정보가 없습니다. 다시 로그인 해주세요.')),
          );
        }
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
        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('이미지 업로드에 실패했습니다. 다시 시도해주세요.')),
          );
        }
        return;
      }

      final ItemAddEntity data = ItemAddEntity(
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

      await _addItemUseCase(
        entity: data,
        imageUrls: imageUrls,
        primaryImageIndex: primaryImageIndex,
        editingItemId: editingItemId,
      );

      if (loadingDialogOpen && navigator.canPop()) {
        navigator.pop();
        loadingDialogOpen = false;
      }

      if (!context.mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AskPopup(
          content: '매물 등록 확인 화면으로 이동하여 최종 등록을 진행해 주세요.',
          yesText: '이동하기',
          yesLogic: () async {
            navigator.pop();
            if (!context.mounted) return;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              context.push('/add_item/item_registration_list');
            });
          },
        ),
      );
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('등록 중 오류가 발생했습니다: $e')),
        );
      }
    } finally {
      isSubmitting = false;
      notifyListeners();

      if (loadingDialogOpen && navigator.canPop()) {
        navigator.pop();
      }
    }
  }
}
