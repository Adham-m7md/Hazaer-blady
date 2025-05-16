import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/constants.dart';
import 'package:hadaer_blady/core/services/custom_product_servise.dart';
import 'package:hadaer_blady/core/services/location_service.dart';
import 'package:hadaer_blady/core/services/rating_service.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/core/widgets/custom_loading_indicator.dart';
import 'package:hadaer_blady/features/home/presentation/widgets/custom_offers_list/offer_carousel.dart';
import 'package:hadaer_blady/features/home/presentation/widgets/user_name_widget.dart';
import 'package:hadaer_blady/features/notfications/notfications_screen.dart';
import 'package:hadaer_blady/features/product/presentation/product.dart';

class HomeScreenBody extends StatefulWidget {
  const HomeScreenBody({super.key});

  @override
  _HomeScreenBodyState createState() => _HomeScreenBodyState();
}

class _HomeScreenBodyState extends State<HomeScreenBody> {
  final CustomProductService productService = CustomProductService();
  final RatingService ratingService = RatingService();
  String? selectedFilter = 'newest'; // Default to newest filter

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(
          right: khorizintalPadding,
          left: khorizintalPadding,
          top: 12,
        ),
        child: Column(
          spacing: 8,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 8),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('مرحبا ..!', style: TextStyles.semiBold16),
                    UserNameWidget(),
                  ],
                ),
                Stack(
                  children: [
                    Positioned(
                      child: CircleAvatar(
                        backgroundColor: AppColors.lightPrimaryColor.withAlpha(
                          40,
                        ),
                        child: IconButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              NotificationsScreen.id,
                            );
                          },
                          icon: const Icon(
                            Icons.notifications_active,
                            color: AppColors.lightPrimaryColor,
                          ),
                        ),
                      ),
                    ),
                    const Positioned(
                      top: 4,
                      right: 0,
                      left: 0,
                      child: CircleAvatar(
                        backgroundColor: AppColors.kRedColor,
                        radius: 3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.vertical,
                child: Column(
                  spacing: 8,
                  children: [
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Text('عروض مميزة :', style: TextStyles.bold16),
                      ],
                    ),
                    FutureBuilder<List<CustomProduct>>(
                      future: productService.getAllProducts(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(child: CustomLoadingIndicator());
                        }
                        if (snapshot.hasError) {
                          log('Error fetching offers: ${snapshot.error}');
                          return const Center(
                            child: Text(
                              'خطأ في تحميل العروض',
                              style: TextStyles.semiBold16,
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text(
                              'لا توجد عروض متاحة',
                              style: TextStyles.semiBold16,
                            ),
                          );
                        }
                        final products = snapshot.data!;
                        log('Fetched ${products.length} special offers');
                        return OffersCarousel(products: products);
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المنتجات :', style: TextStyles.bold16),
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.filter_list,
                            color: AppColors.kGrayColor,
                          ),
                          onSelected: (value) {
                            setState(() {
                              selectedFilter = value;
                            });
                          },
                          itemBuilder:
                              (context) => [
                                const PopupMenuItem(
                                  value: 'highest_rated',
                                  child: Text(
                                    'الأكثر تقييما',
                                    style: TextStyles.bold16,
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'nearest',
                                  child: Text(
                                    'الأقرب إليك',
                                    style: TextStyles.bold16,
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'newest',
                                  child: Text(
                                    'الأحدث',
                                    style: TextStyles.bold16,
                                  ),
                                ),
                              ],
                        ),
                      ],
                    ),
                StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance.collection('products').snapshots(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.8,
        color: AppColors.kWiteColor,
        child: const Center(
          child: CustomLoadingIndicator(),
        ),
      );
    }
    if (snapshot.hasError) {
      log('Error fetching products: ${snapshot.error}');
      return Center(child: Text('خطأ: ${snapshot.error}'));
    }
    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد منتجات متاحة',
          style: TextStyles.semiBold16,
        ),
      );
    }

    final products = snapshot.data!.docs;
    log('Fetched ${products.length} products');

    // Handle "highest_rated" filter
    if (selectedFilter == 'highest_rated') {
      return FutureBuilder<List<Map<String, dynamic>>>(
        future: _sortProductsByFarmerRating(products),
        builder: (context, ratingSnapshot) {
          if (ratingSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CustomLoadingIndicator());
          }
          if (ratingSnapshot.hasError) {
            log('Error sorting products by rating: ${ratingSnapshot.error}');
            return const Center(child: Text('خطأ في تصفية المنتجات'));
          }
          if (!ratingSnapshot.hasData || ratingSnapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد منتجات متاحة'));
          }

          final sortedProducts = ratingSnapshot.data!;
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedProducts.length,
            itemBuilder: (context, index) {
              final product = sortedProducts[index]['product'] as Map<String, dynamic>;
              final productId = sortedProducts[index]['productId'] as String;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Product(
                  product: {
                    ...product,
                    'city': product['city'] ?? 'غير محدد',
                    'quantity': product['quantity'] ?? 1000,
                  },
                  productId: productId,
                ),
              );
            },
          );
        },
      );
    }

    // Handle "nearest" filter
    if (selectedFilter == 'nearest') {
      return FutureBuilder<List<Map<String, dynamic>>>(
        future: LocationService().sortProductsByDistance(products),
        builder: (context, distanceSnapshot) {
          if (distanceSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CustomLoadingIndicator());
          }
          if (distanceSnapshot.hasError) {
            log('Error sorting products by distance: ${distanceSnapshot.error}');
            return const Center(child: Text('خطأ في تصفية المنتجات'));
          }
          if (!distanceSnapshot.hasData || distanceSnapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد منتجات متاحة'));
          }

          final sortedProducts = distanceSnapshot.data!;
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedProducts.length,
            itemBuilder: (context, index) {
              final product = sortedProducts[index]['product'] as Map<String, dynamic>;
              final productId = sortedProducts[index]['productId'] as String;
              final distance = sortedProducts[index]['distance'] as double;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Product(
                  product: {
                    ...product,
                    'city': product['city'] ?? 'غير محدد',
                    'quantity': product['quantity'] ?? 1000,
                    'distance': distance.toStringAsFixed(2), // إضافة المسافة
                  },
                  productId: productId,
                ),
              );
            },
          );
        },
      );
    }

    // Handle "newest" filter
    if (selectedFilter == 'newest') {
      final sortedProducts = products.toList()
        ..sort((a, b) {
          final aTimestamp = (a.data() as Map<String, dynamic>)['created_at'] as Timestamp?;
          final bTimestamp = (b.data() as Map<String, dynamic>)['created_at'] as Timestamp?;
          if (aTimestamp == null && bTimestamp == null) return 0;
          if (aTimestamp == null) return 1;
          if (bTimestamp == null) return -1;
          return bTimestamp.compareTo(aTimestamp); // Newest first
        });

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sortedProducts.length,
        itemBuilder: (context, index) {
          final product = sortedProducts[index].data() as Map<String, dynamic>;
          final productId = sortedProducts[index].id;

          if (productId.isEmpty) {
            log('Warning: Empty productId at index $index');
            return const SizedBox.shrink();
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Product(
              product: {
                ...product,
                'city': product['city'] ?? 'غير محدد',
                'quantity': product['quantity'] ?? 1000,
              },
              productId: productId,
            ),
          );
        },
      );
    }

    // Default product list (no sorting or other filters)
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index].data() as Map<String, dynamic>;
        final productId = products[index].id;
        log('Product $index: $product, ID: $productId');

        if (productId.isEmpty) {
          log('Warning: Empty productId at index $index');
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Product(
            product: {
              ...product,
              'city': product['city'] ?? 'غير محدد',
              'quantity': product['quantity'] ?? 1000,
            },
            productId: productId,
          ),
        );
      },
    );
  },
) ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to sort products by farmer's average rating
  Future<List<Map<String, dynamic>>> _sortProductsByFarmerRating(
    List<QueryDocumentSnapshot> products,
  ) async {
    final List<Map<String, dynamic>> productList = [];

    for (var doc in products) {
      final product = doc.data() as Map<String, dynamic>;
      final productId = doc.id;
      final farmerId = product['farmer_id'] as String?;

      double averageRating = 0.0;
      if (farmerId != null && farmerId.isNotEmpty) {
        try {
          final ratingData = await ratingService.fetchUserRatings(farmerId);
          averageRating = ratingData['averageRating'] as double? ?? 0.0;
        } catch (e) {
          log('Error fetching rating for farmer $farmerId: $e');
        }
      }

      productList.add({
        'product': product,
        'productId': productId,
        'averageRating': averageRating,
      });
    }

    // Sort by average rating in descending order
    productList.sort(
      (a, b) => (b['averageRating'] as double).compareTo(
        a['averageRating'] as double,
      ),
    );

    return productList;
  }
}
