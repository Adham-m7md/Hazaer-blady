import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hadaer_blady/core/services/farmer_service.dart';
import 'package:hadaer_blady/core/services/location_service.dart';
import 'package:hadaer_blady/core/services/rating_service.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/core/widgets/custom_loading_indicator.dart';
import 'package:hadaer_blady/features/coops/widgets/coop.dart';

class CoopsFilterWidget extends StatefulWidget {
  final FarmerService farmerService;
  final LocationService locationService;
  final RatingService ratingService;

  const CoopsFilterWidget({
    super.key,
    required this.farmerService,
    required this.locationService,
    required this.ratingService,
  });

  @override
  _CoopsFilterWidgetState createState() => _CoopsFilterWidgetState();
}

class _CoopsFilterWidgetState extends State<CoopsFilterWidget> {
  String selectedFilter = 'highest_rated'; // Default to highest rated
  String? locationErrorMessage; // To display location-related errors

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedFilter == 'highest_rated'
                  ? 'الأكثر تقييما'
                  : selectedFilter == 'nearest'
                  ? 'الأقرب إليك'
                  : 'الأكثر عروضاً',
              style: TextStyles.bold16,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list, color: AppColors.kGrayColor),
              onSelected: (value) {
                setState(() {
                  selectedFilter = value;
                  locationErrorMessage = null; // Reset error message
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
                      value: 'most_offers',
                      child: Text('الأكثر عروضاً', style: TextStyles.bold16),
                    ),
                  ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (locationErrorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              locationErrorMessage!,
              style: TextStyles.semiBold16.copyWith(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: widget.farmerService.getFarmers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CustomLoadingIndicator());
              }
              if (snapshot.hasError) {
                log('Error fetching farmers: ${snapshot.error}');
                return const Center(child: Text('حدث خطأ أثناء جلب البيانات'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('لا توجد حضائر متاحة'));
              }

              final farmers = snapshot.data!;
              log('Fetched ${farmers.length} farmers');

              // Handle "highest_rated" filter
              if (selectedFilter == 'highest_rated') {
                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _sortFarmersByRating(farmers),
                  builder: (context, ratingSnapshot) {
                    if (ratingSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CustomLoadingIndicator());
                    }
                    if (ratingSnapshot.hasError) {
                      log(
                        'Error sorting farmers by rating: ${ratingSnapshot.error}',
                      );
                      return const Center(child: Text('خطأ في تصفية الحظائر'));
                    }
                    if (!ratingSnapshot.hasData ||
                        ratingSnapshot.data!.isEmpty) {
                      return const Center(child: Text('لا توجد حضائر متاحة'));
                    }

                    final sortedFarmers = ratingSnapshot.data!;
                    return ListView.builder(
                      itemCount: sortedFarmers.length,
                      itemBuilder: (context, index) {
                        final farmer = sortedFarmers[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Coop(
                            id: farmer['uid'] ?? '',
                            name: farmer['name'] ?? 'حضيرة غير معروفة',
                            city:
                                farmer['city']?.isNotEmpty ?? false
                                    ? farmer['city']
                                    : 'غير محدد',
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
                  future: _sortFarmersByDistance(farmers),
                  builder: (context, distanceSnapshot) {
                    if (distanceSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CustomLoadingIndicator());
                    }
                    if (distanceSnapshot.hasError) {
                      log(
                        'Error sorting farmers by distance: ${distanceSnapshot.error}',
                      );
                      return Center(
                        child: Text(
                          'خطأ في تصفية الحظائر: ${distanceSnapshot.error}',
                          style: TextStyles.semiBold16,
                        ),
                      );
                    }
                    if (!distanceSnapshot.hasData ||
                        distanceSnapshot.data!.isEmpty) {
                      return const Center(child: Text('لا توجد حضائر متاحة'));
                    }

                    final sortedFarmers = distanceSnapshot.data!;
                    return ListView.builder(
                      itemCount: sortedFarmers.length,
                      itemBuilder: (context, index) {
                        final farmer = sortedFarmers[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Coop(
                            id: farmer['uid'] ?? '',
                            name: farmer['name'] ?? 'حضيرة غير معروفة',
                            city:
                                farmer['city']?.isNotEmpty ?? false
                                    ? farmer['city']
                                    : 'غير محدد',
                          ),
                        );
                      },
                    );
                  },
                );
              }

              // Handle "most_offers" filter
              if (selectedFilter == 'most_offers') {
                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _sortFarmersByProductCount(farmers),
                  builder: (context, countSnapshot) {
                    if (countSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CustomLoadingIndicator());
                    }
                    if (countSnapshot.hasError) {
                      log(
                        'Error sorting farmers by product count: ${countSnapshot.error}',
                      );
                      return const Center(child: Text('خطأ في تصفية الحظائر'));
                    }
                    if (!countSnapshot.hasData || countSnapshot.data!.isEmpty) {
                      return const Center(child: Text('لا توجد حضائر متاحة'));
                    }

                    final sortedFarmers = countSnapshot.data!;
                    return ListView.builder(
                      itemCount: sortedFarmers.length,
                      itemBuilder: (context, index) {
                        final farmer = sortedFarmers[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Coop(
                            id: farmer['uid'] ?? '',
                            name: farmer['name'] ?? 'حضيرة غير معروفة',
                            city:
                                farmer['city']?.isNotEmpty ?? false
                                    ? farmer['city']
                                    : 'غير محدد',
                          ),
                        );
                      },
                    );
                  },
                );
              }

              // Default list (no sorting or other filters)
              return ListView.builder(
                itemCount: farmers.length,
                itemBuilder: (context, index) {
                  final farmer = farmers[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Coop(
                      id: farmer['uid'] ?? '',
                      name: farmer['name'] ?? 'حضيرة غير معروفة',
                      city:
                          farmer['city']?.isNotEmpty ?? false
                              ? farmer['city']
                              : 'غير محدد',
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Function to sort farmers by their average rating
  Future<List<Map<String, dynamic>>> _sortFarmersByRating(
    List<Map<String, dynamic>> farmers,
  ) async {
    final List<Map<String, dynamic>> farmerList = [];

    for (var farmer in farmers) {
      final farmerId = farmer['uid'] as String?;
      double averageRating = 0.0;

      if (farmerId != null && farmerId.isNotEmpty) {
        try {
          final ratingData = await widget.ratingService.fetchUserRatings(
            farmerId,
          );
          averageRating = ratingData['averageRating'] as double? ?? 0.0;
        } catch (e) {
          log('Error fetching rating for farmer $farmerId: $e');
        }
      }

      farmerList.add({...farmer, 'averageRating': averageRating});
    }

    // Sort by average rating in descending order
    farmerList.sort(
      (a, b) => (b['averageRating'] as double).compareTo(
        a['averageRating'] as double,
      ),
    );

    return farmerList;
  }

  // Function to sort farmers by their product count
  Future<List<Map<String, dynamic>>> _sortFarmersByProductCount(
    List<Map<String, dynamic>> farmers,
  ) async {
    final List<Map<String, dynamic>> farmerList = [];

    for (var farmer in farmers) {
      final farmerId = farmer['uid'] as String?;
      int productCount = 0;

      if (farmerId != null && farmerId.isNotEmpty) {
        try {
          final productSnapshot =
              await FirebaseFirestore.instance
                  .collection('products')
                  .where('farmer_id', isEqualTo: farmerId)
                  .get();
          productCount = productSnapshot.docs.length;
        } catch (e) {
          log('Error fetching product count for farmer $farmerId: $e');
        }
      }

      farmerList.add({...farmer, 'productCount': productCount});
    }

    // Sort by product count in descending order
    farmerList.sort(
      (a, b) => (b['productCount'] as int).compareTo(a['productCount'] as int),
    );

    return farmerList;
  }

  // Function to sort farmers by distance
  Future<List<Map<String, dynamic>>> _sortFarmersByDistance(
    List<Map<String, dynamic>> farmers,
  ) async {
    final List<Map<String, dynamic>> farmerList = [];

    // Try to get user location with permission prompt
    bool locationPermissionGranted = await widget.locationService
        .promptForLocationPermission(context);
    if (!locationPermissionGranted) {
      if (mounted) {
        setState(() {
          locationErrorMessage =
              'يرجى تفعيل خدمات الموقع أو السماح بالوصول لفرز الحظائر حسب المسافة';
        });
      }
      log('Location permission not granted, returning farmers without sorting');
      for (var farmer in farmers) {
        farmerList.add({...farmer, 'distance': double.infinity});
      }
      return farmerList;
    }

    Position? userLocation = await widget.locationService.getUserLocation();
    if (userLocation == null) {
      if (mounted) {
        setState(() {
          locationErrorMessage = 'تعذر الحصول على موقعك، يرجى المحاولة لاحقًا';
        });
      }
      log('User location unavailable, returning farmers without sorting');
      for (var farmer in farmers) {
        farmerList.add({...farmer, 'distance': double.infinity});
      }
      return farmerList;
    }

    log(
      'User location obtained: ${userLocation.latitude}, ${userLocation.longitude}',
    );

    for (var farmer in farmers) {
      final farmerId = farmer['uid'] as String?;
      double distance = double.infinity;

      if (farmerId != null && farmerId.isNotEmpty) {
        try {
          final farmerLocationDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(farmerId)
                  .collection('location')
                  .doc('current')
                  .get();

          if (farmerLocationDoc.exists) {
            final farmerLocation = farmerLocationDoc.data();
            final farmerLat = farmerLocation?['latitude'] as double?;
            final farmerLng = farmerLocation?['longitude'] as double?;

            if (farmerLat != null && farmerLng != null) {
              distance =
                  Geolocator.distanceBetween(
                    userLocation.latitude,
                    userLocation.longitude,
                    farmerLat,
                    farmerLng,
                  ) /
                  1000; // Distance in kilometers
              log('Distance to farmer $farmerId: $distance km');
            }
          } else {
            log('No location data for farmer $farmerId');
          }
        } catch (e) {
          log('Error fetching location for farmer $farmerId: $e');
        }
      }

      farmerList.add({...farmer, 'distance': distance});
    }

    // Sort by distance in ascending order
    farmerList.sort(
      (a, b) => (a['distance'] as double).compareTo(b['distance'] as double),
    );

    return farmerList;
  }
}
