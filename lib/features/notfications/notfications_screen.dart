import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/constants.dart';
import 'package:hadaer_blady/core/functions/build_app_bar_with_arrow_back_button.dart';
import 'package:hadaer_blady/core/services/custom_product_servise.dart';
import 'package:hadaer_blady/core/services/get_it.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/features/add_custom_product/presentation/custom_product_screen_details.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  static const String id = 'NotificationsScreen';

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = false;
  bool _hasUnreadNotifications = false;
  final CollectionReference _notificationsRef = FirebaseFirestore.instance
      .collection('notifications');

  @override
  void initState() {
    super.initState();
    // Check if there are unread notifications when screen loads
    _checkUnreadNotifications();
  }

  // Check if there are any unread notifications
  Future<void> _checkUnreadNotifications() async {
    try {
      final query =
          await _notificationsRef
              .where('isRead', isEqualTo: false)
              .limit(1)
              .get();

      if (mounted) {
        setState(() {
          _hasUnreadNotifications = query.docs.isNotEmpty;
        });
      }
    } catch (e) {
      log('Error checking unread notifications: $e');
    }
  }

  // Mark all notifications as read
  Future<void> _markAllAsRead() async {
    if (!_hasUnreadNotifications) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final notifications =
          await _notificationsRef.where('isRead', isEqualTo: false).get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      if (mounted) {
        setState(() {
          _hasUnreadNotifications = false;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديد الكل كمقروء'),
            backgroundColor: AppColors.kprimaryColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        log('Error marking all notifications as read: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديد الكل كمقروء'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // استخراج قيمة السعر بشكل صحيح من البيانات
  double _extractPrice(Map<String, dynamic> data) {
    // التحقق من وجود السعر في الصيغ المختلفة
    if (data['price'] is num) {
      return (data['price'] as num).toDouble();
    } else if (data['price'] is String) {
      try {
        return double.parse(data['price']);
      } catch (e) {
        log('Error parsing price string: ${data['price']}');
      }
    }

    // محاولة استخراج السعر من الوصف إذا كان موجوداً
    if (data['description'] is String) {
      final description = data['description'] as String;
      // البحث عن نمط "السعر: X دينار" في الوصف
      final priceRegex = RegExp(r'السعر:?\s*(\d+[.,]?\d*)');
      final match = priceRegex.firstMatch(description);
      if (match != null && match.groupCount >= 1) {
        try {
          final priceStr = match.group(1)!.replaceAll(',', '.');
          return double.parse(priceStr);
        } catch (e) {
          log('Error extracting price from description');
        }
      }
    }

    // استخدام القيمة الافتراضية إذا تعذر استخراج السعر
    return 0.0;
  }

  // تنسيق الطابع الزمني لعرض الوقت المنقضي بطريقة ودية للمستخدم
  String _formatTimestamp(Timestamp timestamp) {
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
      // Format as date for older notifications
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kWiteColor,
      appBar: buildAppBarWithArrowBackButton(
        title: 'الإشعارات',
        context: context,
      ),
      body: Column(
        children: [
          // Header with "Mark all as read" button
          _buildHeader(),

          // Notifications list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  _notificationsRef
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.kprimaryColor,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
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
                      ],
                    ),
                  );
                }

                final notifications = snapshot.data!.docs;

                // Update unread status without calling setState to avoid rebuilds
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final hasUnread = notifications.any(
                    (doc) =>
                        (doc.data() as Map<String, dynamic>)['isRead'] == false,
                  );

                  if (hasUnread != _hasUnreadNotifications) {
                    setState(() {
                      _hasUnreadNotifications = hasUnread;
                    });
                  }
                });

                return RefreshIndicator(
                  onRefresh: () async {
                    await _checkUnreadNotifications();
                  },
                  color: AppColors.kprimaryColor,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final data =
                          notifications[index].data() as Map<String, dynamic>;
                      final isRead = data['isRead'] ?? false;
                      final String notificationId = notifications[index].id;

                      return isRead
                          ? _buildReadNotification(
                            notificationId: notificationId,
                            data: data,
                          )
                          : _buildUnreadNotification(
                            notificationId: notificationId,
                            data: data,
                          );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: khorizintalPadding,
        vertical: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(),
          _isLoading
              ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.kprimaryColor,
                ),
              )
              : GestureDetector(
                onTap: _hasUnreadNotifications ? _markAllAsRead : null,
                child: Text(
                  _hasUnreadNotifications ? 'تحديد الكل كمقروء' : 'الكل مقروء',
                  style: TextStyles.semiBold16.copyWith(
                    color:
                        _hasUnreadNotifications
                            ? AppColors.kprimaryColor
                            : AppColors.kFillGrayColor,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildUnreadNotification({
    required String notificationId,
    required Map<String, dynamic> data,
  }) {
    final String productId = data['productId'] ?? '';
    final String title = data['title'] ?? 'عرض جديد';
    final double price = _extractPrice(data);
    final Timestamp timestamp = data['createdAt'] ?? Timestamp.now();

    return Padding(
      padding: const EdgeInsets.only(top: 8, right: 12, left: 12),
      child: Material(
        color: AppColors.kFillGrayColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _onNotificationTap(notificationId, productId),
          child: Container(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Notification icon
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.lightPrimaryColor.withAlpha(20),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.transparent,
                        radius: 30,
                        child: Image.asset(
                          'assets/images/offer.png',
                          fit: BoxFit.cover,
                        ),
                      ),
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
                ),
                const SizedBox(width: 12),

                // Notification content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyles.bold16,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'السعر: ${price.toStringAsFixed(2)} دينار',
                            style: TextStyles.semiBold16.copyWith(
                              color: AppColors.kprimaryColor,
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadNotification({
    required String notificationId,
    required Map<String, dynamic> data,
  }) {
    final String productId = data['productId'] ?? '';
    final String title = data['title'] ?? 'عرض جديد';
    final double price = _extractPrice(data);
    final Timestamp timestamp = data['createdAt'] ?? Timestamp.now();

    return Padding(
      padding: const EdgeInsets.only(top: 8, right: 12, left: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _onNotificationTap(notificationId, productId),
          child: Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.kFillGrayColor.withOpacity(0.5),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.lightPrimaryColor.withAlpha(20),
                  radius: 30,
                  child: Image.asset(
                    'assets/images/offer.png',
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyles.semiBold16,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'السعر: ${price.toStringAsFixed(2)} دينار',
                            style: TextStyles.semiBold16.copyWith(
                              color: AppColors.kprimaryColor,
                            ),
                          ),
                          Text(
                            _formatTimestamp(timestamp),
                            style: TextStyles.semiBold13.copyWith(
                              color: AppColors.kFillGrayColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onNotificationTap(
    String notificationId,
    String productId,
  ) async {
    if (productId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('معرف المنتج غير صالح'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Optimistically mark notification as read
      await _notificationsRef.doc(notificationId).update({'isRead': true});

      // Fetch product data
      final productService = getIt<CustomProductService>();
      final product = await productService.getProductById(productId);

      if (product == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('المنتج غير موجود أو تم حذفه'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (mounted) {
        // Navigate to product details screen
        Navigator.pushNamed(
          context,
          CustomProductDetailScreen.id,
          arguments: product,
        );
      }
    } catch (e) {
      log('Error navigating to product details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء تحميل تفاصيل المنتج'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
