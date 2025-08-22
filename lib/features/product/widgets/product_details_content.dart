import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hadaer_blady/core/services/firebase_auth_service.dart';
import 'package:hadaer_blady/core/services/get_it.dart';
import 'package:hadaer_blady/core/services/rating_service.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_directions.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/features/cart/cubit/cart_cubit.dart';
import 'package:hadaer_blady/features/product/widgets/add_to_cart_button.dart';
import 'package:hadaer_blady/features/product/widgets/farmer_info.dart';
import 'package:hadaer_blady/features/product/widgets/location_info.dart';
import 'package:hadaer_blady/features/product/widgets/product_image.dart';
import 'package:hadaer_blady/features/product/widgets/rating_info.dart';
import 'package:hadaer_blady/features/product/widgets/total_price_info.dart';
import 'package:hadaer_blady/features/rateing/cubit/rating_cubit.dart';
import 'package:hadaer_blady/features/rateing/cubit/rating_state.dart';
import 'package:intl/intl.dart';

class ProductDetailsContent extends StatefulWidget {
  final Map<String, dynamic> productData;
  final Map<String, dynamic>? farmerData;
  final int quantity;

  const ProductDetailsContent({
    super.key,
    required this.productData,
    required this.farmerData,
    required this.quantity,
  });

  @override
  State<ProductDetailsContent> createState() => _ProductDetailsContentState();
}

class _ProductDetailsContentState extends State<ProductDetailsContent> {
  final FirebaseAuthService _firebaseAuthService = getIt<FirebaseAuthService>();
  late String _currentUserId = '';
  late String _farmerId = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _farmerId = widget.productData['farmer_id'] ?? '';
  }

  void _loadCurrentUserId() {
    final userId = _firebaseAuthService.getCurrentUser()?.uid ?? '';
    setState(() {
      _currentUserId = userId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pricePerKg =
        (widget.productData['price_per_kg'] as num?)?.toDouble() ?? 0.0;
    final isOwnProduct =
        _currentUserId == (widget.productData['farmer_id'] ?? '');
    final farmerId = widget.productData['farmer_id'] ?? '';

    return SingleChildScrollView(
      child: Column(
        children: [
          ProductImage(
            imageUrl: widget.productData['image_url'] ?? '',
            context: context,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FarmerInfo(
                      farmerData: widget.farmerData,
                      farmerId: farmerId,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LocationInfo(farmerData: widget.farmerData),
                BlocProvider(
                  create:
                      (context) => RatingCubit(
                        ratingService: RatingService(),
                        auth: getIt<FirebaseAuthService>().auth,
                        userId: _farmerId,
                      ),
                  child: RatingWithBlocBuilder(farmerId: _farmerId),
                ),
                const SizedBox(height: 16),

                // عرض اسم المنتج مع التاريخ في تصميم جميل
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.kWiteColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.kprimaryColor.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    spacing: 8,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        widget.productData['name'] ?? 'منتج غير معروف',
                        style: TextStyles.bold19.copyWith(
                          color: AppColors.kBlackColor,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      Text(
                        widget.productData['description'] ?? 'لا يوجد وصف',
                        style: TextStyles.medium15.copyWith(
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: AppColors.kprimaryColor.withOpacity(0.7),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'تم الرفع: ',
                            style: TextStyles.semiBold13.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SimpleProductDateWidget(
                            createdAt: widget.productData['created_at'],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                const SizedBox(height: 16),
                TotalPriceInfo(totalPrice: pricePerKg.toStringAsFixed(2)),
                SizedBox(height: context.screenHeight * 0.07),
                if (!isOwnProduct)
                  BlocProvider(
                    create: (context) => CartCubit(),
                    child: AddToCartButton(
                      productData: widget.productData,
                      // totalPrice: double.parse(pricePerKg.toStringAsFixed(2)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RatingWithBlocBuilder extends StatelessWidget {
  const RatingWithBlocBuilder({super.key, required this.farmerId});

  final String farmerId;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = BlocProvider.of<RatingCubit>(context);
      cubit.refreshRatings();
    });

    return BlocBuilder<RatingCubit, RatingState>(
      builder: (context, state) {
        if (state is RatingLoadingState) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: CircularProgressIndicator(),
            ),
          );
        } else if (state is RatingErrorState) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                const Icon(Icons.star_outline, color: Colors.grey),
                const SizedBox(width: 4),
                const Text('0.0', style: TextStyles.semiBold16),
                const SizedBox(width: 8),
                Text(
                  '(0 تقييم)',
                  style: TextStyles.medium15.copyWith(color: Colors.grey),
                ),
              ],
            ),
          );
        } else if (state is RatingSuccessState) {
          return RatingInfo(
            rating: state.averageRating.toStringAsFixed(1),
            reviews: state.totalReviews,
            userId: farmerId,
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              const Icon(Icons.star_outline, color: Colors.grey),
              const SizedBox(width: 4),
              const Text('0.0', style: TextStyles.semiBold16),
              const SizedBox(width: 8),
              Text(
                '(0 تقييم)',
                style: TextStyles.medium15.copyWith(color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SimpleProductDateWidget extends StatelessWidget {
  final dynamic createdAt;

  const SimpleProductDateWidget({super.key, required this.createdAt});

  String _formatDate(dynamic timestamp) {
    try {
      DateTime dateTime;

      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else if (timestamp is DateTime) {
        dateTime = timestamp;
      } else {
        return 'تاريخ غير محدد';
      }

      final localDateTime = dateTime.toLocal();
      final now = DateTime.now();
      final difference = now.difference(localDateTime);

      if (difference.inMinutes < 1) {
        return 'الآن';
      } else if (difference.inMinutes < 60) {
        return 'منذ ${difference.inMinutes}د';
      } else if (difference.inHours < 24) {
        return 'منذ ${difference.inHours}س';
      } else if (difference.inDays < 30) {
        return 'منذ ${difference.inDays} يوم';
      } else {
        return DateFormat('dd/MM/yyyy').format(localDateTime);
      }
    } catch (e) {
      return 'تاريخ غير صحيح';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _formatDate(createdAt),
        style: TextStyles.semiBold13.copyWith(color: Colors.grey.shade600),
      ),
    );
  }
}
