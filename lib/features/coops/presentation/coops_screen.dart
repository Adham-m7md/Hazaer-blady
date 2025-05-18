import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hadaer_blady/core/constants.dart';
import 'package:hadaer_blady/core/services/farmer_service.dart';
import 'package:hadaer_blady/core/services/firebase_auth_service.dart';
import 'package:hadaer_blady/core/services/get_it.dart';
import 'package:hadaer_blady/core/services/rating_service.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/core/widgets/custom_loading_indicator.dart';
import 'package:hadaer_blady/features/coops/widgets/coop.dart';

class CoopsScreen extends StatefulWidget {
  const CoopsScreen({super.key});
  static const String id = 'CoopsScreen';

  @override
  _CoopsScreenState createState() => _CoopsScreenState();
}

class _CoopsScreenState extends State<CoopsScreen> {
  final FirebaseAuthService authService = getIt<FirebaseAuthService>();
  final FarmerService farmerService = getIt<FarmerService>();
  final RatingService ratingService = RatingService();
  String selectedFilter = 'highest_rated'; // Default to highest rated

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
            const Text('الحظائر', style: TextStyles.bold19),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الأكثر تقييما', style: TextStyles.bold16),
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
                          child: Text('الأقرب إليك', style: TextStyles.bold16),
                        ),
                        const PopupMenuItem(
                          value: 'most_offers',
                          child: Text(
                            'الأكثر عروضاً',
                            style: TextStyles.bold16,
                          ),
                        ),
                      ],
                ),
              ],
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: farmerService.getFarmers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CustomLoadingIndicator());
                  }
                  if (snapshot.hasError) {
                    log('Error fetching farmers: ${snapshot.error}');
                    return const Center(
                      child: Text('حدث خطأ أثناء جلب البيانات'),
                    );
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
                          return const Center(
                            child: Text('خطأ في تصفية الحظائر'),
                          );
                        }
                        if (!ratingSnapshot.hasData ||
                            ratingSnapshot.data!.isEmpty) {
                          return const Center(
                            child: Text('لا توجد حضائر متاحة'),
                          );
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
                              distanceSnapshot.error.toString(),
                              style: TextStyles.semiBold16,
                            ),
                          );
                        }
                        if (!distanceSnapshot.hasData ||
                            distanceSnapshot.data!.isEmpty) {
                          return const Center(
                            child: Text('لا توجد حضائر متاحة'),
                          );
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
                          return const Center(
                            child: Text('خطأ في تصفية الحظائر'),
                          );
                        }
                        if (!countSnapshot.hasData ||
                            countSnapshot.data!.isEmpty) {
                          return const Center(
                            child: Text('لا توجد حضائر متاحة'),
                          );
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
        ),
      ),
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
          final ratingData = await ratingService.fetchUserRatings(farmerId);
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

  Future<Position?> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        log('Location services are disabled');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          log('Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        log('Location permission permanently denied');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      log('Error getting user location: $e');
      return null;
    }
  }

  // دالة لفرز الحظائر حسب المسافة
  Future<List<Map<String, dynamic>>> _sortFarmersByDistance(
    List<Map<String, dynamic>> farmers,
  ) async {
    final List<Map<String, dynamic>> farmerList = [];
    Position? userLocation = await _getUserLocation();

    if (userLocation == null) {
      log('User location unavailable, returning farmers without sorting');
      // إرجاع الحظائر بدون فرز حسب المسافة
      for (var farmer in farmers) {
        farmerList.add({...farmer, 'distance': double.infinity});
      }
      return farmerList;
    }

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
            final farmerLocation = farmerLocationDoc.data()!;
            final farmerLat = farmerLocation['latitude'] as double?;
            final farmerLng = farmerLocation['longitude'] as double?;

            if (farmerLat != null && farmerLng != null) {
              distance =
                  Geolocator.distanceBetween(
                    userLocation.latitude,
                    userLocation.longitude,
                    farmerLat,
                    farmerLng,
                  ) /
                  1000; // المسافة بالكيلومترات
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
