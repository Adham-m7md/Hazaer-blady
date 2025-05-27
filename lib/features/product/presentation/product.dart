import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hadaer_blady/core/services/product_service.dart';
import 'package:hadaer_blady/core/services/rating_service.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_directions.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/core/widgets/custom_loading_indicator.dart';
import 'package:hadaer_blady/features/product/presentation/product_details_screen.dart';
import 'package:hadaer_blady/features/rateing/cubit/rating_cubit.dart';
import 'package:hadaer_blady/features/rateing/cubit/rating_state.dart';

class Product extends StatelessWidget {
  final Map<String, dynamic> product;
  final String productId;

  const Product({super.key, required this.product, required this.productId});

  @override
  Widget build(BuildContext context) {
    final farmerId = product['farmer_id'] ?? '';
    log('Rendering Product with productId: $productId, product: $product');
    return GestureDetector(
      onTap: () {
        if (productId.isNotEmpty) {
          log('Navigating to ProductDetails with productId: $productId');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ProductDetailsScreen(
                    productId: productId,
                    product: product,
                  ),
            ),
          );
        } else {
          log('Error: Attempted navigation with empty productId');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('معرف المنتج غير صالح')));
        }
      },
      child: Container(
        width: context.screenWidth,
        decoration: BoxDecoration(
          color: AppColors.kFillGrayColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.lightPrimaryColor.withAlpha(30)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                spacing: 6,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (product['name'] ?? 'منتج غير معروف').length > 10
                        ? '${(product['name'] ?? 'منتج غير معروف').substring(0, 10)}...'
                        : product['name'] ?? 'منتج غير معروف',
                    style: TextStyles.semiBold19,
                  ),
                  FutureBuilder<Map<String, dynamic>>(
                    future: ProductService().getFarmerData(
                      product['farmer_id'],
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CustomLoadingIndicator();
                      }
                      if (snapshot.hasError) {
                        log('Error fetching farmer data: ${snapshot.error}');
                        return const Text(
                          'خطأ في جلب بيانات الحظيرة',
                          style: TextStyles.semiBold11,
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Text(
                          'لا توجد بيانات للحظيرة',
                          style: TextStyles.semiBold16,
                        );
                      }
                      final farmerData = snapshot.data!;
                      return Text.rich(
                        TextSpan(
                          style: TextStyles.semiBold16,
                          children: [
                            const TextSpan(text: 'المدينة: '),
                            TextSpan(text: farmerData['city'] ?? 'غير محدد'),
                          ],
                        ),
                      );
                    },
                  ),
                  Text.rich(
                    TextSpan(
                      style: TextStyles.semiBold16,
                      children: [
                        const TextSpan(text: 'الوزن: '),
                        TextSpan(
                          text:
                              '${product['min_weight'] ?? 0}~${product['max_weight'] ?? 0} كيلو',
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize:
                        MainAxisSize
                            .min, // Adjusts the row size to fit its content
                    children: [
                      Text('السعر للكيلو: ', style: TextStyles.semiBold16),
                      Text(
                        _truncateText(
                          '${product['price_per_kg'] ?? 0} دينار',
                          4,
                        ),
                        style: TextStyles.semiBold16,
                      ),
                    ],
                  ),
                  // Fetch and display farmer's ratings
                  BlocProvider(
                    create:
                        (context) => RatingCubit(
                          ratingService: RatingService(),
                          auth: FirebaseAuth.instance,
                          userId: farmerId,
                        ),
                    child: RatingDisplay(),
                  ),
                ],
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 120,
                  height: 120,
                  color: AppColors.kFillGrayColor,
                  child: Image.network(
                    product['image_url'] ?? '',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      log('Image load error for URL: ${product['image_url']}');
                      return const Center(
                        child: Text(
                          'لا يوجد صورة لتحميلها ',
                          style: TextStyles.semiBold16,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }
                      return const Center(child: CustomLoadingIndicator());
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RatingDisplay extends StatelessWidget {
  const RatingDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RatingCubit, RatingState>(
      builder: (context, state) {
        if (state is RatingLoadingState) {
          return const CustomLoadingIndicator();
        }
        if (state is RatingErrorState) {
          log('Error fetching ratings: ${state.message}');
          return const Text(
            'خطأ في جلب التقييمات',
            style: TextStyles.semiBold16,
          );
        }
        if (state is RatingSuccessState) {
          final averageRating = state.averageRating;
          return Row(
            children: [
              const Text('التقييمات :', style: TextStyles.semiBold16),
              const SizedBox(width: 8),
              Row(
                children: [
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: TextStyles.semiBold16,
                  ),
                  const Icon(Icons.star, color: Color(0xffFFC529), size: 28),
                ],
              ),
            ],
          );
        }
        // حالة افتراضية (لا توجد تقييمات)
        return const Text('لا توجد تقييمات', style: TextStyles.semiBold16);
      },
    );
  }
}

String _truncateText(String text, int maxLength) {
  if (text.length <= maxLength) {
    return text;
  }
  return '${text.substring(0, maxLength)}...';
}
