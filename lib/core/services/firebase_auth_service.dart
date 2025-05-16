import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hadaer_blady/core/errors/exeptions.dart';
import 'package:hadaer_blady/core/services/location_service.dart';
import 'package:hadaer_blady/core/services/shared_prefs_singleton.dart';

class FirebaseAuthService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Helper to clean input strings
  String _cleanInput(String input) => input.trim();

  // Helper to save user data to SharedPreferences
  Future<void> _saveUserToPrefs({
    required String name,
    required String email,
    String? phone,
    String? address,
    String? city,
    String? profileImageUrl,
    String? jobTitle,
  }) async {
    await Prefs.setUserName(name);
    await Prefs.setUserEmail(email);
    if (phone != null) await Prefs.setUserPhone(phone);
    if (address != null) await Prefs.setUserAddress(address);
    if (city != null) await Prefs.setUserCity(city);
    if (profileImageUrl != null) {
      await Prefs.setProfileImageUrl(profileImageUrl);
    }
    log(
      'Saved to Prefs: name=$name, email=$email, phone=$phone, address=$address, city=$city, profileImageUrl=$profileImageUrl',
    );
  }

  // Helper to handle FirebaseAuthException
  CustomException _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return CustomException(message: 'الرقم السري ضعيف');
      case 'email-already-in-use':
        return CustomException(message: 'البريد الإلكتروني موجود بالفعل');
      case 'network-request-failed':
        return CustomException(message: 'تأكد من اتصالك بالإنترنت');
      case 'invalid-email':
        return CustomException(message: 'البريد الإلكتروني غير صحيح');
      case 'user-not-found':
        return CustomException(message: 'البريد الإلكتروني غير موجود');
      case 'wrong-password':
        return CustomException(message: 'كلمة المرور غير صحيحة');
      case 'invalid-credential':
        return CustomException(
          message: 'البريد الإلكتروني أو كلمة المرور غير صحيحة',
        );
      case 'requires-recent-login':
        return CustomException(
          message: 'تسجيل الدخول قديم، الرجاء تسجيل الخروج وإعادة تسجيل الدخول',
        );
      default:
        return CustomException(message: 'حدث خطأ ما، الرجاء المحاولة مرة أخرى');
    }
  }

  // Upload profile image to Firebase Storage
  Future<String> uploadProfileImage(File image) async {
    try {
      final user = auth.currentUser;
      if (user == null) {
        throw CustomException(message: 'لم يتم تسجيل الدخول');
      }

      final storageRef = _storage.ref().child(
        'profile_images/${user.uid}/profile.jpg',
      );
      final uploadTask = await storageRef.putFile(image);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      await Prefs.setProfileImageUrl(downloadUrl);
      log('Profile image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      log('Error uploading profile image: $e');
      throw CustomException(message: 'حدث خطأ أثناء رفع الصورة');
    }
  }

  // Create a new user
  Future<User> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String jobTitle,
    String? address,
    String? city,
    double? rating,
    int? reviews,
    int? offers,
    String? profileImageUrl,
  }) async {
    try {
      final cleanEmail = _cleanInput(email);
      final cleanName =
          _cleanInput(name).isNotEmpty ? _cleanInput(name) : 'Unnamed User';
      final cleanPhone = _cleanInput(phone);
      final cleanAddress = _cleanInput(address ?? '');
      final cleanCity = _cleanInput(city ?? '');
      final cleanProfileImageUrl = _cleanInput(profileImageUrl ?? '');

      log('Creating user with email: $cleanEmail');
      final credential = await auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        // تسجيل بيانات المستخدم الأساسية
        await firestore.collection('users').doc(user.uid).set({
          'name': cleanName,
          'phone': cleanPhone,
          'email': cleanEmail,
          'job_title': jobTitle,
          'address': cleanAddress.isEmpty ? null : cleanAddress,
          'city': cleanCity.isEmpty ? null : cleanCity,
          'profile_image_url': cleanProfileImageUrl,
          'rating': rating ?? 0.0,
          'reviews': reviews ?? 0,
          'offers': offers ?? 0,
          'created_at': FieldValue.serverTimestamp(),
        });

        // تسجيل بيانات الموقع في subcollection
        final position = await LocationService().getUserLocation();
        if (position != null) {
          await firestore
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
            'Location saved for user ${user.uid}: lat=${position.latitude}, lng=${position.longitude}',
          );
        } else {
          log('No location data available for user ${user.uid}');
        }

        await _saveUserToPrefs(
          name: cleanName,
          email: cleanEmail,
          phone: cleanPhone,
          address: cleanAddress,
          city: cleanCity,
          profileImageUrl: cleanProfileImageUrl,
        );
        log('User created successfully with ID: ${user.uid}');
      }

      return user!;
    } on FirebaseAuthException catch (e) {
      log('Exception in createUserWithEmailAndPassword: $e');
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      log('Unexpected error in createUserWithEmailAndPassword: $e');
      throw CustomException(message: 'حدث خطأ ما، الرجاء المحاولة مرة أخرى');
    }
  }

  // Sign in with email or phone
  Future<User> signInWithEmailOrPhone({
    required String emailOrPhone,
    required String password,
  }) async {
    try {
      final cleanInput = _cleanInput(emailOrPhone);
      final isEmail = cleanInput.contains('@');
      log(
        'Attempting to sign in with ${isEmail ? "email" : "phone"}: $cleanInput',
      );

      if (isEmail) {
        return await _signInWithEmail(cleanInput, password);
      } else {
        return await _signInWithPhone(cleanInput, password);
      }
    } on FirebaseAuthException catch (e) {
      log('FirebaseAuthException in signInWithEmailOrPhone: $e');
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      log('Unexpected error in signInWithEmailOrPhone: $e');
      throw CustomException(message: 'حدث خطأ ما، الرجاء المحاولة مرة أخرى');
    }
  }

  // Sign in with email
  Future<User> _signInWithEmail(String email, String password) async {
    final credential = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user!;
    final userDoc = await firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};
    final userName = userData['name'] as String? ?? 'User';
    final userEmail = userData['email'] as String? ?? email;
    final userPhone = userData['phone'] as String? ?? '';
    final userAddress = userData['address'] as String? ?? '';
    final userCity = userData['city'] as String? ?? '';
    final userProfileImageUrl = userData['profile_image_url'] as String? ?? '';

    await _saveUserToPrefs(
      name: userName,
      email: userEmail,
      phone: userPhone,
      address: userAddress,
      city: userCity,
      profileImageUrl: userProfileImageUrl,
    );
    log('Sign in successful with email');
    return user;
  }

  // Sign in with phone
  Future<User> _signInWithPhone(String phone, String password) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    log('Searching for user with phone: "$cleanPhone"');

    final userEmail = await _findUserEmailByPhone(cleanPhone, phone);
    if (userEmail == null) {
      log('No user found with this phone number');
      throw CustomException(message: 'لا يوجد مستخدم بهذا الرقم');
    }

    final credential = await auth.signInWithEmailAndPassword(
      email: userEmail,
      password: password,
    );

    final user = credential.user!;
    final userDoc = await firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};
    final userName = userData['name'] as String? ?? 'User';
    final userPhone = userData['phone'] as String? ?? '';
    final userAddress = userData['address'] as String? ?? '';
    final userCity = userData['city'] as String? ?? '';
    final userProfileImageUrl = userData['profile_image_url'] as String? ?? '';

    await _saveUserToPrefs(
      name: userName,
      email: userEmail,
      phone: userPhone,
      address: userAddress,
      city: userCity,
      profileImageUrl: userProfileImageUrl,
    );
    log('User found with email: $userEmail');
    return user;
  }

  // Find user email by phone
  Future<String?> _findUserEmailByPhone(
    String cleanPhone,
    String originalPhone,
  ) async {
    var querySnapshot =
        await firestore
            .collection('users')
            .where('phone', isEqualTo: originalPhone)
            .limit(1)
            .get();

    if (querySnapshot.docs.isEmpty && originalPhone != cleanPhone) {
      querySnapshot =
          await firestore
              .collection('users')
              .where('phone', isEqualTo: cleanPhone)
              .limit(1)
              .get();
    }

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.data()['email'] as String;
    }

    log('No exact match found, trying partial search');
    final allUsers = await firestore.collection('users').get();
    for (var doc in allUsers.docs) {
      final storedPhone = doc.data()['phone'] as String? ?? '';
      final cleanStoredPhone = storedPhone.replaceAll(RegExp(r'[^\d]'), '');

      if (cleanStoredPhone.contains(cleanPhone) ||
          cleanPhone.contains(cleanStoredPhone)) {
        return doc.data()['email'] as String;
      }
    }

    return null;
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
      final user = auth.currentUser;
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
        await firestore.collection('users').doc(user.uid).update(updateData);
      }

      // تحديث بيانات الموقع
      final position = await LocationService().getUserLocation();
      if (position != null) {
        await firestore
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

      await _saveUserToPrefs(
        name: name ?? Prefs.getUserName(),
        email: await getCurrentUserEmail(),
        phone: phone,
        address: address,
        city: city,
        profileImageUrl: profileImageUrl,
      );
      log('User data updated successfully for ID: ${user.uid}');
    } catch (e) {
      log('Unexpected error in updateUserData: $e');
      throw CustomException(message: 'حدث خطأ أثناء تحديث البيانات');
    }
  } // Reset password

  Future<void> resetPassword({required String email}) async {
    try {
      final cleanEmail = _cleanInput(email);
      log('Checking if email exists: $cleanEmail');

      final querySnapshot =
          await firestore
              .collection('users')
              .where('email', isEqualTo: cleanEmail)
              .limit(1)
              .get();

      if (querySnapshot.docs.isEmpty) {
        log('Email not found in Firestore: $cleanEmail');
        throw CustomException(message: 'البريد الإلكتروني غير موجود');
      }

      await auth.sendPasswordResetEmail(email: cleanEmail);
      log('Password reset email sent successfully');
    } on FirebaseAuthException catch (e) {
      log('FirebaseAuthException in resetPassword: $e');
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      log('Unexpected error in resetPassword: $e');
      throw CustomException(message: 'حدث خطأ ما، الرجاء المحاولة مرة أخرى');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await auth.signOut();
      await Prefs.clearAllUserData();
      log('User signed out successfully');
    } catch (e) {
      log('Error signing out: $e');
      throw CustomException(message: 'حدث خطأ أثناء تسجيل الخروج');
    }
  }

  // Get current user
  User? getCurrentUser() => auth.currentUser;

  // Get farmers
  Future<List<Map<String, dynamic>>> getFarmers() async {
    try {
      log('Fetching farmers from Firestore');
      final querySnapshot =
          await firestore
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
      final doc = await firestore.collection('users').doc(id).get();
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

  // Check if user is logged in
  bool isUserLoggedIn() => auth.currentUser != null;

  // Get current user name
  Future<String> getCurrentUserName() async {
    try {
      final name = Prefs.getUserName();
      if (name != 'User') return name;

      final user = getCurrentUser();
      if (user == null) return 'User';

      final doc = await firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return 'User';

      final fetchedName = doc.data()?['name'] as String? ?? 'User';
      await Prefs.setUserName(fetchedName);
      return fetchedName;
    } catch (e) {
      log('Error getting user name: $e');
      return 'User';
    }
  }

  // Get current user email
  Future<String> getCurrentUserEmail() async {
    try {
      final email = Prefs.getUserEmail();
      if (email.isNotEmpty) return email;

      final user = getCurrentUser();
      if (user == null) return '';

      final userEmail = user.email;
      if (userEmail != null && userEmail.isNotEmpty) {
        await Prefs.setUserEmail(userEmail);
        return userEmail;
      }

      final doc = await firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return '';

      final fetchedEmail = doc.data()?['email'] as String? ?? '';
      await Prefs.setUserEmail(fetchedEmail);
      return fetchedEmail;
    } catch (e) {
      log('Error getting user email: $e');
      return '';
    }
  }

  // Get current user data
  Future<Map<String, dynamic>> getCurrentUserData() async {
    try {
      final user = getCurrentUser();
      if (user == null) {
        return {
          'name': Prefs.getUserName(),
          'email': Prefs.getUserEmail(),
          'phone': Prefs.getUserPhone(),
          'address': Prefs.getUserAddress(),
          'city': Prefs.getUserCity(),
          'profile_image_url': Prefs.getProfileImageUrl(),
          'job_title': Prefs.getJobTitle(),
        };
      }

      final doc = await firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        return {
          'name': Prefs.getUserName(),
          'email': Prefs.getUserEmail(),
          'phone': Prefs.getUserPhone(),
          'address': Prefs.getUserAddress(),
          'city': Prefs.getUserCity(),
          'profile_image_url': Prefs.getProfileImageUrl(),
          'job_title': Prefs.getJobTitle(),
        };
      }

      final data = doc.data() ?? {};
      await _saveUserToPrefs(
        name: data['name'] as String? ?? 'User',
        email: data['email'] as String? ?? '',
        phone: data['phone'] as String? ?? '',
        address: data['address'] as String? ?? '',
        city: data['city'] as String? ?? '',
        profileImageUrl: data['profile_image_url'] as String? ?? '',
        jobTitle: data['job_title'] as String? ?? '',
      );
      return data;
    } catch (e) {
      log('Error getting user data: $e');
      return {
        'name': Prefs.getUserName(),
        'email': Prefs.getUserEmail(),
        'phone': Prefs.getUserPhone(),
        'address': Prefs.getUserAddress(),
        'city': Prefs.getUserCity(),
        'profile_image_url': Prefs.getProfileImageUrl(),
        'job_title': Prefs.getJobTitle(),
      };
    }
  }

  // Delete user account
  Future<void> deleteUserAccount({required String password}) async {
    try {
      final user = auth.currentUser;
      if (user == null || user.email == null) {
        throw CustomException(message: 'لم يتم تسجيل الدخول');
      }

      log('Attempting to delete user account for: ${user.email}');
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      await firestore.collection('users').doc(user.uid).delete();
      await user.delete();
      await Prefs.clearAllUserData();
      log('User account deleted from Firebase Auth');
    } on FirebaseAuthException catch (e) {
      log('Firebase Auth Exception in deleteUserAccount: $e');
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      log('Unexpected error in deleteUserAccount: $e');
      throw CustomException(message: 'حدث خطأ ما، الرجاء المحاولة مرة أخرى');
    }
  }

  Future<void> updateFarmerLocation(String userId) async {
    try {
      final position = await LocationService().getUserLocation();
      if (position != null) {
        await firestore
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
