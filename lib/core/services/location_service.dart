import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  // Get the user's current location
  Future<Position?> getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        log('Location services are disabled');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        log('Location permission denied, requesting permission');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          log('Location permission denied by user');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        log('Location permission permanently denied');
        return null;
      }

      log('Getting current position');
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      log('Error getting location: $e');
      return null;
    }
  }

  // Sort products by distance from user
  Future<List<Map<String, dynamic>>> sortProductsByDistance(
    List<QueryDocumentSnapshot> products,
  ) async {
    final List<Map<String, dynamic>> productList = [];
    int farmersWithLocation = 0;
    int farmersWithoutLocation = 0;

    // Get user location
    Position? userLocation = await getUserLocation();

    if (userLocation == null) {
      log('User location unavailable, cannot sort by distance');
      // Instead of throwing an exception, we'll return products without distance sorting
      // This provides a more graceful fallback
      for (var doc in products) {
        final product = doc.data() as Map<String, dynamic>;
        productList.add({
          'product': product,
          'productId': doc.id,
          'distance': double.infinity,
        });
      }
      return productList;
    }

    log(
      'User location obtained: ${userLocation.latitude}, ${userLocation.longitude}',
    );

    // For each product, try to get its farmer's location
    for (var doc in products) {
      final product = doc.data() as Map<String, dynamic>;
      final productId = doc.id;
      final farmerId = product['farmer_id'] as String?;

      double distance = double.infinity;

      if (farmerId != null && farmerId.isNotEmpty) {
        try {
          // First try to get from subcollection location/current
          var farmerLocationDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(farmerId)
                  .collection('location')
                  .doc('current')
                  .get();

          // If not found, try to check if location is stored directly in user document
          if (!farmerLocationDoc.exists) {
            final farmerDoc =
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(farmerId)
                    .get();

            if (farmerDoc.exists &&
                farmerDoc.data()!.containsKey('latitude') &&
                farmerDoc.data()!.containsKey('longitude')) {
              final farmerData = farmerDoc.data()!;
              final farmerLat = farmerData['latitude'] as double?;
              final farmerLng = farmerData['longitude'] as double?;

              if (farmerLat != null && farmerLng != null) {
                distance =
                    Geolocator.distanceBetween(
                      userLocation.latitude,
                      userLocation.longitude,
                      farmerLat,
                      farmerLng,
                    ) /
                    1000; // Convert to kilometers
                farmersWithLocation++;
                log(
                  'Found location directly in user document for farmer $farmerId: $distance km',
                );
              }
            }
          } else {
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
                  1000; // Convert to kilometers
              farmersWithLocation++;
              log(
                'Found location in subcollection for farmer $farmerId: $distance km',
              );
            }
          }

          if (distance == double.infinity) {
            farmersWithoutLocation++;
            log('No valid location data found for farmer $farmerId');
          }
        } catch (e) {
          log('Error fetching location for farmer $farmerId: $e');
        }
      } else {
        log('No farmerId for product $productId');
      }

      productList.add({
        'product': product,
        'productId': productId,
        'distance': distance,
      });
    }

    // Log summary statistics
    log(
      'Location summary: $farmersWithLocation farmers with location, $farmersWithoutLocation without location',
    );

    // Sort products by distance (closest first)
    productList.sort((a, b) => a['distance'].compareTo(b['distance']));

    // If no farmers have location, show a message but still return all products
    // This prevents returning an empty list when no locations are available
    if (farmersWithLocation == 0 && farmersWithoutLocation > 0) {
      log(
        'Warning: No farmers have location data. Distance-based sorting not possible.',
      );
    }

    return productList;
  }

  Future<List<Map<String, dynamic>>> sortFarmersByDistance(
    List<Map<String, dynamic>> farmers,
  ) async {
    final List<Map<String, dynamic>> farmerList = [];
    int farmersWithLocation = 0;
    int farmersWithoutLocation = 0;

    // Get user location
    Position? userLocation = await getUserLocation();

    if (userLocation == null) {
      log('User location unavailable, cannot sort by distance');
      // بدلاً من إرجاع قائمة فارغة، نعيد الحظائر بدون فرز حسب المسافة
      for (var farmer in farmers) {
        farmerList.add({...farmer, 'distance': double.infinity});
      }
      return farmerList;
    }

    log(
      'User location obtained: ${userLocation.latitude}, ${userLocation.longitude}',
    );

    // لكل حظيرة، نحاول الحصول على موقعها
    for (var farmer in farmers) {
      final farmerId = farmer['uid'] as String?;
      double distance = double.infinity;

      if (farmerId != null && farmerId.isNotEmpty) {
        try {
          // أولاً نبحث في المجموعة الفرعية location/current
          var farmerLocationDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(farmerId)
                  .collection('location')
                  .doc('current')
                  .get();

          // إذا لم نجد، نحاول التحقق مما إذا كان الموقع مخزنًا مباشرة في وثيقة المستخدم
          if (!farmerLocationDoc.exists) {
            final farmerDoc =
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(farmerId)
                    .get();

            if (farmerDoc.exists &&
                farmerDoc.data()!.containsKey('latitude') &&
                farmerDoc.data()!.containsKey('longitude')) {
              final farmerData = farmerDoc.data()!;
              final farmerLat = farmerData['latitude'] as double?;
              final farmerLng = farmerData['longitude'] as double?;

              if (farmerLat != null && farmerLng != null) {
                distance =
                    Geolocator.distanceBetween(
                      userLocation.latitude,
                      userLocation.longitude,
                      farmerLat,
                      farmerLng,
                    ) /
                    1000; // تحويل إلى كيلومترات
                farmersWithLocation++;
                log(
                  'Found location directly in user document for farmer $farmerId: $distance km',
                );
              }
            }
          } else {
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
                  1000; // تحويل إلى كيلومترات
              farmersWithLocation++;
              log(
                'Found location in subcollection for farmer $farmerId: $distance km',
              );
            }
          }

          if (distance == double.infinity) {
            farmersWithoutLocation++;
            log('No valid location data found for farmer $farmerId');
          }
        } catch (e) {
          log('Error fetching location for farmer $farmerId: $e');
        }
      } else {
        log('No farmerId for farmer');
      }

      farmerList.add({...farmer, 'distance': distance});
    }

    // تسجيل إحصائيات موجزة
    log(
      'Location summary: $farmersWithLocation farmers with location, $farmersWithoutLocation without location',
    );

    // فرز الحظائر حسب المسافة (الأقرب أولاً)
    farmerList.sort((a, b) => a['distance'].compareTo(b['distance']));

    // إذا لم يكن لدى أي حظيرة بيانات موقع، قم بعرض رسالة ولكن أعد كل الحظائر
    if (farmersWithLocation == 0 && farmersWithoutLocation > 0) {
      log(
        'Warning: No farmers have location data. Distance-based sorting not possible.',
      );
    }

    return farmerList;
  }
}
