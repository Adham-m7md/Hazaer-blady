import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hadaer_blady/core/errors/exeptions.dart';
import 'package:hadaer_blady/core/services/shared_prefs_singleton.dart';

class FirebaseAuthService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

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
    if (jobTitle != null) {
      await Prefs.setJobTitle(jobTitle);
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

  Future<String?> _getFCMToken() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // طلب إذن بالإشعارات (مطلوب في iOS و Android 13+)
    NotificationSettings settings = await messaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // الحصول على التوكن
      String? token = await messaging.getToken();
      print("FCM Token: $token");
      return token;
      // ممكن تخزن التوكن في Firebase Firestore أو Realtime DB حسب احتياجك
    } else {
      print('لم يتم السماح بالإشعارات');
      throw 'لم يتم السماح بالإشعارات';
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
        // إرسال رابط تأكيد البريد الإلكتروني
        if (!user.emailVerified) {
          await user.sendEmailVerification();
          log('Verification email sent to: $cleanEmail');
        }

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
          'email_verified': false,
          'fcm_token': await _getFCMToken(),
        });

        // Removed location saving logic
        log(
          'User created successfully without location data for ID: ${user.uid}',
        );

        await _saveUserToPrefs(
          name: cleanName,
          email: cleanEmail,
          phone: cleanPhone,
          address: cleanAddress,
          city: cleanCity,
          profileImageUrl: cleanProfileImageUrl,
          jobTitle: jobTitle,
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

  // Resend email verification
  Future<void> resendEmailVerification() async {
    try {
      final user = auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        log('Verification email resent to: ${user.email}');
      } else if (user == null) {
        throw CustomException(message: 'لم يتم تسجيل الدخول');
      } else {
        throw CustomException(message: 'البريد الإلكتروني تم تأكيده بالفعل');
      }
    } on FirebaseAuthException catch (e) {
      log('FirebaseAuthException in resendEmailVerification: $e');
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      log('Unexpected error in resendEmailVerification: $e');
      throw CustomException(message: 'حدث خطأ ما، الرجاء المحاولة مرة أخرى');
    }
  }

  // Check email verification status
  Future<bool> checkEmailVerification() async {
    try {
      final user = auth.currentUser;
      if (user != null) {
        await user.reload();
        if (user.emailVerified) {
          await firestore.collection('users').doc(user.uid).update({
            'email_verified': true,
          });
          log('Email verification status updated for user: ${user.uid}');
          return true;
        }
        return false;
      }
      throw CustomException(message: 'لم يتم تسجيل الدخول');
    } catch (e) {
      log('Error checking email verification: $e');
      throw CustomException(message: 'حدث خطأ أثناء التحقق من حالة التأكيد');
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

      User user;
      if (isEmail) {
        user = await _signInWithEmail(cleanInput, password);
      } else {
        user = await _signInWithPhone(cleanInput, password);
      }

      // التحقق من تأكيد البريد الإلكتروني
      await user.reload();
      if (!user.emailVerified) {
        log('Email not verified for user: ${user.email}');
        throw CustomException(message: 'يرجى تأكيد بريدك الإلكتروني أولاً');
      }

      return user;
    } on FirebaseAuthException catch (e) {
      log('FirebaseAuthException in signInWithEmailOrPhone: $e');
      throw _handleFirebaseAuthException(e);
    } on CustomException catch (e) {
      log('CustomException in signInWithEmailOrPhone: $e');
      rethrow;
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
    final userJobTitle = userData['job_title'] as String? ?? '';

    await _saveUserToPrefs(
      name: userName,
      email: userEmail,
      phone: userPhone,
      address: userAddress,
      city: userCity,
      profileImageUrl: userProfileImageUrl,
      jobTitle: userJobTitle,
    );

    // ✅ تحديث FCM token يدويًا مباشرة بعد تسجيل الدخول
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': token});
        log('✅ FCM token updated manually: $token');
      } else {
        log('⚠️ Failed to get FCM token.');
      }
    } catch (e) {
      log('❌ Error updating FCM token: $e');
    }

    // ✅ إضافة مستمع للتحديث المستقبلي
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'fcmToken': newToken},
      );
      log('🔄 FCM token refreshed: $newToken');
    });

    log('✅ Sign in successful with email');
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
    final userJobTitle = userData['job_title'] as String? ?? '';

    await _saveUserToPrefs(
      name: userName,
      email: userEmail,
      phone: userPhone,
      address: userAddress,
      city: userCity,
      profileImageUrl: userProfileImageUrl,
      jobTitle: userJobTitle,
    );
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': token});
        log('✅ FCM token updated manually: $token');
      } else {
        log('⚠️ Failed to get FCM token.');
      }
    } catch (e) {
      log('❌ Error updating FCM token: $e');
    }

    // ✅ إضافة مستمع للتحديث المستقبلي
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'fcmToken': newToken},
      );
      log('🔄 FCM token refreshed: $newToken');
    });
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

  // Reset password
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

  // void _listenToFCMTokenRefresh() {
  //   FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
  //     final userId = FirebaseAuth.instance.currentUser?.uid;
  //     if (userId != null) {
  //       await FirebaseFirestore.instance.collection('users').doc(userId).update(
  //         {'fcm_token': newToken},
  //       );
  //       log('FCM token updated: $newToken');
  //     } else {
  //       print('No user logged in to update FCM token.');
  //     }
  //   });
  // }

  Future<bool> isEmailVerified() async {
    try {
      final user = auth.currentUser;
      if (user == null) {
        log('No user logged in to check email verification');
        return false;
      }

      // إعادة تحميل بيانات المستخدم للحصول على أحدث حالة
      await user.reload();

      log('Email verification status for ${user.email}: ${user.emailVerified}');
      return user.emailVerified;
    } catch (e) {
      log('Error checking email verification status: $e');
      return false;
    }
  }
}
