import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hadaer_blady/core/services/custom_product_servise.dart';
import 'package:hadaer_blady/core/services/farmer_service.dart';
import 'package:hadaer_blady/core/services/firebase_auth_service.dart';
import 'package:hadaer_blady/core/services/get_it.dart';
import 'package:hadaer_blady/core/services/rating_service.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_directions.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/core/utils/svg_images.dart';
import 'package:hadaer_blady/features/cart/cubit/cart_cubit.dart';
import 'package:hadaer_blady/features/home/presentation/home_screen.dart';
import 'package:hadaer_blady/features/home/presentation/widgets/custom_offers_list/offer_carousel.dart';
import 'package:hadaer_blady/features/product/widgets/farmer_info.dart';
import 'package:hadaer_blady/features/product/widgets/location_info.dart';
import 'package:hadaer_blady/features/product/widgets/product_details_content.dart';
import 'package:hadaer_blady/features/product/widgets/rating_info.dart';
import 'package:hadaer_blady/features/rateing/cubit/rating_cubit.dart';
import 'package:hadaer_blady/features/rateing/cubit/rating_state.dart';

class AddCustomOrderToCart extends StatelessWidget {
  const AddCustomOrderToCart({
    super.key,
    required this.onPressed,
    required this.text,
    this.color = AppColors.kprimaryColor,
    this.isLoading = false,
  });

  final VoidCallback onPressed;
  final String text;
  final Color color;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.screenHeight * 0.06,
      width: double.infinity,
      child: TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          backgroundColor: isLoading ? AppColors.klightGrayColor : color,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        child: Text(
          isLoading ? 'جاري الإضافة...' : text,
          style: TextStyles.bold16.copyWith(color: AppColors.kWiteColor),
        ),
      ),
    );
  }
}

class CustomProductDetailScreen extends StatefulWidget {
  final CustomProduct product;

  const CustomProductDetailScreen({super.key, required this.product});

  static const id = 'CustomProductDetailScreen';

  @override
  State<CustomProductDetailScreen> createState() =>
      _CustomProductDetailScreenState();
}

class _CustomProductDetailScreenState extends State<CustomProductDetailScreen> {
  final FirebaseAuthService firebaseAuthService = getIt<FirebaseAuthService>();
  final FarmerService farmerService = getIt<FarmerService>();
  final CustomProductService customProductService =
      getIt<CustomProductService>();
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    log(
      'Initialized CustomProductDetailScreen with product: ${widget.product.id} - ${widget.product.title}',
    );
  }

  void _loadCurrentUserId() {
    final userId = firebaseAuthService.getCurrentUser()?.uid ?? '';
    setState(() {
      _currentUserId = userId;
    });
    log('Current user ID: $_currentUserId');
  }

  Future<bool> isFarmer() async {
    try {
      final userData = await firebaseAuthService.getCurrentUserData();
      return userData['job_title'] == 'صاحب حظيرة';
    } catch (e) {
      log('Error checking farmer status: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> fetchFarmerData(String farmerId) async {
    try {
      if (farmerId.isEmpty) {
        log('Empty farmerId provided');
        return {};
      }
      final farmerData = await farmerService.getFarmerById(farmerId);
      log('Fetched farmer data: $farmerData');
      return farmerData;
    } catch (e) {
      log('Error fetching farmer data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل بيانات المزارع: $e')),
      );
      return {};
    }
  }

  Future<void> _handleAddToCart(BuildContext context) async {
    try {
      final cartCubit = context.read<CartCubit>();
      const quantity = 1;
      final productData = {
        'id': widget.product.id,
        'name': widget.product.title,
        'price': widget.product.price,
        'imageUrl': widget.product.imageUrl,
        'description': widget.product.description,
        'farmerId': widget.product.farmerId,
        'displayLocation': widget.product.displayLocation,
      };
      final totalPrice = widget.product.price * quantity;

      log(
        'Adding to cart: ${widget.product.title}, Quantity: $quantity, Total Price: $totalPrice, Image URL: ${widget.product.imageUrl}',
      );

      if (productData['id'] == null) {
        _showErrorMessage(context, 'معرف المنتج غير صالح');
        return;
      }

      if (productData['imageUrl'] == null) {
        log('Warning: imageUrl is empty or null');
      }

      await cartCubit.addToCart(
        productId: widget.product.id,
        productData: productData,
        // quantity: quantity,
        totalPrice: totalPrice,
      );

      final isUserFarmer = await isFarmer();
      if (isUserFarmer) {
        _navigateToHomeScreen(context, isUserFarmer);
      } else {
        _showSuccessMessage(context, isUserFarmer);
      }
    } catch (error) {
      _showErrorMessage(context, error.toString());
    }
  }

  void _navigateToHomeScreen(BuildContext context, bool isFarmer) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(initialTabIndex: isFarmer ? 3 : 2),
      ),
      (route) => false,
    );
  }

  void _showSuccessMessage(BuildContext context, bool isFarmer) {
    showDialog(
      context: context,
      builder:
          (context) => CustomeShowDialog(
            text: 'تمت إضافة ${widget.product.title} إلى السلة',
            buttonText: 'عرض السلة',
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          HomeScreen(initialTabIndex: isFarmer ? 3 : 2),
                ),
                (route) => false,
              );
            },
          ),
    );
  }

  void _showErrorMessage(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder:
          (context) => CustomeShowDialog(
            text: 'فشلت عملية الإضافة: $errorMessage',
            buttonText: 'حاول مرة أخرى',
            onPressed: () {
              Navigator.pop(context);
            },
            isError: true,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    log(
      'Building CustomProductDetailScreen for product: ${widget.product.title}, farmerId: ${widget.product.farmerId}',
    );
    return BlocProvider(
      create: (context) => CartCubit(),
      child: Scaffold(
        backgroundColor: AppColors.kWiteColor,
        body: SafeArea(
          child: SingleChildScrollView(
            child: FutureBuilder<Map<String, dynamic>>(
              future: fetchFarmerData(widget.product.farmerId),
              builder: (context, farmerSnapshot) {
                final farmerData = farmerSnapshot.data ?? {};
                if (farmerSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (farmerSnapshot.hasError) {
                  log('Farmer data error: ${farmerSnapshot.error}');
                  return const Center(
                    child: Text('خطأ في تحميل بيانات المزارع'),
                  );
                }

                final isOwnOffer = _currentUserId == widget.product.farmerId;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        color: AppColors.kFillGrayColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Hero(
                        tag: 'product_${widget.product.id}',
                        child: CustomProductImage(product: widget.product),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FarmerInfo(
                            farmerData: farmerData,
                            farmerId: widget.product.farmerId,
                          ),
                          LocationInfo(farmerData: farmerData),
                          BlocProvider(
                            create:
                                (context) => RatingCubit(
                                  ratingService: RatingService(),
                                  auth: firebaseAuthService.auth,
                                  userId: widget.product.farmerId,
                                ),
                            child: RatingDisplay(
                              userId: widget.product.farmerId,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                widget.product.title,
                                style: TextStyles.bold19.copyWith(
                                  color: Colors.black87,
                                  height: 1.3,
                                ),
                              ),
                              SimpleProductDateWidget(
                                createdAt: widget.product.createdAt,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.product.description,
                            style: TextStyles.regular16.copyWith(
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text(
                                'العرض متاح في: ',
                                style: TextStyles.medium15,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.product.displayLocation,
                                style: TextStyles.medium15,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.kprimaryColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.kprimaryColor.withOpacity(
                                      0.3,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                '${widget.product.price.toStringAsFixed(2)} دينار',
                                style: TextStyles.bold16.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: context.screenHeight * 0.03),
                          if (!isOwnOffer)
                            BlocBuilder<CartCubit, CartState>(
                              builder: (context, state) {
                                return AddCustomOrderToCart(
                                  onPressed: () => _handleAddToCart(context),
                                  text: 'إضافة إلى السلة',
                                  isLoading: state is CartLoading,
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class RatingDisplay extends StatelessWidget {
  final String userId;

  const RatingDisplay({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RatingCubit, RatingState>(
      builder: (context, state) {
        if (state is RatingLoadingState) {
          return const Center(child: CircularProgressIndicator());
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
          final totalReviews = state.totalReviews;
          return RatingInfo(
            rating: averageRating.toStringAsFixed(1),
            reviews: totalReviews,
            userId: userId,
          );
        }
        return RatingInfo(rating: '0.0', reviews: 0, userId: userId);
      },
    );
  }
}

class CustomProductImage extends StatelessWidget {
  const CustomProductImage({super.key, required this.product});

  final CustomProduct product;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.network(
          product.imageUrl,
          fit: BoxFit.cover,
          height: context.screenHeight * 0.3,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            log('Failed to load image: ${product.imageUrl}, Error: $error');
            return Container(
              height: context.screenHeight * 0.3,
              color: AppColors.kFillGrayColor,
              child: const Center(
                child: Text(
                  'لا يوجد صورة لتحميلها',
                  style: TextStyles.semiBold16,
                ),
              ),
            );
          },
        ),
        Positioned(
          top: 16,
          left: 12,
          child: IconButton.outlined(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(
                AppColors.kWiteColor.withAlpha(50),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            icon: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.arrow_forward_ios_outlined,
                color: AppColors.kBlackColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CustomeShowDialog extends StatelessWidget {
  const CustomeShowDialog({
    super.key,
    required this.text,
    required this.buttonText,
    required this.onPressed,
    this.isError = false,
  });

  final String text;
  final String buttonText;
  final VoidCallback onPressed;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.kWiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Center(
        child: Column(
          spacing: 36,
          children: [
            SvgPicture.asset(Assets.imagesCongrates),
            Text(
              text,
              style: TextStyles.semiBold16,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
            AddCustomOrderToCart(onPressed: onPressed, text: buttonText),
          ],
        ),
      ),
    );
  }
}
