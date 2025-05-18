import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hadaer_blady/core/errors/exeptions.dart';
import 'package:hadaer_blady/core/services/firebase_auth_service.dart';
import 'package:hadaer_blady/core/services/location_service.dart';

class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuthService _authService = FirebaseAuthService();

  // Upload profile image to Firebase Storage
  Future<String> uploadProfileImage(File image) async {
    try {
      final user = _authService.getCurrentUser();
      if (user == null) {
        throw CustomException(message: 'لم يتم تسجيل الدخول');
      }

      final storageRef = _storage.ref().child(
        'profile_images/${user.uid}/profile.jpg',
      );
      final uploadTask = await storageRef.putFile(image);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Update user document with new profile image URL
      await _firestore.collection('users').doc(user.uid).update({
        'profile_image_url': downloadUrl,
      });

      log('Profile image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      log('Error uploading profile image: $e');
      throw CustomException(message: 'حدث خطأ أثناء رفع الصورة');
    }
  }

  // Update user data
  Future<void> updateUserData({
    String? name,
    String? phone,
    String? address,
    String? city,
    String? profileImageUrl,
  }) async {
    try {
      final user = _authService.getCurrentUser();
      if (user == null) {
        throw CustomException(message: 'لم يتم تسجيل الدخول');
      }

      final updateData = <String, dynamic>{};
      if (name != null && _cleanInput(name).isNotEmpty) {
        updateData['name'] = _cleanInput(name);
      }
      if (phone != null && _cleanInput(phone).isNotEmpty) {
        updateData['phone'] = _cleanInput(phone);
      }
      if (address != null) {
        updateData['address'] = _cleanInput(address);
      }
      if (city != null) {
        updateData['city'] = _cleanInput(city);
      }
      if (profileImageUrl != null) {
        updateData['profile_image_url'] = _cleanInput(profileImageUrl);
      }

      if (updateData.isNotEmpty) {
        await _firestore.collection('users').doc(user.uid).update(updateData);
      }

      // تحديث بيانات الموقع
      final position = await LocationService().getUserLocation();
      if (position != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('location')
            .doc('current')
            .set({
              'latitude': position.latitude,
              'longitude': position.longitude,
              'timestamp': FieldValue.serverTimestamp(),
            });
        log(
          'Location updated for user ${user.uid}: lat=${position.latitude}, lng=${position.longitude}',
        );
      } else {
        log('No location data available for user ${user.uid}');
      }

      log('User data updated successfully for ID: ${user.uid}');
    } catch (e) {
      log('Unexpected error in updateUserData: $e');
      throw CustomException(message: 'حدث خطأ أثناء تحديث البيانات');
    }
  }

  // Helper to clean input strings
  String _cleanInput(String input) => input.trim();
}
