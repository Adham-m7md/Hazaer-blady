import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hadaer_blady/core/services/firebase_auth_service.dart';
import 'package:hadaer_blady/core/services/get_it.dart';
import 'package:hadaer_blady/features/add_custom_product/presentation/add_custom_product_screen.dart';
import 'package:hadaer_blady/features/add_custom_product/presentation/custom_product_screen_details.dart';
import 'package:hadaer_blady/features/add_product/view/add_product_screen.dart';
import 'package:hadaer_blady/features/auth/presentation/forget_pass/view/forget_pass.dart';
import 'package:hadaer_blady/features/auth/presentation/signin/view/signin_screen.dart';
import 'package:hadaer_blady/features/auth/presentation/signup/view/signup_screen.dart';
import 'package:hadaer_blady/features/cart/cubit/cart_cubit.dart';
import 'package:hadaer_blady/features/cart/presentation/cart_screen.dart';
import 'package:hadaer_blady/features/checkout/presentation/check_out_flow.dart';
import 'package:hadaer_blady/features/checkout/presentation/checkout_screen.dart';
import 'package:hadaer_blady/features/checkout/presentation/congrates_screen.dart';
import 'package:hadaer_blady/features/coops/presentation/coop_details.dart';
import 'package:hadaer_blady/features/coops/presentation/coops_screen.dart';
import 'package:hadaer_blady/features/farmer_request_orders/presentation/farmer_request_orders_screen.dart';
import 'package:hadaer_blady/features/home/presentation/home_screen.dart';
import 'package:hadaer_blady/features/home/presentation/widgets/custom_offers_list/offer_carousel.dart';
import 'package:hadaer_blady/features/my_coop/presentation/my_coop_screen.dart';
import 'package:hadaer_blady/features/my_orders/presentation/my_orders.dart';
import 'package:hadaer_blady/features/notfications/notfications_screen.dart';
import 'package:hadaer_blady/features/onboarding/view/onboarding_view.dart';
import 'package:hadaer_blady/features/product/presentation/product_details_screen.dart';
import 'package:hadaer_blady/features/profile_data/presentation/profile_data.dart';
import 'package:hadaer_blady/features/rateing/view/rating_screen.dart';
import 'package:hadaer_blady/features/settings/presentation/settings_screen.dart';
import 'package:hadaer_blady/features/splash/splash_screen.dart';
import 'package:hadaer_blady/features/who_we_are/presentation/who_we_are_screen.dart';

// Widget لعرض رسالة تسجيل الدخول المطلوب
class LoginRequiredScreen extends StatelessWidget {
  final String message;

  const LoginRequiredScreen({
    super.key,
    this.message = 'يجب تسجيل الدخول أولاً للوصول لهذه الصفحة',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل الدخول مطلوب'),
        backgroundColor: Colors.red.shade50,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 80, color: Colors.red.shade300),
              const SizedBox(height: 24),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed:
                        () => Navigator.pushReplacementNamed(
                          context,
                          SigninScreen.id,
                        ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('تسجيل الدخول'),
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('رجوع'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Route<dynamic> onGenerateRoute(RouteSettings settings) {
  log(
    'Navigating to route: ${settings.name} with arguments: ${settings.arguments}',
  );

  // التحقق من تسجيل الدخول للصفحات المحمية
  final authService = getIt<FirebaseAuthService>();
  final protectedRoutes = [
    CustomProductDetailScreen.id,
    CartScreen.id,
    CheckoutScreen.id,
    CheckoutFlow.id,
    MyOrders.id,
    ProfileData.id,
    // يمكنك إضافة المزيد من الصفحات المحمية هنا
  ];

  if (protectedRoutes.contains(settings.name) &&
      !authService.isUserLoggedIn()) {
    log('Access denied to ${settings.name} - User not logged in');
    return MaterialPageRoute(builder: (_) => const LoginRequiredScreen());
  }

  switch (settings.name) {
    case FarmerRequestOrdersScreen.id:
      return MaterialPageRoute(
        builder: (_) => const FarmerRequestOrdersScreen(),
      );
    case MyCoopScreen.id:
      return MaterialPageRoute(builder: (_) => const MyCoopScreen());
    case CustomProductDetailScreen.id:
      final CustomProduct? product = settings.arguments as CustomProduct?;
      if (product == null) {
        log('Error: No product data provided for CustomProductDetailScreen');
        return MaterialPageRoute(
          builder:
              (_) => const Scaffold(
                body: Center(
                  child: Text(
                    'خطأ: لم يتم تمرير بيانات العرض',
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
                ),
              ),
        );
      }
      log(
        'Navigating to CustomProductDetailScreen with product: ${product.id} - ${product.title}',
      );
      return MaterialPageRoute(
        builder: (_) => CustomProductDetailScreen(product: product),
      );
    case AddCustomProductScreen.id:
      return MaterialPageRoute(builder: (_) => const AddCustomProductScreen());
    case SettingsScreen.id:
      return MaterialPageRoute(builder: (_) => const SettingsScreen());
    case RatingScreen.id:
      final String? userId = settings.arguments as String?;
      if (userId == null || userId.isEmpty) {
        log('Error: No userId provided for RatingScreen');
        return MaterialPageRoute(
          builder:
              (_) => const Scaffold(
                body: Center(child: Text('معرف المستخدم غير متوفر')),
              ),
        );
      }
      return MaterialPageRoute(builder: (_) => RatingScreen(userId: userId));
    case AddProductScreen.id:
      return MaterialPageRoute(builder: (_) => const AddProductScreen());
    case CoopDetails.id:
      final arguments = settings.arguments;
      if (arguments is String && arguments.isNotEmpty) {
        return MaterialPageRoute(
          builder: (_) => CoopDetails(farmerId: arguments),
        );
      }
      log('Error: No farmerId provided for CoopDetails');
      return MaterialPageRoute(
        builder:
            (_) => const Scaffold(
              body: Center(child: Text('معرف الحضيرة غير متوفر')),
            ),
      );
    case CartScreen.id:
      return MaterialPageRoute(builder: (_) => const CartScreen());
    case NotificationsScreen.id:
      return MaterialPageRoute(builder: (_) => const NotificationsScreen());
    case ForgetPass.id:
      return MaterialPageRoute(builder: (_) => const ForgetPass());
    case CoopsScreen.id:
      return MaterialPageRoute(builder: (_) => const CoopsScreen());
    case CheckoutFlow.id:
      final selectedItems =
          settings.arguments as List<Map<String, dynamic>>? ?? [];
      debugPrint('onGenerateRoute: CheckoutFlow arguments = $selectedItems');
      return MaterialPageRoute(
        builder: (_) => CheckoutFlow(),
        settings: RouteSettings(arguments: selectedItems), // تمرير arguments
      );
    case CheckoutScreen.id:
      final selectedItems =
          settings.arguments as List<Map<String, dynamic>>? ?? [];
      return MaterialPageRoute(
        builder:
            (_) => BlocProvider(
              create: (context) => CartCubit()..loadCartItems(),
              child: CheckoutScreen(selectedItems: selectedItems),
            ),
      );
    case CongratesScreen.id:
      final String? orderNumber = settings.arguments as String?;
      if (orderNumber == null || orderNumber.isEmpty) {
        log('Error: No orderNumber provided for CongratesScreen');
        return MaterialPageRoute(
          builder:
              (_) => const Scaffold(
                body: Center(child: Text('رقم الطلب غير متوفر')),
              ),
        );
      }
      return MaterialPageRoute(
        builder: (_) => CongratesScreen(orderNumber: orderNumber),
      );
    case MyOrders.id:
      return MaterialPageRoute(builder: (_) => const MyOrders());
    case WhoWeAreScreen.id:
      return MaterialPageRoute(builder: (_) => const WhoWeAreScreen());
    case ProfileData.id:
      return MaterialPageRoute(builder: (_) => const ProfileData());
    case ProductDetailsScreen.id:
      final arguments = settings.arguments;
      if (arguments is Map<String, dynamic> &&
          arguments.containsKey('productId') &&
          arguments.containsKey('product')) {
        final String productId = arguments['productId'] as String;
        final Map<String, dynamic> product =
            arguments['product'] as Map<String, dynamic>;
        if (productId.isNotEmpty) {
          return MaterialPageRoute(
            builder:
                (_) => ProductDetailsScreen(
                  productId: productId,
                  product: product,
                ),
          );
        }
      }
      log('Error: Invalid product data for ProductDetailsScreen');
      return MaterialPageRoute(
        builder:
            (_) => const Scaffold(
              body: Center(child: Text('معرف المنتج أو البيانات غير متوفرة')),
            ),
      );
    case HomeScreen.id:
      return MaterialPageRoute(builder: (_) => const HomeScreen());
    case SignupScreen.id:
      return MaterialPageRoute(builder: (_) => const SignupScreen());
    case OnboardingView.id:
      return MaterialPageRoute(builder: (_) => const OnboardingView());
    case SigninScreen.id:
      return MaterialPageRoute(builder: (_) => const SigninScreen());
    case SplashScreen.id:
      return MaterialPageRoute(builder: (_) => const SplashScreen());
    default:
      log('Error: Unknown route: ${settings.name}');
      return MaterialPageRoute(
        builder:
            (_) =>
                const Scaffold(body: Center(child: Text('الصفحة غير موجودة'))),
      );
  }
}
