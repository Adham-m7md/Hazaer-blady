import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/services/farmer_request_order_service.dart';
import 'package:hadaer_blady/core/services/firebase_auth_service.dart';
import 'package:hadaer_blady/core/services/get_it.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_directions.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/core/widgets/row_profile_content.dart';
import 'package:hadaer_blady/features/add_custom_product/presentation/add_custom_product_screen.dart';
import 'package:hadaer_blady/features/auth/presentation/signin/view/signin_screen.dart';
import 'package:hadaer_blady/features/farmer_request_orders/presentation/farmer_request_orders_screen.dart';
import 'package:hadaer_blady/features/my_coop/presentation/my_coop_screen.dart';
import 'package:hadaer_blady/features/my_orders/presentation/my_orders.dart';
import 'package:hadaer_blady/features/profile/widgets/profile_image_widget.dart';
import 'package:hadaer_blady/features/profile/widgets/profile_info.dart';
import 'package:hadaer_blady/features/profile_data/presentation/profile_data.dart';
import 'package:hadaer_blady/features/settings/presentation/settings_screen.dart';

class ProfileScreenBody extends StatefulWidget {
  const ProfileScreenBody({super.key});

  @override
  State<ProfileScreenBody> createState() => _ProfileScreenBodyState();
}

class _ProfileScreenBodyState extends State<ProfileScreenBody> {
  final FirebaseAuthService firebaseAuthService = getIt<FirebaseAuthService>();
  final FarmerOrderService farmerOrderService = FarmerOrderService();
  bool isCoopOwner = false;
  bool isAdmin = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await firebaseAuthService.getCurrentUserData();
      final currentUserEmail = firebaseAuthService.getCurrentUser()?.email;

      setState(() {
        isCoopOwner = userData['job_title'] == 'صاحب حظيرة';
        isAdmin = currentUserEmail == 'ahmed.roma22@gmail.com';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isCoopOwner = false;
        isAdmin = false;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            spacing: 12,
            children: [
              const Row(
                children: [
                  ProfileImageWidget(),
                  SizedBox(width: 24),
                  UserInfoColumn(),
                ],
              ),
              const Row(children: [Text('عام', style: TextStyles.semiBold16)]),
              InkWell(
                onTap: () {
                  Navigator.pushNamed(context, ProfileData.id);
                },
                child: const CustomeRowProfileContent(
                  icon: Icons.person_outlined,
                  titelText: 'بياناتى',
                ),
              ),

              if (isCoopOwner)
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, MyCoopScreen.id);
                  },
                  child: const CustomeRowProfileContent(
                    icon: Icons.storefront_outlined,
                    titelText: 'حظيرتي',
                  ),
                ),

              if (isAdmin)
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, AddCustomProductScreen.id);
                  },
                  child: const CustomeRowProfileContent(
                    icon: Icons.add,
                    titelText: 'إضافة عرض خاص ',
                  ),
                ),

              if (isCoopOwner)
                FarmerOrdersRowWithBadge(
                  farmerOrderService: farmerOrderService,
                ),

              InkWell(
                onTap: () {
                  Navigator.pushNamed(context, MyOrders.id);
                },
                child: const CustomeRowProfileContent(
                  icon: Icons.shopping_bag_outlined,
                  titelText: 'مشترياتي',
                ),
              ),

              const Row(
                children: [Text('المساعدة', style: TextStyles.semiBold16)],
              ),
              InkWell(
                onTap: () {
                  Navigator.pushNamed(context, SettingsScreen.id);
                },
                child: const CustomeRowProfileContent(
                  icon: Icons.settings_outlined,
                  titelText: 'الإعدادات',
                ),
              ),

              if (isAdmin) ...[
                SizedBox(height: context.screenHeight * 0.02),
              ] else if (isCoopOwner) ...[
                SizedBox(height: context.screenHeight * 0.15),
              ] else ...[
                SizedBox(height: context.screenHeight * 0.32),
              ],
              GestureDetector(
                onTap: () {
                  firebaseAuthService.signOut();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    SigninScreen.id,
                    (_) => false,
                  );
                },
                child: Container(
                  height: 30,
                  width: double.infinity,
                  color: const Color(0xffEBF9F1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.logout_sharp,
                        color: AppColors.kRedColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'تسجيل الخروج',
                        style: TextStyles.semiBold16.copyWith(
                          color: AppColors.kRedColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
  }
}

// Widget بديل أكثر تفصيلاً (اختياري)
class FarmerOrdersRowWithBadge extends StatelessWidget {
  final FarmerOrderService farmerOrderService;

  const FarmerOrdersRowWithBadge({super.key, required this.farmerOrderService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: farmerOrderService.getFarmerOrders(),
      builder: (context, snapshot) {
        int pendingOrdersCount = 0;

        if (snapshot.hasData && snapshot.data != null) {
          final pendingOrders =
              snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final status = data['status'] as String? ?? '';
                return status == 'pending';
              }).toList();

          pendingOrdersCount = pendingOrders.length;
        }

        return InkWell(
          onTap: () {
            Navigator.pushNamed(context, FarmerRequestOrdersScreen.id);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.kBlackColor,
                      size: 24,
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'الطلبات الواردة',
                          style: TextStyles.semiBold16.copyWith(
                            color: AppColors.kGrayColor,
                          ),
                        ),
                      ),
                      if (pendingOrdersCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.kRedColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            pendingOrdersCount > 99
                                ? '99+'
                                : pendingOrdersCount.toString(),
                            style: TextStyles.bold13.copyWith(
                              color: Colors.white,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      const Padding(
                        padding: EdgeInsets.only(left: 12),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          color: AppColors.kprimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
