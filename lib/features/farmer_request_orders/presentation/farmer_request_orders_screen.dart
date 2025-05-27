import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hadaer_blady/core/constants.dart';
import 'package:hadaer_blady/core/functions/build_app_bar_with_arrow_back_button.dart';
import 'package:hadaer_blady/core/services/farmer_request_order_service.dart';
import 'package:hadaer_blady/core/services/notfications_service.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/core/utils/svg_images.dart';
import 'package:hadaer_blady/core/widgets/custom_loading_indicator.dart';
import 'package:intl/intl.dart';

enum OrderStatus { all, pending, contacted, purchased, cancelled }

class FarmerRequestOrdersScreen extends StatefulWidget {
  const FarmerRequestOrdersScreen({super.key});
  static const String id = '/farmer-request-orders-screen';

  @override
  State<FarmerRequestOrdersScreen> createState() =>
      _FarmerRequestOrdersScreenState();
}

class _FarmerRequestOrdersScreenState extends State<FarmerRequestOrdersScreen>
    with SingleTickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  final FarmerOrderService _farmerOrderService = FarmerOrderService();
  late TabController _tabController;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadUnreadCount();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _notificationService.getUnreadNotificationsCount();
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    } catch (e) {
      debugPrint('Error loading unread count: $e');
    }
  }

  List<QueryDocumentSnapshot> _filterOrders(
    List<QueryDocumentSnapshot> orders,
    OrderStatus status,
  ) {
    var filteredOrders = orders;

    if (status != OrderStatus.all) {
      filteredOrders =
          filteredOrders.where((order) {
            final data = order.data() as Map<String, dynamic>;
            final orderStatus = data['status'] as String? ?? '';
            return orderStatus == status.name;
          }).toList();
    }

    // ترتيب الطلبات (الجديدة أولاً)
    filteredOrders.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      final aTimestamp =
          (aData['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
      final bTimestamp =
          (bData['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
      return bTimestamp.compareTo(aTimestamp);
    });

    return filteredOrders;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return _buildUnauthenticatedScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.kWiteColor,
      appBar: _buildAppBar(),
      body: Column(children: [Expanded(child: _buildTabBarView())]),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.kWiteColor,
      elevation: 0,

      title: Text(
        'طلبات الحظيرة',
        style: TextStyles.bold19.copyWith(color: AppColors.kprimaryColor),
      ),
      centerTitle: true,
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_forward_ios_outlined,
                color: AppColors.kprimaryColor,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48.0),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.kGrayColor.withOpacity(0.2)),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: false,
            labelColor: AppColors.kprimaryColor,
            unselectedLabelColor: AppColors.kGrayColor,
            indicatorColor: AppColors.kprimaryColor,
            labelStyle: TextStyles.semiBold13,
            unselectedLabelStyle: TextStyles.regular13,
            tabs: const [
              Tab(text: 'الكل'),
              Tab(text: 'في الانتظار'),
              Tab(text: 'تم التواصل'),
              Tab(text: 'تم الشراء'),
              Tab(text: 'ملغية'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnauthenticatedScreen() {
    return Scaffold(
      backgroundColor: AppColors.kWiteColor,
      appBar: buildAppBarWithArrowBackButton(
        title: 'طلبات الحظيرة',
        context: context,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              Assets.imagesOrder,
              width: 120,
              height: 120,
              colorFilter: const ColorFilter.mode(
                AppColors.kGrayColor,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'يرجى تسجيل الدخول لعرض الطلبات',
              style: TextStyles.semiBold16,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kprimaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: Text(
                'العودة',
                style: TextStyles.semiBold13.copyWith(
                  color: AppColors.kWiteColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBarView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _farmerOrderService.getFarmerOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CustomLoadingIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final allOrders = snapshot.data?.docs ?? [];

        if (allOrders.isEmpty) {
          return _buildEmptyState('لا توجد طلبات واردة حاليًا');
        }

        return TabBarView(
          controller: _tabController,
          children:
              OrderStatus.values.map((status) {
                final filteredOrders = _filterOrders(allOrders, status);
                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                    _loadUnreadCount();
                  },
                  child:
                      filteredOrders.isEmpty
                          ? _buildEmptyState('لا توجد طلبات في هذه الفئة')
                          : SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: khorizintalPadding,
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 16),
                                  // _buildQuickStats(allOrders),
                                  // const SizedBox(height: 16),
                                  ...filteredOrders.map((doc) {
                                    final orderData =
                                        doc.data() as Map<String, dynamic>;
                                    return EnhancedFarmerOrderCard(
                                      orderId: doc.id,
                                      orderData: orderData,
                                      onStatusUpdate: (status) async {
                                        await _updateOrderStatus(
                                          doc.id,
                                          status,
                                        );
                                      },
                                    );
                                  }),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                );
              }).toList(),
        );
      },
    );
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      await _farmerOrderService.updateOrderStatus(orderId, status);
      _loadUnreadCount();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تحديث حالة الطلب بنجاح',
              style: TextStyles.semiBold13.copyWith(
                color: AppColors.kWiteColor,
              ),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ في تحديث الطلب',
              style: TextStyles.semiBold13.copyWith(
                color: AppColors.kWiteColor,
              ),
            ),
            backgroundColor: AppColors.kRedColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(khorizintalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.kRedColor),
            const SizedBox(height: 16),
            Text(
              'خطأ في تحميل الطلبات',
              style: TextStyles.semiBold16.copyWith(color: AppColors.kRedColor),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyles.regular13.copyWith(color: AppColors.kGrayColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() {}),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kprimaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                'إعادة المحاولة',
                style: TextStyles.semiBold13.copyWith(
                  color: AppColors.kWiteColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(khorizintalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              Assets.imagesOrder,
              width: 120,
              height: 120,
              colorFilter: const ColorFilter.mode(
                AppColors.kGrayColor,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: TextStyles.semiBold16,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'سيتم إشعارك عند وصول طلبات جديدة',
              style: TextStyles.regular13.copyWith(color: AppColors.kGrayColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildQuickStats(List<QueryDocumentSnapshot> orders) {
  //   final stats = _calculateOrderStats(orders);

  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         colors: [
  //           AppColors.kprimaryColor.withOpacity(0.1),
  //           AppColors.kprimaryColor.withOpacity(0.05),
  //         ],
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //       ),
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: AppColors.kprimaryColor.withOpacity(0.2)),
  //     ),
  //     child: Column(
  //       children: [
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             _buildStatItem(
  //               'الإجمالي',
  //               stats['total'].toString(),
  //               Icons.shopping_cart,
  //             ),
  //             _buildStatItem(
  //               'في الانتظار',
  //               stats['pending'].toString(),
  //               Icons.pending,
  //               color: Colors.orange,
  //             ),
  //             _buildStatItem(
  //               'تم التواصل',
  //               stats['contacted'].toString(),
  //               Icons.check_circle,
  //               color: Colors.green,
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 12),
  //         Divider(color: AppColors.kGrayColor.withOpacity(0.3)),
  //         const SizedBox(height: 8),
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Text(
  //               'إجمالي القيمة: ${stats['totalValue']} دينار',
  //               style: TextStyles.bold16.copyWith(
  //                 color: AppColors.kprimaryColor,
  //               ),
  //             ),
  //             if (stats['pending'] > 0)
  //               Container(
  //                 padding: const EdgeInsets.symmetric(
  //                   horizontal: 8,
  //                   vertical: 4,
  //                 ),
  //                 decoration: BoxDecoration(
  //                   color: Colors.orange.withOpacity(0.1),
  //                   borderRadius: BorderRadius.circular(8),
  //                   border: Border.all(color: Colors.orange),
  //                 ),
  //                 child: Text(
  //                   '${stats['pending']} طلب جديد',
  //                   style: TextStyles.bold13.copyWith(color: Colors.orange),
  //                 ),
  //               ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Map<String, dynamic> _calculateOrderStats(
  //   List<QueryDocumentSnapshot> orders,
  // ) {
  //   int total = orders.length;
  //   int pending = 0;
  //   int contacted = 0;
  //   double totalValue = 0.0;

  //   for (var order in orders) {
  //     final data = order.data() as Map<String, dynamic>;
  //     final status = data['status'] as String? ?? '';

  //     if (status == 'pending') pending++;
  //     if (status == 'contacted') contacted++;

  //     final cartItems = data['cartItems'] as List<dynamic>? ?? [];
  //     totalValue += cartItems.fold<double>(0, (sum, item) {
  //       return sum + (item['totalPrice'] as num).toDouble();
  //     });
  //   }

  //   return {
  //     'total': total,
  //     'pending': pending,
  //     'contacted': contacted,
  //     'totalValue': totalValue.toStringAsFixed(0),
  //   };
  // }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color ?? AppColors.kprimaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyles.bold16.copyWith(
            color: color ?? AppColors.kprimaryColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyles.semiBold13.copyWith(color: AppColors.kGrayColor),
        ),
      ],
    );
  }
}

class EnhancedFarmerOrderCard extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> orderData;
  final Function(String) onStatusUpdate;

  const EnhancedFarmerOrderCard({
    super.key,
    required this.orderId,
    required this.orderData,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final cartItems = orderData['cartItems'] as List<dynamic>? ?? [];
    final userData = orderData['userData'] as Map<String, dynamic>? ?? {};
    final timestamp = (orderData['timestamp'] as Timestamp?)?.toDate();
    final status = orderData['status'] as String? ?? 'pending';
    final isNew = status == 'pending';

    final totalPrice = cartItems.fold<double>(
      0,
      (sum, item) => sum + (item['totalPrice'] as num).toDouble(),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:
            isNew
                ? AppColors.kprimaryColor.withOpacity(0.05)
                : AppColors.kWiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isNew
                  ? AppColors.kprimaryColor.withOpacity(0.3)
                  : AppColors.kGrayColor.withOpacity(0.2),
          width: isNew ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.kGrayColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.all(16),
        leading: _buildOrderIcon(status, isNew),
        title: _buildOrderHeader(orderId, timestamp, isNew),
        subtitle: _buildOrderSummary(cartItems.length, totalPrice, userData),
        trailing: const Icon(Icons.expand_more),
        children: [_buildOrderDetails(cartItems, userData, status)],
      ),
    );
  }

  Widget _buildOrderIcon(String status, bool isNew) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getStatusColor(status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SvgPicture.asset(
            Assets.imagesOrder,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              _getStatusColor(status),
              BlendMode.srcIn,
            ),
          ),
        ),
        if (isNew)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.kRedColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOrderHeader(String orderId, DateTime? timestamp, bool isNew) {
    final shortId = orderId.length > 8 ? orderId.substring(0, 8) : orderId;
    final formattedDate =
        timestamp != null
            ? DateFormat('dd/MM/yyyy - HH:mm', 'ar').format(timestamp)
            : 'غير متوفر';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('طلب #$shortId', style: TextStyles.bold13),
                  if (isNew) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.kRedColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'جديد',
                        style: TextStyles.bold13.copyWith(
                          color: AppColors.kWiteColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                formattedDate,
                style: TextStyles.semiBold13.copyWith(
                  color: AppColors.kGrayColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummary(
    int itemCount,
    double totalPrice,
    Map<String, dynamic> userData,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${userData['name'] ?? 'عميل غير معروف'}',
                  style: TextStyles.semiBold13,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$itemCount منتج • $totalPrice دينار',
                  style: TextStyles.semiBold13.copyWith(
                    color: AppColors.kGrayColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails(
    List<dynamic> cartItems,
    Map<String, dynamic> userData,
    String status,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        _buildProductsList(cartItems),
        const SizedBox(height: 16),
        _buildCustomerInfo(userData),
        const SizedBox(height: 16),
        _buildStatusSection(status),
        if (status == 'pending' || status == 'contacted') ...[
          const SizedBox(height: 16),
          _buildActionButtons(status),
        ],
      ],
    );
  }

  Widget _buildProductsList(List<dynamic> cartItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'المنتجات:',
          style: TextStyles.bold13.copyWith(color: AppColors.kprimaryColor),
        ),
        const SizedBox(height: 8),
        ...cartItems.map((item) {
          final productData = item['productData'] as Map<String, dynamic>;
          final quantity = item['quantity'] as int? ?? 1;
          final itemTotalPrice = (item['totalPrice'] as num).toDouble();

          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.kFillGrayColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${productData['name'] ?? 'منتج غير معروف'}',
                    style: TextStyles.semiBold13,
                  ),
                ),
                Text(
                  'x$quantity',
                  style: TextStyles.semiBold13.copyWith(
                    color: AppColors.kGrayColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$itemTotalPrice د',
                  style: TextStyles.semiBold13.copyWith(
                    color: AppColors.kprimaryColor,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCustomerInfo(Map<String, dynamic> userData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'بيانات العميل:',
          style: TextStyles.bold13.copyWith(color: AppColors.kprimaryColor),
        ),
        const SizedBox(height: 8),
        _buildInfoRow(Icons.person, 'الاسم', userData['name'] ?? 'غير متوفر'),
        _buildPhoneRow(userData['phone'] ?? 'غير متوفر'),
        _buildInfoRow(
          Icons.location_city,
          'المدينة',
          userData['city'] ?? 'غير متوفر',
        ),
        _buildInfoRow(
          Icons.location_on,
          'العنوان',
          userData['address'] ?? 'غير متوفر',
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.kGrayColor),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyles.regular13),
          Expanded(
            child: Text(
              value,
              style: TextStyles.semiBold13,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneRow(String phoneNumber) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.phone, size: 16, color: AppColors.kGrayColor),
          const SizedBox(width: 8),
          const Text('الهاتف: ', style: TextStyles.regular13),
          Expanded(
            child: EnhancedCopyablePhoneNumber(phoneNumber: phoneNumber),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(String status) {
    return Row(
      children: [
        const Icon(Icons.info_outline, size: 16, color: AppColors.kGrayColor),
        const SizedBox(width: 8),
        const Text('الحالة: ', style: TextStyles.regular13),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _getStatusColor(status)),
          ),
          child: Text(
            _getStatusText(status),
            style: TextStyles.bold13.copyWith(color: _getStatusColor(status)),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(String status) {
    return Builder(
      builder: (context) {
        if (status == 'pending') {
          return Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => onStatusUpdate('contacted'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: AppColors.kWiteColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('تم التواصل'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showCancelDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.kRedColor,
                    foregroundColor: AppColors.kWiteColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('إلغاء الطلب'),
                ),
              ),
            ],
          );
        } else if (status == 'contacted') {
          return Center(
            child: ElevatedButton.icon(
              onPressed: () => onStatusUpdate('purchased'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kprimaryColor,
                foregroundColor: AppColors.kWiteColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('تم الشراء'),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_outlined, color: AppColors.kRedColor),
              const SizedBox(width: 8),
              const Text('تأكيد الإلغاء'),
            ],
          ),
          content: const Text(
            'هل أنت متأكد من إلغاء هذا الطلب؟\nلا يمكن التراجع عن هذا الإجراء.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'لا، إبقاء الطلب',
                style: TextStyles.semiBold13.copyWith(
                  color: AppColors.kGrayColor,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onStatusUpdate('cancelled');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kRedColor,
                foregroundColor: AppColors.kWiteColor,
              ),
              child: const Text('نعم، إلغاء الطلب'),
            ),
          ],
        );
      },
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'في الانتظار';
      case 'contacted':
      case 'confirmed':
        return 'تم التواصل';
      case 'purchased':
      case 'completed':
        return 'تم الشراء';
      case 'cancelled':
        return 'ملغية';
      default:
        return 'غير معروف';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'contacted':
      case 'confirmed':
        return Colors.green;
      case 'purchased':
      case 'completed':
        return AppColors.kprimaryColor;
      case 'cancelled':
        return AppColors.kRedColor;
      default:
        return AppColors.kGrayColor;
    }
  }
}

class EnhancedCopyablePhoneNumber extends StatefulWidget {
  final String phoneNumber;

  const EnhancedCopyablePhoneNumber({super.key, required this.phoneNumber});

  @override
  State<EnhancedCopyablePhoneNumber> createState() =>
      _EnhancedCopyablePhoneNumberState();
}

class _EnhancedCopyablePhoneNumberState
    extends State<EnhancedCopyablePhoneNumber>
    with TickerProviderStateMixin {
  bool _isCopied = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _copyToClipboard() async {
    if (widget.phoneNumber != 'غير متوفر') {
      await Clipboard.setData(ClipboardData(text: widget.phoneNumber));

      _animationController.forward().then((_) {
        _animationController.reverse();
      });

      setState(() {
        _isCopied = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.kWiteColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'تم نسخ رقم الهاتف: ${widget.phoneNumber}',
                    style: TextStyles.semiBold13.copyWith(
                      color: AppColors.kWiteColor,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isCopied = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.phoneNumber,
            style: TextStyles.semiBold13.copyWith(
              color:
                  widget.phoneNumber != 'غير متوفر'
                      ? AppColors.kprimaryColor
                      : AppColors.kGrayColor,
            ),
          ),
        ),
        if (widget.phoneNumber != 'غير متوفر') ...[
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: InkWell(
                      onTap: _copyToClipboard,
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          _isCopied ? Icons.check_circle : Icons.copy,
                          color:
                              _isCopied
                                  ? Colors.green
                                  : AppColors.kprimaryColor,
                          size: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ],
    );
  }
}
