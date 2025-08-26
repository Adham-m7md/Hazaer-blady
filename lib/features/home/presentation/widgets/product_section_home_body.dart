import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/services/location_service.dart';
import 'package:hadaer_blady/core/services/rating_service.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/core/widgets/custom_loading_indicator.dart';
import 'package:hadaer_blady/features/product/presentation/product.dart';

class ProductsSectionWidget extends StatefulWidget {
  const ProductsSectionWidget({super.key});

  @override
  _ProductsSectionWidgetState createState() => _ProductsSectionWidgetState();
}

class _ProductsSectionWidgetState extends State<ProductsSectionWidget> {
  final RatingService ratingService = RatingService();
  String? selectedFilter = 'newest'; // Default to newest filter

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with filter
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('المنتجات :', style: TextStyles.bold16),
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list, color: AppColors.kGrayColor),
              onSelected: (value) {
                setState(() {
                  selectedFilter = value;
                });
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'highest_rated',
                      child: Text('الأكثر تقييما', style: TextStyles.bold16),
                    ),
                    const PopupMenuItem(
                      value: 'nearest',
                      child: Text('الأقرب إليك', style: TextStyles.bold16),
                    ),
                    const PopupMenuItem(
                      value: 'newest',
                      child: Text('الأحدث', style: TextStyles.bold16),
                    ),
                  ],
            ),
          ],
        ),

        // Products List
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('products').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.5,
                color: AppColors.kWiteColor,
                child: const Center(child: CustomLoadingIndicator()),
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

            return _buildFilteredProductsList(products);
          },
        ),
      ],
    );
  }

  Widget _buildFilteredProductsList(List<QueryDocumentSnapshot> products) {
    switch (selectedFilter) {
      case 'highest_rated':
        return _buildHighestRatedProducts(products);
      case 'nearest':
        return _buildNearestProducts(products);
      case 'newest':
        return _buildNewestProducts(products);
      default:
        return _buildDefaultProducts(products);
    }
  }

  Widget _buildHighestRatedProducts(List<QueryDocumentSnapshot> products) {
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
          return const Center(child: Text('لا توجد منتjat متاحة'));
        }

        final sortedProducts = ratingSnapshot.data!;
        return _buildProductsList(
          sortedProducts
              .map(
                (item) => {
                  'product': item['product'] as Map<String, dynamic>,
                  'productId': item['productId'] as String,
                },
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildNearestProducts(List<QueryDocumentSnapshot> products) {
    return FutureBuilder<bool>(
      future: LocationService().promptForLocationPermission(context),
      builder: (context, permissionSnapshot) {
        if (permissionSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CustomLoadingIndicator());
        }
        if (!permissionSnapshot.hasData || !permissionSnapshot.data!) {
          // Fallback to newest filter if location permission is denied
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              selectedFilter = 'newest';
            });
          });
          return _buildNewestProducts(products);
        }

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: LocationService().sortProductsByDistance(products),
          builder: (context, distanceSnapshot) {
            if (distanceSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CustomLoadingIndicator());
            }
            if (distanceSnapshot.hasError) {
              log(
                'Error sorting products by distance: ${distanceSnapshot.error}',
              );
              return const Center(
                child: Text('خطأ في تصفية المنتجات حسب الموقع'),
              );
            }
            if (!distanceSnapshot.hasData || distanceSnapshot.data!.isEmpty) {
              // Fallback to newest filter if no products or location data
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  selectedFilter = 'newest';
                });
              });
              return _buildNewestProducts(products);
            }

            final sortedProducts = distanceSnapshot.data!;
            // Check if any products have valid distances
            bool hasValidDistances = sortedProducts.any(
              (item) => (item['distance'] as double).isFinite,
            );
            if (!hasValidDistances) {
              // Fallback to newest filter if no valid location data
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  selectedFilter = 'newest';
                });
              });
              return _buildNewestProducts(products);
            }

            return _buildProductsList(
              sortedProducts.map((item) {
                final product = item['product'] as Map<String, dynamic>;
                final distance = item['distance'] as double;
                return {
                  'product': {
                    ...product,
                    'distance':
                        distance.isFinite
                            ? distance.toStringAsFixed(2)
                            : 'غير معروف',
                  },
                  'productId': item['productId'] as String,
                };
              }).toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildNewestProducts(List<QueryDocumentSnapshot> products) {
    final sortedProducts =
        products.toList()..sort((a, b) {
          final aTimestamp =
              (a.data() as Map<String, dynamic>)['created_at'] as Timestamp?;
          final bTimestamp =
              (b.data() as Map<String, dynamic>)['created_at'] as Timestamp?;
          if (aTimestamp == null && bTimestamp == null) return 0;
          if (aTimestamp == null) return 1;
          if (bTimestamp == null) return -1;
          return bTimestamp.compareTo(aTimestamp); // Newest first
        });

    return _buildProductsList(
      sortedProducts
          .map(
            (doc) => {
              'product': doc.data() as Map<String, dynamic>,
              'productId': doc.id,
            },
          )
          .toList(),
    );
  }

  Widget _buildDefaultProducts(List<QueryDocumentSnapshot> products) {
    return _buildProductsList(
      products
          .map(
            (doc) => {
              'product': doc.data() as Map<String, dynamic>,
              'productId': doc.id,
            },
          )
          .toList(),
    );
  }

  Widget _buildProductsList(List<Map<String, dynamic>> productsList) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: productsList.length,
      itemBuilder: (context, index) {
        final productData = productsList[index];
        final product = productData['product'] as Map<String, dynamic>;
        final productId = productData['productId'] as String;

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
