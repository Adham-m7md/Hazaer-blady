import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hadaer_blady/core/constants.dart';
import 'package:hadaer_blady/core/functions/build_app_bar_with_arrow_back_button.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/features/notfications/cubit/notfications_cubit.dart';
import 'package:hadaer_blady/features/notfications/cubit/notfications_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  static const String id = 'NotificationsScreen';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NotificationsCubit()..checkUnreadNotifications(),
      child: Scaffold(
        backgroundColor: AppColors.kWiteColor,
        appBar: buildAppBarWithArrowBackButton(
          title: 'الإشعارات',
          context: context,
        ),
        body: const NotficationsScreenBody(),
      ),
    );
  }
}

class NotficationsScreenBody extends StatelessWidget {
  const NotficationsScreenBody({super.key});

  @override
  Widget build(BuildContext context) {
    // التحقق من وجود مستخدم مسجل
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 64,
              color: AppColors.kGrayColor,
            ),
            SizedBox(height: 16),
            Text(
              'يجب تسجيل الدخول لرؤية الإشعارات',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.kGrayColor,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        const _NotificationsHeader(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            // استدعاء الإشعارات من subcollection الخاص بالمستخدم
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('notifications')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              // Loading state
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.kprimaryColor,
                  ),
                );
              }

              // Error state
              if (snapshot.hasError) {
                log('Error loading notifications: ${snapshot.error}');
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'حدث خطأ في تحميل الإشعارات',
                        style: TextStyles.semiBold16.copyWith(
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // إعادة تحميل الصفحة
                          Navigator.of(context).pushReplacementNamed(
                            NotificationsScreen.id,
                          );
                        },
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                );
              }

              // Empty state
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_off_outlined,
                        size: 64,
                        color: AppColors.kGrayColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد إشعارات',
                        style: TextStyles.semiBold16.copyWith(
                          color: AppColors.kGrayColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ستظهر هنا الإشعارات الخاصة بك',
                        style: TextStyles.semiBold13.copyWith(
                          color: AppColors.kGrayColor,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final notifications = snapshot.data!.docs;
              log('Loaded ${notifications.length} notifications for user: ${user.uid}');

              return RefreshIndicator(
                onRefresh: () async {
                  await context
                      .read<NotificationsCubit>()
                      .checkUnreadNotifications();
                },
                color: AppColors.kprimaryColor,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: notifications.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final doc = notifications[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isRead = data['isRead'] ?? false;

                    return NotificationItem(
                      notificationId: doc.id,
                      data: data,
                      isRead: isRead,
                      userId: user.uid, // إضافة userId للتعامل مع subcollection
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: khorizintalPadding,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: AppColors.kWiteColor,
            boxShadow: [
              BoxShadow(
                color: AppColors.kGrayColor.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDeleteAllButton(context, state),
              _buildMarkAllReadButton(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeleteAllButton(BuildContext context, NotificationsState state) {
    return GestureDetector(
      onTap: state.isLoading || !state.hasNotifications
          ? null
          : () async {
              final shouldDelete = await _showDeleteConfirmationDialog(context);
              if (shouldDelete == true && context.mounted) {
                context.read<NotificationsCubit>().deleteAllNotifications();
              }
            },
      child: Text(
        'حذف الكل',
        style: TextStyles.semiBold16.copyWith(
          color: state.isLoading || !state.hasNotifications
              ? AppColors.kGrayColor
              : Colors.red,
        ),
      ),
    );
  }

  Widget _buildMarkAllReadButton(
    BuildContext context,
    NotificationsState state,
  ) {
    if (state.isLoading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.kprimaryColor,
        ),
      );
    }

    return GestureDetector(
      onTap: state.hasUnreadNotifications
          ? () => context.read<NotificationsCubit>().markAllAsRead()
          : null,
      child: Text(
        state.hasUnreadNotifications ? 'تحديد الكل كمقروء' : 'الكل مقروء',
        style: TextStyles.semiBold16.copyWith(
          color: state.hasUnreadNotifications
              ? AppColors.kprimaryColor
              : AppColors.kGrayColor,
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.kWiteColor,
          title: const Text('تأكيد الحذف'),
          content: const Text('هل أنت متأكد من حذف جميع الإشعارات؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );
  }
}

class NotificationItem extends StatelessWidget {
  final String notificationId;
  final Map<String, dynamic> data;
  final bool isRead;
  final String userId; // إضافة userId

  const NotificationItem({
    super.key,
    required this.notificationId,
    required this.data,
    required this.isRead,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final String productId = data['productId'] ?? '';
    final String title = data['title'] ?? 'عرض جديد';
    final String description = data['description'] ?? '';
    final double price = _extractPrice(data);
    final Timestamp timestamp = data['createdAt'] ?? Timestamp.now();
    final String notificationType = data['type'] ?? 'new_product';

    return Material(
      color: isRead ? Colors.transparent : AppColors.kFillGrayColor,
      borderRadius: BorderRadius.circular(12),
      elevation: isRead ? 0 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onNotificationTap(context),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            border: isRead
                ? Border.all(
                    color: AppColors.kFillGrayColor.withOpacity(0.5),
                    width: 1,
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildNotificationIcon(isRead, notificationType),
              const SizedBox(width: 16),
              Expanded(
                child: _buildNotificationContent(
                  title,
                  description,
                  price,
                  timestamp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(bool isRead, String type) {
    IconData iconData;
    switch (type) {
      case 'new_product':
        iconData = Icons.local_offer;
        break;
      case 'order_update':
        iconData = Icons.shopping_cart;
        break;
      case 'general':
        iconData = Icons.notifications;
        break;
      default:
        iconData = Icons.local_offer;
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.lightPrimaryColor.withOpacity(0.1),
      ),
      padding: const EdgeInsets.all(4),
      child: Stack(
        children: [
          CircleAvatar(
            backgroundColor: Colors.transparent,
            radius: 28,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset(
                'assets/images/offer.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    iconData,
                    color: AppColors.kprimaryColor,
                    size: 32,
                  );
                },
              ),
            ),
          ),
          if (!isRead)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.kprimaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationContent(
    String title,
    String description,
    double price,
    Timestamp timestamp,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: isRead ? TextStyles.semiBold16 : TextStyles.bold16,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyles.semiBold13.copyWith(
              color: AppColors.kGrayColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (price > 0)
              Expanded(
                child: Text(
                  'السعر: ${price.toStringAsFixed(2)} دينار',
                  style: TextStyles.semiBold13.copyWith(
                    color: AppColors.kprimaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Text(
              _formatTimestamp(timestamp),
              style: TextStyles.semiBold13.copyWith(
                color: AppColors.kGrayColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _onNotificationTap(BuildContext context) {
    // تحديد الإشعار كمقروء
    _markAsRead();
    
    // التنقل إلى المنتج أو الصفحة المناسبة
    final productId = data['productId'] ?? '';
    if (productId.isNotEmpty) {
      context.read<NotificationsCubit>().onNotificationTap(
        context,
        notificationId,
        productId,
      );
    }
  }

  void _markAsRead() {
    if (!isRead) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true})
          .catchError((error) {
        log('Error marking notification as read: $error');
      });
    }
  }

  double _extractPrice(Map<String, dynamic> data) {
    // Try direct price field
    if (data['price'] is num) {
      return (data['price'] as num).toDouble();
    }

    if (data['price'] is String) {
      try {
        return double.parse(data['price']);
      } catch (e) {
        log('Error parsing price string: ${data['price']}');
      }
    }

    // Try extracting from description
    if (data['description'] is String) {
      final description = data['description'] as String;
      final priceRegex = RegExp(r'السعر:?\s*(\d+[.,]?\d*)');
      final match = priceRegex.firstMatch(description);
      if (match != null && match.groupCount >= 1) {
        try {
          final priceStr = match.group(1)!.replaceAll(',', '.');
          return double.parse(priceStr);
        } catch (e) {
          log('Error extracting price from description: $e');
        }
      }
    }

    return 0.0;
  }

  String _formatTimestamp(Timestamp timestamp) {
    try {
      final dateTime = timestamp.toDate();
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'الآن';
      } else if (difference.inMinutes < 60) {
        return 'منذ ${difference.inMinutes} دقيقة';
      } else if (difference.inHours < 24) {
        return 'منذ ${difference.inHours} ساعة';
      } else if (difference.inDays < 30) {
        return 'منذ ${difference.inDays} يوم';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      log('Error formatting timestamp: $e');
      return '';
    }
  }
}