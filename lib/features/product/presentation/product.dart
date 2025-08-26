import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:intl/intl.dart';

class Product extends StatelessWidget {
  final Map<String, dynamic> product;
  final String productId;

  const Product({super.key, required this.product, required this.productId});

  @override
  Widget build(BuildContext context) {
    String formatDate(dynamic rawDate) {
      if (rawDate == null) return "غير متوفر";

      try {
        DateTime dateTime;

        if (rawDate is Timestamp) {
          // لو جاي من Firestore كـ Timestamp
          dateTime = rawDate.toDate();
        } else if (rawDate is String) {
          // لو راجع String عادي
          dateTime = DateTime.parse(rawDate);
        } else {
          return "تاريخ غير صالح";
        }

        return DateFormat("d MMMM yyyy - hh:mm a", "ar").format(dateTime);
      } catch (e) {
        return "تاريخ غير صالح";
      }
    }

    final farmerId = product['farmer_id'] ?? '';
    log('Rendering Product with productId: $productId, product: $product');

    return GestureDetector(
      onTap: () {
        if (productId.isNotEmpty) {
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('معرف المنتج غير صالح')));
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              /// صورة المنتج
              Hero(
                tag: productId,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    product['image_url'] ?? '',
                    width: context.screenWidth * 0.3,
                    height: context.screenHeight * 0.14,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.kFillGrayColor,
                        width: context.screenWidth * 0.3,
                        height: context.screenHeight * 0.14,
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),

              /// تفاصيل المنتج
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [
                    Text(
                      (product['name'] ?? 'منتج غير معروف'),
                      style: TextStyles.semiBold19,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    /// المدينة
                    FutureBuilder<Map<String, dynamic>>(
                      future: ProductService().getFarmerData(farmerId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CustomLoadingIndicator();
                        }
                        if (snapshot.hasError) {
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
                        return Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 18,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              farmerData['city'] ?? 'غير محدد',
                              style: TextStyles.semiBold16,
                            ),
                          ],
                        );
                      },
                    ),

                    /// السعر
                    Row(
                      children: [
                        const Icon(
                          Icons.attach_money,
                          size: 18,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${product['price_per_kg'] ?? 0} دينار ",
                          style: TextStyles.semiBold16,
                        ),
                      ],
                    ),

                    /// التقييم
                    BlocProvider(
                      create:
                          (context) => RatingCubit(
                            ratingService: RatingService(),
                            auth: FirebaseAuth.instance,
                            userId: farmerId,
                          ),
                      child: const RatingDisplay(),
                    ),

                    /// وقت الإضافة (Created At)
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.blueGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formatDate(product['created_at']),
                          style: TextStyles.semiBold11.copyWith(
                            color: Colors.grey[700],
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
          return const Text(
            'خطأ في جلب التقييمات',
            style: TextStyles.semiBold16,
          );
        }
        if (state is RatingSuccessState) {
          final averageRating = state.averageRating;
          return Row(
            children: [
              const Icon(Icons.star, color: Color(0xffFFC529), size: 20),
              const SizedBox(width: 4),
              Text(
                averageRating.toStringAsFixed(1),
                style: TextStyles.semiBold16,
              ),
            ],
          );
        }
        return const Text('لا توجد تقييمات', style: TextStyles.semiBold16);
      },
    );
  }
}
