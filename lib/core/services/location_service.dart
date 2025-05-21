import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hadaer_blady/core/services/shared_prefs_singleton.dart';

class LocationService {
  Position? _cachedUserLocation;
  DateTime? _cacheTimestamp;
  static const Duration _cacheDuration = Duration(minutes: 5);

  // Validate latitude and longitude values
  bool _isValidCoordinate(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }

  // Get the user's current location, using stored location if available
  Future<Position?> getUserLocation({bool forceRefresh = false}) async {
    // Check SharedPreferences for stored location
    final storedLat = Prefs.getUserLatitude();
    final storedLng = Prefs.getUserLongitude();
    if (!forceRefresh && storedLat != null && storedLng != null) {
      if (!_isValidCoordinate(storedLat, storedLng)) {
        log('Invalid stored coordinates: lat=$storedLat, lng=$storedLng');
        return null;
      }
      log('Using stored location from SharedPreferences: $storedLat, $storedLng');
      return Position(
        latitude: storedLat,
        longitude: storedLng,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );
    }

    // Check if cached location is still valid
    if (!forceRefresh &&
        _cachedUserLocation != null &&
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!).inSeconds <
            _cacheDuration.inSeconds) {
      log('Using cached user location: ${_cachedUserLocation!.latitude}, ${_cachedUserLocation!.longitude}');
      return _cachedUserLocation;
    }

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
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!_isValidCoordinate(position.latitude, position.longitude)) {
        log('Invalid position coordinates: lat=${position.latitude}, lng=${position.longitude}');
        return null;
      }

      _cachedUserLocation = position;
      _cacheTimestamp = DateTime.now();
      // Save to SharedPreferences
      await Prefs.setUserLocation(position.latitude, position.longitude);
      // Save to Firestore
      await saveUserLocationToFirestore(position);
      log('User location saved to SharedPreferences: ${position.latitude}, ${position.longitude}');
      log('User location cached: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      log('Error getting location: $e');
      return null;
    }
  }

  // Prompt user for location permissions
  Future<bool> promptForLocationPermission(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تفعيل خدمات الموقع'),
            content: const Text(
              'خدمات الموقع غير مفعلة. يرجى تفعيلها لتحديد موقعك والاستفادة من ميزات التطبيق.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () async {
                  await Geolocator.openLocationSettings();
                  Navigator.pop(context);
                },
                child: const Text('فتح الإعدادات'),
              ),
            ],
          ),
        );
      }
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (context.mounted) {
          bool retry = false;
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('طلب إذن الموقع'),
              content: const Text(
                'هذا التطبيق يحتاج إلى إذن الموقع لتحديد موقعك. يرجى السماح بالوصول للمتابعة.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                TextButton(
                  onPressed: () {
                    retry = true;
                    Navigator.pop(context);
                  },
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
          if (retry && context.mounted) {
            permission = await Geolocator.requestPermission();
            if (permission == LocationPermission.denied) {
              return false;
            }
          } else {
            return false;
          }
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('إذن الموقع مرفوض نهائيًا'),
            content: const Text(
              'لقد رفضت إذن الموقع نهائيًا. يرجى السماح بالوصول من إعدادات التطبيق لتحديد موقعك.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () async {
                  await Geolocator.openAppSettings();
                  Navigator.pop(context);
                },
                child: const Text('فتح الإعدادات'),
              ),
            ],
          ),
        );
      }
      return false;
    }

    return true;
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

    log('User location obtained: ${userLocation.latitude}, ${userLocation.longitude}');

    // Collect unique farmer IDs
    final farmerIds = products
        .map((doc) => (doc.data() as Map<String, dynamic>)['farmer_id'] as String?)
        .where((id) => id != null && id.isNotEmpty)
        .toSet()
        .toList();

    // Batch fetch farmer locations
    final locationDocs = await Future.wait(
      farmerIds.map((farmerId) async {
        try {
          final locationDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(farmerId)
              .collection('location')
              .doc('current')
              .get();
          if (locationDoc.exists) {
            final data = locationDoc.data();
            log('Location data for farmer $farmerId: $data');
            return {'farmerId': farmerId, 'location': data};
          }
          final farmerDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(farmerId)
              .get();
          final data = farmerDoc.exists &&
                  farmerDoc.data()!.containsKey('latitude') &&
                  farmerDoc.data()!.containsKey('longitude')
              ? farmerDoc.data() as Map<String, dynamic>
              : null;
          log('Farmer doc data for $farmerId: $data');
          return {'farmerId': farmerId, 'location': data};
        } catch (e) {
          log('Error fetching location for farmer $farmerId: $e');
          return {'farmerId': farmerId, 'location': null};
        }
      }),
    );

    // Create a map for quick lookup of farmer locations
    final farmerLocations = <String, Map<String, dynamic>?>{
      for (var result in locationDocs)
        result['farmerId'] as String: result['location'] as Map<String, dynamic>?,
    };

    // Process products
    for (var doc in products) {
      final product = doc.data() as Map<String, dynamic>;
      final productId = doc.id;
      final farmerId = product['farmer_id'] as String?;
      double distance = double.infinity;

      if (farmerId != null &&
          farmerId.isNotEmpty &&
          farmerLocations[farmerId] != null) {
        final locationData = farmerLocations[farmerId]!;
        final farmerLat = locationData['latitude'] as double?;
        final farmerLng = locationData['longitude'] as double?;

        if (farmerLat != null &&
            farmerLng != null &&
            _isValidCoordinate(farmerLat, farmerLng)) {
          distance = Geolocator.distanceBetween(
                userLocation.latitude,
                userLocation.longitude,
                farmerLat,
                farmerLng,
              ) /
              1000; // Convert to kilometers
          farmersWithLocation++;
          log('Distance for farmer $farmerId (product $productId): $distance km');
        } else {
          farmersWithoutLocation++;
          log('No valid location data for farmer $farmerId (product $productId)');
        }
      } else {
        farmersWithoutLocation++;
        log('No farmerId or location data for product $productId');
      }

      productList.add({
        'product': product,
        'productId': productId,
        'distance': distance,
      });
    }

    log('Location summary: $farmersWithLocation farmers with location, $farmersWithoutLocation without location');

    // Sort products by distance (closest first)
    productList.sort((a, b) => a['distance'].compareTo(b['distance']));

    if (farmersWithLocation == 0 && farmersWithoutLocation > 0) {
      log('Warning: No farmers have valid location data. Distance-based sorting not possible.');
    }

    return productList;
  }

  // Sort farmers by distance
  Future<List<Map<String, dynamic>>> sortFarmersByDistance(
    List<Map<String, dynamic>> farmers,
    BuildContext context, // Added context for permission prompt
  ) async {
    final List<Map<String, dynamic>> farmerList = [];
    int farmersWithLocation = 0;
    int farmersWithoutLocation = 0;

    // Try to get user location with permission prompt
    bool locationPermissionGranted = await promptForLocationPermission(context);
    if (!locationPermissionGranted) {
      log('Location permission not granted, returning farmers without sorting');
      for (var farmer in farmers) {
        farmerList.add({...farmer, 'distance': double.infinity});
      }
      return farmerList;
    }

    // Get user location
    Position? userLocation = await getUserLocation();
    if (userLocation == null) {
      log('User location unavailable, cannot sort by distance');
      for (var farmer in farmers) {
        farmerList.add({...farmer, 'distance': double.infinity});
      }
      return farmerList;
    }

    log('User location obtained: ${userLocation.latitude}, ${userLocation.longitude}');

    // Collect unique farmer IDs
    final farmerIds = farmers
        .map((farmer) => farmer['uid'] as String?)
        .where((id) => id != null && id.isNotEmpty)
        .toSet()
        .toList();

    // Batch fetch farmer locations
    final locationDocs = await Future.wait(
      farmerIds.map((farmerId) async {
        try {
          final locationDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(farmerId)
              .collection('location')
              .doc('current')
              .get();
          if (locationDoc.exists) {
            final data = locationDoc.data();
            log('Location data for farmer $farmerId: $data');
            return {'farmerId': farmerId, 'location': data};
          }
          final farmerDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(farmerId)
              .get();
          final data = farmerDoc.exists &&
                  farmerDoc.data()!.containsKey('latitude') &&
                  farmerDoc.data()!.containsKey('longitude')
              ? farmerDoc.data() as Map<String, dynamic>
              : null;
          log('Farmer doc data for $farmerId: $data');
          return {'farmerId': farmerId, 'location': data};
        } catch (e) {
          log('Error fetching location for farmer $farmerId: $e');
          return {'farmerId': farmerId, 'location': null};
        }
      }),
    );

    // Create a map for quick lookup
    final farmerLocations = <String, Map<String, dynamic>?>{
      for (var result in locationDocs)
        result['farmerId'] as String: result['location'] as Map<String, dynamic>?,
    };

    // Process farmers
    for (var farmer in farmers) {
      final farmerId = farmer['uid'] as String?;
      double distance = double.infinity;

      if (farmerId != null &&
          farmerId.isNotEmpty &&
          farmerLocations[farmerId] != null) {
        final locationData = farmerLocations[farmerId]!;
        final farmerLat = locationData['latitude'] as double?;
        final farmerLng = locationData['longitude'] as double?;

        if (farmerLat != null &&
            farmerLng != null &&
            _isValidCoordinate(farmerLat, farmerLng)) {
          distance = Geolocator.distanceBetween(
                userLocation.latitude,
                userLocation.longitude,
                farmerLat,
                farmerLng,
              ) /
              1000; // Convert to kilometers
          farmersWithLocation++;
          log('Distance for farmer $farmerId: $distance km');
        } else {
          farmersWithoutLocation++;
          log('No valid location data for farmer $farmerId');
        }
      } else {
        farmersWithoutLocation++;
        log('No farmerId or location data for farmer');
      }

      farmerList.add({...farmer, 'distance': distance});
    }

    log('Location summary: $farmersWithLocation farmers with location, $farmersWithoutLocation without location');

    // Sort farmers by distance (closest first)
    farmerList.sort((a, b) => a['distance'].compareTo(b['distance']));

    if (farmersWithLocation == 0 && farmersWithoutLocation > 0) {
      log('Warning: No farmers have valid location data. Distance-based sorting not possible.');
    }

    return farmerList;
  }

  // Save user location to Firestore
  Future<void> saveUserLocationToFirestore(Position position) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        log('No authenticated user to save location');
        return;
      }

      if (!_isValidCoordinate(position.latitude, position.longitude)) {
        log('Invalid coordinates for Firestore: lat=${position.latitude}, lng=${position.longitude}');
        throw Exception('Invalid location coordinates');
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('location')
          .doc('current')
          .set({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });

      log('User location saved to Firestore: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      log('Error saving user location to Firestore: $e');
      throw Exception('Failed to save user location: $e');
    }
  }
}