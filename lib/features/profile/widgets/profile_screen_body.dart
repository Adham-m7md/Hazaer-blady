import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/services/firebase_auth_service.dart';
import 'package:hadaer_blady/core/services/get_it.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_directions.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/core/widgets/row_profile_content.dart';
import 'package:hadaer_blady/features/add_custom_product/presentation/add_custom_product_screen.dart';
import 'package:hadaer_blady/features/auth/presentation/signin/view/signin_screen.dart';
import 'package:hadaer_blady/features/my_coop/presentation/my_coop_screen.dart';
import 'package:hadaer_blady/features/my_orders/presentation/my_orders.dart';
import 'package:hadaer_blady/features/profile/widgets/profile_image_widget.dart';
import 'package:hadaer_blady/features/profile/widgets/profile_info.dart';
import 'package:hadaer_blady/features/profile_data/presentation/profile_data.dart';
import 'package:hadaer_blady/features/settings/presentation/settings_screen.dart';
import 'package:hadaer_blady/features/who_we_are/presentation/who_we_are_screen.dart';

class ProfileScreenBody extends StatefulWidget {
  const ProfileScreenBody({super.key});

  @override
  State<ProfileScreenBody> createState() => _ProfileScreenBodyState();
}

class _ProfileScreenBodyState extends State<ProfileScreenBody> {
  final FirebaseAuthService firebaseAuthService = getIt<FirebaseAuthService>();
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

              // Only show "حظيرتي" for coop owners
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
              InkWell(
                onTap: () {
                  Navigator.pushNamed(context, MyOrders.id);
                },
                child: const CustomeRowProfileContent(
                  icon: Icons.inventory_2_outlined,
                  titelText: 'طلباتى',
                ),
              ),
              CustomeRowProfileContent(
                icon: Icons.notifications_outlined,
                titelText: 'الأشعارات',
                secondIcon: Icons.notifications_active_outlined,
                actionButton: () {},
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
              InkWell(
                onTap: () {
                  Navigator.pushNamed(context, WhoWeAreScreen.id);
                },
                child: const CustomeRowProfileContent(
                  icon: Icons.info_outlined,
                  titelText: 'من نحن',
                ),
              ),
              if (isAdmin) ...[
                SizedBox(height: context.screenHeight * 0.04),
              ] else if (isCoopOwner) ...[
                SizedBox(height: context.screenHeight * 0.1),
              ] else ...[
                SizedBox(height: context.screenHeight * 0.15),
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
                  color: Color(0xffEBF9F1),
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
