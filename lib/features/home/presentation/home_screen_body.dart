import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hadaer_blady/core/constants.dart';
import 'package:hadaer_blady/core/services/custom_product_servise.dart';
import 'package:hadaer_blady/core/services/firebase_auth_service.dart';
import 'package:hadaer_blady/core/services/get_it.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/core/widgets/custom_loading_indicator.dart';
import 'package:hadaer_blady/features/home/presentation/widgets/custom_offers_list/offer_carousel.dart';
import 'package:hadaer_blady/features/home/presentation/widgets/product_section_home_body.dart';
import 'package:hadaer_blady/features/home/presentation/widgets/user_name_widget.dart';
import 'package:hadaer_blady/features/notfications/cubit/notfications_cubit.dart';
import 'package:hadaer_blady/features/notfications/notfications_screen.dart';

class HomeScreenBody extends StatefulWidget {
  const HomeScreenBody({super.key});

  @override
  _HomeScreenBodyState createState() => _HomeScreenBodyState();
}

class _HomeScreenBodyState extends State<HomeScreenBody> {
  final CustomProductService productService = CustomProductService();

  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(
          right: khorizintalPadding,
          left: khorizintalPadding,
          top: 12,
        ),
        child: Column(
          spacing: 8,
          children: [
            // Header Section
            BlocProvider(
              create: (context) => NotificationsCubit(),
              child: _buildHeaderSection(),
            ),

            Expanded(
              child: RefreshIndicator(
                key: _refreshKey,
                onRefresh: _onRefresh,
                color: AppColors.lightPrimaryColor,
                backgroundColor: AppColors.kWiteColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  scrollDirection: Axis.vertical,
                  child: Column(
                    spacing: 8,
                    children: [
                      _buildOffersSection(),

                      const ProductsSectionWidget(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: 8),
        const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('مرحبا ..!', style: TextStyles.semiBold16),
            UserNameWidget(),
          ],
        ),
        _buildNotificationButton(),
      ],
    );
  }

  Widget _buildNotificationButton() {
    final firebaseAuth = getIt<FirebaseAuthService>();
    final auth = getIt<FirebaseAuthService>();

    return StreamBuilder<QuerySnapshot>(
      stream:
          firebaseAuth.firestore
              .collection('users')
              .doc(auth.auth.currentUser!.uid)
              .collection('notifications')
              .where('isRead', isEqualTo: false)
              .snapshots(),
      builder: (context, snapshot) {
        int unreadCount = 0;

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          unreadCount = snapshot.data!.docs.length;
        }
        return Stack(
          children: [
            Positioned(
              child: CircleAvatar(
                backgroundColor: AppColors.lightPrimaryColor.withAlpha(40),
                child: IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, NotificationsScreen.id);
                  },
                  icon: const Icon(
                    Icons.notifications_active,
                    color: AppColors.lightPrimaryColor,
                  ),
                ),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                top: 0,
                right: 0,
                left: 26,
                child: CircleAvatar(
                  backgroundColor: AppColors.kRedColor,
                  radius: 8,
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: TextStyles.semiBold11.copyWith(
                      color: AppColors.kWiteColor,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildOffersSection() {
    return Column(
      spacing: 12,
      children: [
        const Row(children: [Text('عروض مميزة :', style: TextStyles.bold16)]),
        FutureBuilder<List<CustomProduct>>(
          future: productService.getAllProducts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CustomLoadingIndicator());
            }
            if (snapshot.hasError) {
              log('Error fetching offers: ${snapshot.error}');
              return const Center(
                child: Text(
                  'خطأ في تحميل العروض',
                  style: TextStyles.semiBold16,
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('لا توجد عروض متاحة', style: TextStyles.semiBold16),
              );
            }
            final products = snapshot.data!;
            log('Fetched ${products.length} special offers');
            return OffersCarousel(products: products);
          },
        ),
      ],
    );
  }

  // Function to handle refresh
  Future<void> _onRefresh() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {});

      log('Page refreshed successfully');
    } catch (e) {
      log('Error during refresh: $e');
    }
  }
}
