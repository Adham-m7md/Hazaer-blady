import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:hadaer_blady/core/constants.dart';
import 'package:hadaer_blady/core/services/firebase_auth_service.dart';
import 'package:hadaer_blady/core/services/get_it.dart';
import 'package:hadaer_blady/core/services/rating_service.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_directions.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/core/widgets/custom_loading_indicator.dart';
import 'package:hadaer_blady/features/home/presentation/home_screen.dart';
import 'package:hadaer_blady/features/product/presentation/product.dart';
import 'package:hadaer_blady/features/rateing/cubit/rating_cubit.dart';
import 'package:hadaer_blady/features/rateing/cubit/rating_state.dart';
import 'package:hadaer_blady/features/rateing/view/rating_screen.dart';

class CoopDetails extends StatelessWidget {
  final String farmerId;

  const CoopDetails({super.key, required this.farmerId});
  static const String id = 'CoopDetails';

  Future<bool> checkIfFarmer() async {
    final authService = GetIt.instance<FirebaseAuthService>();
    try {
      final userData = await authService.getCurrentUserData();
      return userData['job_title'] == 'صاحب حظيرة';
    } catch (e) {
      log('Error checking farmer status: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = getIt<FirebaseAuthService>();
    log('CoopDetails build with farmerId: $farmerId');

    if (farmerId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('تفاصيل الحضيرة', style: TextStyles.bold19),
          backgroundColor: AppColors.kWiteColor,
          automaticallyImplyLeading: false,
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios_outlined),
              onPressed: () async {
                final isFarmer = await checkIfFarmer();
                if (isFarmer) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeScreen(initialTabIndex: 0),
                    ),
                    (route) => false,
                  );
                } else {
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        body: const Center(child: Text('معرف الحضيرة غير متوفر')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.kWiteColor,
      appBar: AppBar(
        backgroundColor: AppColors.kWiteColor,
        title: FutureBuilder<Map<String, dynamic>>(
          future: authService.getFarmerById(farmerId),
          builder: (context, snapshot) {
            String title;
            if (snapshot.connectionState == ConnectionState.waiting) {
              title = 'جارٍ التحميل...';
            } else if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              title = 'تفاصيل الحضيرة';
            } else {
              title = snapshot.data!['name'] ?? 'تفاصيل الحضيرة';
            }
            return Text(title, style: TextStyles.bold19);
          },
        ),
        automaticallyImplyLeading: false,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_outlined),
            onPressed: () async {
              final isFarmer = await checkIfFarmer();
              if (isFarmer) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(initialTabIndex: 0),
                  ),
                  (route) => false,
                );
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: authService.getFarmerById(farmerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            log('Farmer data error: ${snapshot.error}');
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد بيانات لهذه الحضيرة'));
          }

          final farmer = snapshot.data!;
          log('Farmer data: $farmer');
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                farmer['profile_image_url']?.isNotEmpty ?? false
                    ? Image.network(
                      farmer['profile_image_url'],
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              color: AppColors.kFillGrayColor,
                              borderRadius: const BorderRadius.all(
                                Radius.circular(4),
                              ),
                            ),
                          ),
                    )
                    : Container(
                      color: AppColors.kFillGrayColor,
                      width: double.infinity,
                      height: context.screenHeight * 0.25,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 4,
                          children: [
                            const Icon(
                              Icons.person,
                              color: AppColors.kGrayColor,
                              size: 40,
                            ),
                            const Text(
                              'لا يوجد صورة',
                              style: TextStyles.semiBold16,
                            ),
                          ],
                        ),
                      ),
                    ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: khorizintalPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            'المدينة  : ',
                            style: TextStyles.semiBold16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            farmer['city']?.isNotEmpty ?? false
                                ? farmer['city']
                                : 'غير محدد',
                            style: TextStyles.semiBold16,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text(
                            'العنوان : ',
                            style: TextStyles.semiBold16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              farmer['address']?.isNotEmpty ?? false
                                  ? farmer['address']
                                  : 'غير محدد',
                              style: TextStyles.semiBold16,
                            ),
                          ),
                        ],
                      ),
                      BlocProvider(
                        create:
                            (context) => RatingCubit(
                              ratingService: RatingService(),
                              auth: authService.auth,
                              userId: farmerId,
                            ),
                        child: RatingDisplay(farmerId: farmerId),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: khorizintalPadding,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Text('المنتجات:  ', style: TextStyles.bold16),
                      StreamBuilder<QuerySnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('products')
                                .where('farmer_id', isEqualTo: farmerId)
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox.shrink();
                          }
                          if (snapshot.hasError || !snapshot.hasData) {
                            return const Text('(0)', style: TextStyles.bold19);
                          }
                          final productCount = snapshot.data!.docs.length;
                          return Text(
                            '($productCount)',
                            style: TextStyles.bold19,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('products')
                          .where('farmer_id', isEqualTo: farmerId)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CustomLoadingIndicator());
                    }
                    if (snapshot.hasError) {
                      log('Products query error: ${snapshot.error}');
                      return Center(child: Text('خطأ: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: khorizintalPadding,
                        ),
                        child: Center(
                          child: Text(
                            'لا توجد منتجات متاحة',
                            style: TextStyles.semiBold16,
                          ),
                        ),
                      );
                    }

                    final products = snapshot.data!.docs;
                    log('Products count: ${products.length}');
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product =
                            products[index].data() as Map<String, dynamic>;
                        final productId = products[index].id;
                        log('Product $index: $product, ID: $productId');
                        if (productId.isEmpty) {
                          log('Warning: Empty productId at index $index');
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: khorizintalPadding,
                            vertical: 8,
                          ),
                          child: Product(
                            product: {
                              ...product,
                              'city': farmer['city'] ?? 'غير محدد',
                              'quantity': product['quantity'] ?? 1000,
                            },
                            productId: productId,
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ويدجت منفصلة لعرض التقييمات
class RatingDisplay extends StatelessWidget {
  final String farmerId;

  const RatingDisplay({super.key, required this.farmerId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RatingCubit, RatingState>(
      builder: (context, state) {
        if (state is RatingLoadingState) {
          return const Center(child: CustomLoadingIndicator());
        }
        if (state is RatingErrorState) {
          log(
            'Error fetching ratings for farmerId $farmerId: ${state.message}',
          );
          return const Text(
            'خطأ في جلب التقييمات',
            style: TextStyles.semiBold16,
          );
        }
        double averageRating = 0.0;
        int totalReviews = 0;
        if (state is RatingSuccessState) {
          averageRating = state.averageRating;
          totalReviews = state.totalReviews;
        }
        return Row(
          children: [
            const Text('التقييم  : ', style: TextStyles.semiBold16),
            const SizedBox(width: 8),
            Text(
              averageRating.toStringAsFixed(1),
              style: TextStyles.bold16.copyWith(color: Colors.deepOrangeAccent),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () {
                log('Navigating to RatingScreen with userId: $farmerId');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RatingScreen(userId: farmerId),
                  ),
                );
              },
              child: Text(
                '(عدد التقييمات : $totalReviews)',
                style: TextStyles.semiBold16.copyWith(
                  color: AppColors.kprimaryColor,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.kprimaryColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
