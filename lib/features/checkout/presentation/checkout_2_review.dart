import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/constants.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_directions.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/core/widgets/custom_tittel.dart';

class Checkout2Review extends StatelessWidget {
  final Map<String, String>? userData;
  final List<Map<String, dynamic>> selectedItems;

  const Checkout2Review({
    super.key,
    this.userData,
    required this.selectedItems,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('Checkout2Review: selectedItems = $selectedItems');
    if (selectedItems.isEmpty) {
      debugPrint('Checkout2Review: selectedItems is empty');
    } else {
      debugPrint('Checkout2Review: Processing ${selectedItems.length} items');
      for (var item in selectedItems) {
        debugPrint('Checkout2Review: Item = $item');
        if (!item.containsKey('productData') ||
            !item.containsKey('totalPrice')) {
          debugPrint('Checkout2Review: Invalid item structure: $item');
        }
      }
    }

    final totalPrice = selectedItems.fold<double>(0, (sum, item) {
      final price = item['totalPrice'];
      if (price is num) {
        return sum + price.toDouble();
      }
      debugPrint('Checkout2Review: Invalid totalPrice for item: $item');
      return sum;
    });

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(khorizintalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomTittel(text: 'ملخص الطلب :'),
            SizedBox(height: context.screenHeight * 0.02),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppColors.kFillGrayColor,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (selectedItems.isEmpty)
                    const Text('السلة فارغة', style: TextStyles.semiBold16)
                  else
                    ...selectedItems.map((item) {
                      final productData =
                          item['productData'] as Map<String, dynamic>?;
                      if (productData == null) {
                        debugPrint(
                          'Checkout2Review: productData is null for item: $item',
                        );
                        return const SizedBox();
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            // صورة المنتج
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.0),
                                color: AppColors.klightGrayColor,
                              ),
                              child:
                                  productData['image_url'] != null
                                      ? ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                        child: Image.network(
                                          productData['image_url'],
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(
                                                    Icons.error,
                                                    color: Colors.red,
                                                  ),
                                        ),
                                      )
                                      : const Icon(
                                        Icons.image_not_supported,
                                        color: Colors.grey,
                                      ),
                            ),
                            const SizedBox(width: 12),
                            // تفاصيل المنتج
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productData['name'] ?? 'منتج غير معروف',
                                    style: TextStyles.semiBold16,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'الكمية: ${item['quantity']}',
                                    style: TextStyles.regular13.copyWith(
                                      color: AppColors.kGrayColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // السعر
                            Text(
                              '${item['totalPrice']} دينار',
                              style: TextStyles.bold16.copyWith(
                                color: AppColors.kprimaryColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  const Divider(thickness: 1, color: AppColors.klightGrayColor),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الإجمالي:', style: TextStyles.bold19),
                      Text(
                        '$totalPrice دينار',
                        style: TextStyles.bold19.copyWith(
                          color: AppColors.kprimaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: context.screenHeight * 0.02),
            const CustomTittel(text: 'يرجى التأكد من العنوان'),
            SizedBox(height: context.screenHeight * 0.02),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppColors.kFillGrayColor,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('عنوان التوصيل:', style: TextStyles.bold16),
                      IconButton(
                        onPressed: () {
                          final pageController =
                              context
                                  .findAncestorWidgetOfExactType<PageView>()
                                  ?.controller;
                          if (pageController != null) {
                            pageController.jumpToPage(0);
                          }
                        },
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.kGrayColor,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: AppColors.kGrayColor,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          userData != null
                              ? '${userData!['name']} - ${userData!['city']} - ${userData!['address']}'
                              : 'لم يتم إدخال عنوان',
                          style: TextStyles.semiBold16.copyWith(
                            color: AppColors.kGrayColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
