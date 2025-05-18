import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hadaer_blady/core/constants.dart';
import 'package:hadaer_blady/core/functions/build_app_bar_with_arrow_back_button.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/core/utils/svg_images.dart';
import 'package:intl/intl.dart'; // لتنسيق التاريخ

class MyOrders extends StatelessWidget {
  const MyOrders({super.key});
  static const String id = 'MyOrders';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.kWiteColor,
        appBar: buildAppBarWithArrowBackButton(
          title: 'مشترياتي',
          context: context,
        ),
        body: const Center(
          child: Text(
            'يرجى تسجيل الدخول لعرض الطلبات',
            style: TextStyles.semiBold16,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.kWiteColor,
      appBar: buildAppBarWithArrowBackButton(
        title: 'مشترياتي',
        context: context,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: khorizintalPadding),
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('orders')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'خطأ: ${snapshot.error}',
                  style: TextStyles.semiBold16.copyWith(
                    color: AppColors.kRedColor,
                  ),
                ),
              );
            }

            final orders = snapshot.data?.docs ?? [];

            if (orders.isEmpty) {
              return const Center(
                child: Text(
                  ' ليس لديك مشتريات, قم بالتسوق الأن !',
                  style: TextStyles.semiBold16,
                ),
              );
            }

            return SingleChildScrollView(
              child: Column(
                spacing: 12,
                children: [
                  const SizedBox(height: 8),
                  ...orders.map((doc) {
                    final orderData = doc.data() as Map<String, dynamic>;
                    return CustomOrder(orderId: doc.id, orderData: orderData);
                  }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class CustomOrder extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  const CustomOrder({
    super.key,
    required this.orderId,
    required this.orderData,
  });

  @override
  Widget build(BuildContext context) {
    final cartItems = orderData['cartItems'] as List<dynamic>? ?? [];
    final userData = orderData['userData'] as Map<String, dynamic>? ?? {};
    final timestamp = (orderData['timestamp'] as Timestamp?)?.toDate();
    final status = orderData['status'] as String? ?? 'غير معروف';
    final totalPrice = cartItems.fold<double>(
      0,
      (sum, item) => sum + (item['totalPrice'] as num).toDouble(),
    );
    final itemCount = cartItems.length;
    final formattedDate =
        timestamp != null
            ? DateFormat('dd MMMM yyyy', 'ar').format(timestamp)
            : 'غير متوفر';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.kFillGrayColor,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: khorizintalPadding),
        childrenPadding: const EdgeInsets.all(khorizintalPadding),
        backgroundColor: AppColors.kFillGrayColor,
        collapsedBackgroundColor: AppColors.kFillGrayColor,
        iconColor: AppColors.kGrayColor,
        collapsedIconColor: AppColors.kGrayColor,
        leading: SvgPicture.asset(Assets.imagesOrder),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              'طلب رقم: $orderId',
              style: TextStyles.bold13,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text('تم الطلب: $formattedDate', style: TextStyles.semiBold13),
            const SizedBox(height: 4),
            Text(
              'عدد الطلبات: $itemCount    $totalPrice دينار',
              style: TextStyles.semiBold13,
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_drop_down_outlined, size: 32),
        children: [
          const Divider(color: AppColors.kGrayColor, thickness: 0.4),
          // Order Items
          Text(
            'المنتجات:',
            style: TextStyles.bold16.copyWith(color: AppColors.kprimaryColor),
          ),
          const SizedBox(height: 8),
          ...cartItems.map((item) {
            final productData = item['productData'] as Map<String, dynamic>;
            final quantity = item['quantity'] as int? ?? 1;
            final itemTotalPrice = (item['totalPrice'] as num).toDouble();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${productData['name'] ?? 'منتج غير معروف'} (x$quantity)',
                      style: TextStyles.semiBold13,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text('$itemTotalPrice دينار', style: TextStyles.semiBold13),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          // User Data
          Text(
            'بيانات التوصيل:',
            style: TextStyles.bold13.copyWith(color: AppColors.kprimaryColor),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person, color: AppColors.kGrayColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'الاسم: ${userData['name'] ?? 'غير متوفر'}',
                  style: TextStyles.semiBold13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.phone, color: AppColors.kGrayColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'رقم الهاتف: ${userData['phone'] ?? 'غير متوفر'}',
                  style: TextStyles.semiBold13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.location_city,
                color: AppColors.kGrayColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'المدينة: ${userData['city'] ?? 'غير متوفر'}',
                  style: TextStyles.semiBold13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: AppColors.kGrayColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'العنوان: ${userData['address'] ?? 'غير متوفر'}',
                  style: TextStyles.semiBold13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Order Status
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.kGrayColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text('الحالة: $status', style: TextStyles.semiBold13),
            ],
          ),
        ],
      ),
    );
  }
}
