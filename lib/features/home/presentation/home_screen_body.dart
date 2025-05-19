import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/constants.dart';
import 'package:hadaer_blady/core/services/custom_product_servise.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/core/widgets/custom_loading_indicator.dart';
import 'package:hadaer_blady/features/home/presentation/widgets/custom_offers_list/offer_carousel.dart';
import 'package:hadaer_blady/features/home/presentation/widgets/product_section_home_body.dart';
import 'package:hadaer_blady/features/home/presentation/widgets/user_name_widget.dart';
import 'package:hadaer_blady/features/notfications/notfications_screen.dart';

class HomeScreenBody extends StatefulWidget {
  const HomeScreenBody({super.key});

  @override
  _HomeScreenBodyState createState() => _HomeScreenBodyState();
}

class _HomeScreenBodyState extends State<HomeScreenBody> {
  final CustomProductService productService = CustomProductService();

  // Key for RefreshIndicator
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
            _buildHeaderSection(),

            // Main Content with Pull to Refresh
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
                      const SizedBox(height: 4),

                      // Offers Section
                      _buildOffersSection(),

                      // Products Section
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
        const Positioned(
          top: 4,
          right: 0,
          left: 0,
          child: CircleAvatar(backgroundColor: AppColors.kRedColor, radius: 3),
        ),
      ],
    );
  }

  Widget _buildOffersSection() {
    return Column(
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
      // Add a small delay for better UX
      await Future.delayed(const Duration(milliseconds: 500));

      // Refresh the state to trigger rebuilds
      setState(() {
        // This will trigger all StreamBuilders and FutureBuilders to rebuild
      });

      log('Page refreshed successfully');
    } catch (e) {
      log('Error during refresh: $e');
    }
  }
}
