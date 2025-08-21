import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hadaer_blady/core/services/firebase_auth_service.dart';
import 'package:hadaer_blady/core/services/get_it.dart';
import 'package:hadaer_blady/core/services/rating_service.dart';
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
    // final minWeight =
    //     (widget.productData['min_weight'] as num?)?.toDouble() ?? 0.0;
    // final maxWeight =
    //     (widget.productData['max_weight'] as num?)?.toDouble() ?? 0.0;
    // final averageWeight = (minWeight + maxWeight) / 2;
    // final totalPrice = (widget.quantity * pricePerKg * averageWeight)
    //  .toStringAsFixed(2);
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
                LocationInfo(farmerData: widget.farmerData),
                // إنشاء BlocProvider جديد مع تأخير بدء الاستماع للتقييمات
                BlocProvider(
                  create:
                      (context) => RatingCubit(
                        ratingService: RatingService(),
                        auth: getIt<FirebaseAuthService>().auth,
                        userId: _farmerId,
                      ),
                  child: RatingWithBlocBuilder(farmerId: _farmerId),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    widget.productData['name'] ?? 'منتج غير معروف',
                    style: TextStyles.semiBold19,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    textAlign: TextAlign.center,
                    widget.productData['description'] ?? 'لا يوجد وصف',
                    style: TextStyles.semiBold16,
                  ),
                ),
                const SizedBox(height: 16),
                // QuantitySelector(quantity: widget.quantity),
                // const SizedBox(height: 16),
                // WeightInfo(minWeight: minWeight, maxWeight: maxWeight),
                // const SizedBox(height: 16),
                // PriceInfo(pricePerKg: pricePerKg),
                const SizedBox(height: 16),
                TotalPriceInfo(totalPrice: pricePerKg.toStringAsFixed(2)),
                SizedBox(height: context.screenHeight * 0.07),
                if (!isOwnProduct)
                  BlocProvider(
                    create: (context) => CartCubit(),
                    child: AddToCartButton(
                      productData: widget.productData,
                      // quantity: widget.quantity,
                      totalPrice: double.parse(pricePerKg.toStringAsFixed(2)),
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
    // تأكد من استدعاء refreshRatings لضمان بدء التحميل
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = BlocProvider.of<RatingCubit>(context);
      cubit.refreshRatings();
    });

    return BlocBuilder<RatingCubit, RatingState>(
      builder: (context, state) {
        // عرض بيانات التقييم بناءً على حالة الكيوبت
        if (state is RatingLoadingState) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: CircularProgressIndicator(),
            ),
          );
        } else if (state is RatingErrorState) {
          // عرض واجهة أكثر وضوحًا في حالة الخطأ
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

        // حالة افتراضية عندما لا توجد بيانات بعد
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
