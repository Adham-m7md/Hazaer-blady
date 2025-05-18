import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hadaer_blady/core/errors/exeptions.dart';
import 'package:hadaer_blady/core/services/location_service.dart';

class FarmerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get farmers
  Future<List<Map<String, dynamic>>> getFarmers() async {
    try {
      log('Fetching farmers from Firestore');
      final querySnapshot =
          await _firestore
              .collection('users')
              .where('job_title', isEqualTo: 'صاحب حظيرة')
              .get();

      final farmers =
          querySnapshot.docs.map((doc) {
            final data = doc.data();
            data['uid'] = doc.id;
            return data;
          }).toList();

      log('Fetched ${farmers.length} farmers successfully');
      return farmers;
    } catch (e) {
      log('Error fetching farmers: $e');
      throw CustomException(message: 'حدث خطأ أثناء جلب بيانات أصحاب المزارع');
    }
  }

  // Get farmer by ID
  Future<Map<String, dynamic>> getFarmerById(String id) async {
    try {
      final doc = await _firestore.collection('users').doc(id).get();
      if (!doc.exists) {
        throw CustomException(message: 'الحضيرة غير موجودة');
      }
      final data = doc.data()!;
      data['uid'] = doc.id;
      return data;
    } catch (e) {
      log('Error fetching farmer by ID: $e');
      throw CustomException(message: 'حدث خطأ أثناء جلب بيانات الحضيرة');
    }
  }

  // Update farmer location
  Future<void> updateFarmerLocation(String userId) async {
    try {
      final position = await LocationService().getUserLocation();
      if (position != null) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('location')
            .doc('current')
            .set({
              'latitude': position.latitude,
              'longitude': position.longitude,
              'timestamp': FieldValue.serverTimestamp(),
            });
        log(
          'Farmer location updated for user $userId: lat=${position.latitude}, lng=${position.longitude}',
        );
      } else {
        log('No location data available for farmer $userId');
        throw CustomException(message: 'تعذر الحصول على موقع التاجر');
      }
    } catch (e) {
      log('Error updating farmer location: $e');
      throw CustomException(message: 'حدث خطأ أثناء تحديث موقع التاجر');
    }
  }
}
