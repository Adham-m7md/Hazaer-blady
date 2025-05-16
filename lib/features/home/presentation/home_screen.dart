// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/services/firebase_auth_service.dart';
import 'package:hadaer_blady/core/services/get_it.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/widgets/custom_loading_indicator.dart';
import 'package:hadaer_blady/features/add_product/view/add_product_screen.dart';
import 'package:hadaer_blady/features/cart/presentation/cart_screen.dart';
import 'package:hadaer_blady/features/coops/presentation/coops_screen.dart';
import 'package:hadaer_blady/features/home/presentation/home_screen_body.dart';
import 'package:hadaer_blady/features/home/presentation/widgets/bottom_nav_bar/bottom_nav_bar.dart';
import 'package:hadaer_blady/features/profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialTabIndex});
  static const String id = 'homescreen';
  final int? initialTabIndex;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _pageController;
  int _selectedIndex = 0;
  bool _isFarmer = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialTabIndex ?? 0);
    _selectedIndex = widget.initialTabIndex ?? 0;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authService = getIt<FirebaseAuthService>();
    try {
      final userData = await authService.getCurrentUserData();
      setState(() {
        _isFarmer = userData['job_title'] == 'صاحب حظيرة';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ في تحميل البيانات: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.kWiteColor,
        body: Center(child: CustomLoadingIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(body: Center(child: Text(_errorMessage!)));
    }

    final List<Widget> screens = [
      const HomeScreenBody(),
      const CoopsScreen(),
      if (_isFarmer) const AddProductScreen(),
      const CartScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.kWiteColor,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: screens,
      ),
      bottomNavigationBar: BottomNavBar(
        onTap: _onNavBarTap,
        currentIndex: _selectedIndex,
        isFarmer: _isFarmer,
      ),
    );
  }

  void _onNavBarTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 200),
      curve: Curves.linear,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
