import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:hadaer_blady/core/errors/exeptions.dart';
import 'package:hadaer_blady/core/services/firebase_auth_service.dart';
import 'package:hadaer_blady/core/services/get_it.dart';
import 'package:hadaer_blady/core/services/shared_prefs_singleton.dart';
import 'package:hadaer_blady/core/services/user_profile_service.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final _firebaseAuthService = getIt<FirebaseAuthService>();
  final _userService = getIt<UserProfileService>();

  ProfileCubit() : super(ProfileInitial());

  Future<void> fetchUserData() async {
    try {
      // Check if we already have data in shared preferences
      if (_hasCompleteSharedPrefsData()) {
        // Construct userData map from SharedPreferences
        final userData = {
          'name': Prefs.getUserName(),
          'email': Prefs.getUserEmail(),
          'phone': Prefs.getUserPhone(),
          'city': Prefs.getUserCity(),
          'address': Prefs.getUserAddress(),
          'profile_image_url': Prefs.getProfileImageUrl(),
        };
        emit(ProfileLoaded(userData));
      } else {
        // Fetch from Firebase
        emit(ProfileLoading());
        final userData = await _firebaseAuthService.getCurrentUserData();

        // Save fetched data to SharedPreferences
        _saveUserDataToPrefs(userData);

        emit(ProfileLoaded(userData));
      }
    } catch (e) {
      emit(ProfileError('حدث خطأ أثناء جلب البيانات'));
    }
  }

  bool _hasCompleteSharedPrefsData() {
    // Check if we have the essential data in SharedPreferences
    final hasName =
        Prefs.getUserName().isNotEmpty && Prefs.getUserName() != 'User';
    final hasEmail = Prefs.getUserEmail().isNotEmpty;

    return hasName && hasEmail;
  }

  void _saveUserDataToPrefs(Map<String, dynamic> userData) {
    if (userData['name'] != null && userData['name'].toString().isNotEmpty) {
      Prefs.setUserName(userData['name'].toString());
    }

    if (userData['email'] != null && userData['email'].toString().isNotEmpty) {
      Prefs.setUserEmail(userData['email'].toString());
    }

    if (userData['phone'] != null && userData['phone'].toString().isNotEmpty) {
      Prefs.setUserPhone(userData['phone'].toString());
    }

    if (userData['city'] != null && userData['city'].toString().isNotEmpty) {
      Prefs.setUserCity(userData['city'].toString());
    }

    if (userData['address'] != null &&
        userData['address'].toString().isNotEmpty) {
      Prefs.setUserAddress(userData['address'].toString());
    }

    if (userData['profile_image_url'] != null &&
        userData['profile_image_url'].toString().isNotEmpty) {
      Prefs.setProfileImageUrl(userData['profile_image_url'].toString());
    }
  }

  Future<void> updateUserData({
    String? name,
    String? phone,
    String? city,
    String? address,
    File? profileImage,
  }) async {
    emit(ProfileLoading());
    try {
      String? profileImageUrl;

      // Upload image if a new one is selected
      if (profileImage != null) {
        profileImageUrl = await _userService.uploadProfileImage(profileImage);
      }

      // Update user data in Firebase - send empty strings to clear values if needed
      await _userService.updateUserData(
        name: name?.isNotEmpty == true ? name : null,
        phone: phone, // Send phone as-is, including empty string to clear
        city: city, // Send city as-is, including empty string to clear
        address: address, // Send address as-is, including empty string to clear
        profileImageUrl: profileImageUrl,
      );

      // Fetch the updated data
      final userData = await _firebaseAuthService.getCurrentUserData();

      // Update SharedPreferences with new values - always update these fields
      if (phone != null) Prefs.setUserPhone(phone);
      if (city != null) Prefs.setUserCity(city);
      if (address != null) Prefs.setUserAddress(address);
      if (profileImageUrl != null) Prefs.setProfileImageUrl(profileImageUrl);

      emit(ProfileUpdated(userData));
    } on CustomException catch (e) {
      emit(ProfileError(e.message));
    } catch (e) {
      emit(ProfileError('حدث خطأ أثناء تحديث البيانات: $e'));
    }
  }
}
