// قم باستبدال ملف checkout_screen.dart بهذا الكود

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hadaer_blady/core/constants.dart';
import 'package:hadaer_blady/core/functions/build_app_bar_with_arrow_back_button.dart';
import 'package:hadaer_blady/core/services/check_out_service.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/widgets/custom_button.dart';
import 'package:hadaer_blady/features/cart/cubit/cart_cubit.dart';
import 'package:hadaer_blady/features/checkout/presentation/checkout_1_data.dart';
import 'package:hadaer_blady/features/checkout/presentation/congrates_screen.dart';
import 'package:hadaer_blady/features/checkout/widgets/checkout_steps_page_view.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  static const id = 'CheckoutScreen';

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late PageController pageController;
  int currentIndexPage = 0;
  Map<String, String>? userData;
  final CheckoutService _checkoutService = CheckoutService();
  final GlobalKey<Checkout1DataState> _checkout1DataKey =
      GlobalKey<Checkout1DataState>();

  @override
  void initState() {
    super.initState();
    pageController = PageController();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void _submitOrder() async {
    try {
      // الوصول إلى CartCubit من سياق CheckoutScreen
      // هذا سيعمل لأن CartCubit موجود بالفعل في شجرة الويدجت من خلال CheckoutFlow
      final cartCubit = context.read<CartCubit>();
      final cartItems =
          cartCubit.state is CartLoaded
              ? (cartCubit.state as CartLoaded).cartItems
              : <Map<String, dynamic>>[];

      // التحقق من البيانات
      if (cartItems.isEmpty) {
        debugPrint('Error: Cart is empty');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('السلة فارغة'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (userData == null || userData!.isEmpty) {
        debugPrint('Error: User data is null or empty');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('بيانات المستخدم غير مكتملة'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      debugPrint(
        'Submitting order with userData: $userData, cartItems: $cartItems',
      );

      // إرسال الطلب باستخدام CheckoutService
      final orderNumber = await _checkoutService.submitOrder(
        userData: userData!,
        cartItems: cartItems,
      );

      debugPrint('Order submitted successfully, orderNumber: $orderNumber');

      // تفريغ السلة بعد الشراء الناجح
      cartCubit.clearCart();

      // الانتقال إلى شاشة التهنئة مع رقم الطلب
      Navigator.pushNamedAndRemoveUntil(
        context,
        CongratesScreen.id,
        (route) => false,
        arguments: orderNumber,
      );
    } catch (e, stackTrace) {
      debugPrint('Error in _submitOrder: $e');
      debugPrint('StackTrace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل إتمام الطلب: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // لم نعد بحاجة إلى إنشاء BlocProvider هنا
    // لأنه تم إنشاؤه بالفعل في CheckoutFlow
    return Scaffold(
      backgroundColor: AppColors.kWiteColor,
      appBar: buildAppBarWithArrowBackButton(
        title: 'تأكيد الطلب',
        context: context,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: khorizintalPadding),
          child: Column(
            children: [
              CheckoutStepsPageView(
                pageController: pageController,
                checkout1DataKey: _checkout1DataKey,
                onPageChanged: (index) {
                  setState(() {
                    currentIndexPage = index;
                  });
                },
                userData: userData,
                onDataSubmitted: (data) {
                  setState(() {
                    userData = data;
                  });
                  pageController.nextPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.linear,
                  );
                },
              ),
              currentIndexPage == 0
                  ? CustomButton(
                    onPressed: () {
                      // التحقق من البيانات قبل الانتقال
                      if (_checkout1DataKey.currentState != null) {
                        _checkout1DataKey.currentState!.submitData();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('يرجى ملء جميع الحقول بشكل صحيح'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    text: 'التالي',
                  )
                  : CustomButton(
                    onPressed: userData != null ? _submitOrder : () {},
                    text: 'الشراء',
                    color:
                        userData != null
                            ? AppColors.kprimaryColor
                            : AppColors.kGrayColor,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
