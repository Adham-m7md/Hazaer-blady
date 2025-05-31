import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hadaer_blady/core/functions/show_snack_bar.dart';
import 'package:hadaer_blady/core/services/custom_product_servise.dart';
import 'package:hadaer_blady/core/services/get_it.dart';
import 'package:hadaer_blady/features/add_custom_product/presentation/custom_product_screen_details.dart';
import 'package:hadaer_blady/features/notfications/cubit/notfications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final CustomProductService _productService = getIt<CustomProductService>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  NotificationsCubit() : super(NotificationsState.initial()) {
    checkUnreadNotifications();
  }

  CollectionReference _getNotificationsRef() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications');
  }

  Future<void> checkUnreadNotifications() async {
    try {
      emit(state.copyWith(isLoading: true));
      final user = _auth.currentUser;
      if (user == null) {
        log('No authenticated user found');
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'يجب تسجيل الدخول لعرض الإشعارات',
          ),
        );
        return;
      }

      final query = await _getNotificationsRef().get();
      final hasNotifications = query.docs.isNotEmpty;
      final hasUnread = query.docs.any((doc) => !(doc['isRead'] ?? false));
      log(
        'Checked notifications: hasNotifications=$hasNotifications, hasUnread=$hasUnread',
      );
      emit(
        state.copyWith(
          hasUnreadNotifications: hasUnread,
          hasNotifications: hasNotifications,
          isLoading: false,
          errorMessage: null,
        ),
      );
    } catch (e) {
      log('Error checking notifications: $e');
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'حدث خطأ أثناء التحقق من الإشعارات',
        ),
      );
    }
  }

  Future<void> markAllAsRead() async {
    if (!state.hasUnreadNotifications) return;

    try {
      emit(state.copyWith(isLoading: true));
      final notifications =
          await _getNotificationsRef().where('isRead', isEqualTo: false).get();
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
      log(
        'All notifications marked as read for user: ${_auth.currentUser?.uid}',
      );
      emit(
        state.copyWith(
          hasUnreadNotifications: false,
          isLoading: false,
          errorMessage: null,
        ),
      );
    } catch (e) {
      log('Error marking all notifications as read: $e');
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'حدث خطأ أثناء تحديد الإشعارات كمقروءة',
        ),
      );
    }
  }

  Future<void> deleteAllNotifications() async {
    if (!state.hasNotifications) return;

    try {
      emit(state.copyWith(isLoading: true));
      final notifications = await _getNotificationsRef().get();
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in notifications.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      log('All notifications deleted for user: ${_auth.currentUser?.uid}');
      emit(
        state.copyWith(
          hasUnreadNotifications: false,
          hasNotifications: false,
          isLoading: false,
          errorMessage: null,
        ),
      );
    } catch (e) {
      log('Error deleting all notifications: $e');
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'حدث خطأ أثناء حذف الإشعارات',
        ),
      );
    }
  }

  Future<void> onNotificationTap(
    BuildContext context,
    String notificationId,
    String productId,
  ) async {
    if (productId.isEmpty) {
      showSnackBarMethode(context, 'معرف المنتج غير صالح');
      return;
    }

    try {
      // Mark the notification as read
      await _getNotificationsRef().doc(notificationId).update({'isRead': true});
      final product = await _productService.getProductById(productId);

      if (product == null) {
        showSnackBarMethode(context, 'المنتج غير موجود أو تم حذفه');
        return;
      }

      await Navigator.pushNamed(
        context,
        CustomProductDetailScreen.id,
        arguments: product,
      );
      // Recheck notifications after returning from product details
      await checkUnreadNotifications();
    } catch (e) {
      log('Error navigating to product details: $e');
      showSnackBarMethode(context, 'حدث خطأ أثناء تحميل تفاصيل المنتج');
    }
  }
}
