import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  static late SharedPreferences _instance;
  static final ValueNotifier<String> profileImageNotifier = ValueNotifier('');

  // Initialize SharedPreferences and set initial notifier value
  static Future<void> init() async {
    _instance = await SharedPreferences.getInstance();
    profileImageNotifier.value = getProfileImageUrl(); // Set initial value
  }

  // Generic method to set a boolean value
  static Future<void> setBool(String key, bool value) async {
    await _instance.setBool(key, value);
  }

  // Generic method to get a boolean value
  static bool getBool(String key) {
    return _instance.getBool(key) ?? false;
  }

  // Save user name to SharedPreferences
  static Future<void> setUserName(String userName) async {
    await _instance.setString('user_name', userName);
  }

  // Retrieve user name from SharedPreferences
  static String getUserName() {
    return _instance.getString('user_name') ?? 'User';
  }

  // Clear user name from SharedPreferences
  static Future<void> clearUserName() async {
    await _instance.remove('user_name');
  }

  // Save user email to SharedPreferences
  static Future<void> setUserEmail(String userEmail) async {
    await _instance.setString('user_email', userEmail);
  }

  // Retrieve user email from SharedPreferences
  static String getUserEmail() {
    return _instance.getString('user_email') ?? '';
  }

  // Clear user email from SharedPreferences
  static Future<void> clearUserEmail() async {
    await _instance.remove('user_email');
  }

  // Save phone to SharedPreferences
  static Future<void> setUserPhone(String phone) async {
    await _instance.setString('user_phone', phone);
  }

  // Retrieve phone from SharedPreferences
  static String getUserPhone() {
    return _instance.getString('user_phone') ?? '';
  }

  // Clear phone from SharedPreferences
  static Future<void> clearUserPhone() async {
    await _instance.remove('user_phone');
  }

  // Save address to SharedPreferences
  static Future<void> setUserAddress(String address) async {
    await _instance.setString('user_address', address);
  }

  // Retrieve address from SharedPreferences
  static String getUserAddress() {
    return _instance.getString('user_address') ?? '';
  }

  // Clear address from SharedPreferences
  static Future<void> clearUserAddress() async {
    await _instance.remove('user_address');
  }

  // Save city to SharedPreferences
  static Future<void> setUserCity(String city) async {
    await _instance.setString('user_city', city);
  }

  // Retrieve city from SharedPreferences
  static String getUserCity() {
    return _instance.getString('user_city') ?? '';
  }

  // Clear city from SharedPreferences
  static Future<void> clearUserCity() async {
    await _instance.remove('user_city');
  }

  // Save profile image URL to SharedPreferences and update notifier
  static Future<void> setProfileImageUrl(String imageUrl) async {
    await _instance.setString('profile_image_url', imageUrl);
    profileImageNotifier.value = imageUrl; // Update the notifier
  }

  // Retrieve profile image URL from SharedPreferences
  static String getProfileImageUrl() {
    return _instance.getString('profile_image_url') ?? '';
  }

  // Clear profile image URL from SharedPreferences and update notifier
  static Future<void> clearProfileImageUrl() async {
    await _instance.remove('profile_image_url');
    profileImageNotifier.value = ''; // Update the notifier
  }

  // Save job title to SharedPreferences
  static Future<void> setJobTitle(String jobTitle) async {
    await _instance.setString('job_title', jobTitle);
  }

  // Retrieve job title from SharedPreferences
  static String getJobTitle() {
    return _instance.getString('job_title') ?? '';
  }

  // Clear job title from SharedPreferences
  static Future<void> clearJobTitle() async {
    await _instance.remove('job_title');
  }

  // Save user location (latitude and longitude) to SharedPreferences
  static Future<void> setUserLocation(double latitude, double longitude) async {
    await _instance.setDouble('user_latitude', latitude);
    await _instance.setDouble('user_longitude', longitude);
  }

  // Retrieve user latitude from SharedPreferences
  static double? getUserLatitude() {
    return _instance.getDouble('user_latitude');
  }

  // Retrieve user longitude from SharedPreferences
  static double? getUserLongitude() {
    return _instance.getDouble('user_longitude');
  }

  // Clear user location from SharedPreferences
  static Future<void> clearUserLocation() async {
    await _instance.remove('user_latitude');
    await _instance.remove('user_longitude');
  }

  // Clear all user data from SharedPreferences
  static Future<void> clearAllUserData() async {
    await clearUserName();
    await clearUserEmail();
    await clearUserPhone();
    await clearUserAddress();
    await clearUserCity();
    await clearProfileImageUrl();
    await clearJobTitle();
    await clearUserLocation();
  }
}
