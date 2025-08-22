import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hadaer_blady/core/constants.dart';
import 'package:hadaer_blady/core/functions/build_app_bar_with_arrow_back_button.dart';
import 'package:hadaer_blady/core/services/check_out_service.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/core/utils/svg_images.dart';
import 'package:hadaer_blady/core/widgets/custom_button.dart';
import 'package:hadaer_blady/core/widgets/custome_show_dialog.dart';
import 'package:hadaer_blady/features/cart/cubit/cart_cubit.dart';
import 'package:hadaer_blady/features/checkout/presentation/checkout_1_data.dart';
import 'package:hadaer_blady/features/checkout/presentation/congrates_screen.dart';
import 'package:hadaer_blady/features/checkout/widgets/checkout_steps_page_view.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedItems;

  const CheckoutScreen({super.key, required this.selectedItems});

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
    debugPrint(
      'CheckoutScreen: Initial selectedItems = ${widget.selectedItems}',
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void _submitOrder() async {
    try {
      final cartItems = widget.selectedItems;

      if (cartItems.isEmpty) {
        debugPrint('Error: Cart is empty');
        showDialog(
          context: context,
          builder:
              (context) => CustomeShowDialog(
                text: 'السلة فارغة',
                buttonText: 'حسنًا',
                onPressed: () => Navigator.pop(context),
                imagePath: Assets.imagesEror,
              ),
        );
        return;
      }

      if (userData == null || userData!.isEmpty) {
        debugPrint('Error: User data is null or empty');
        showDialog(
          context: context,
          builder:
              (context) => CustomeShowDialog(
                text: 'بيانات المستخدم غير مكتملة',
                buttonText: 'حسنًا',
                onPressed: () => Navigator.pop(context),
                imagePath: Assets.imagesEror,
              ),
        );
        return;
      }

      debugPrint(
        'Submitting order with userData: $userData, cartItems: $cartItems',
      );

      final orderNumber = await _checkoutService.submitOrder(
        userData: userData!,
        cartItems: cartItems,
      );

      debugPrint('Order submitted successfully, orderNumber: $orderNumber');

      final cartCubit = context.read<CartCubit>();
      for (var item in cartItems) {
        await cartCubit.removeFromCart(item['productId']);
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        CongratesScreen.id,
        (route) => false,
        arguments: orderNumber,
      );
    } catch (e, stackTrace) {
      debugPrint('Error in _submitOrder: $e');
      debugPrint('StackTrace: $stackTrace');
      // تنظيف رسالة الخطأ
      String errorMessage = e.toString();
      // إزالة "Exception: " أو "exception" بأي صيغة
      errorMessage = errorMessage.replaceAll(RegExp(r'[Ee]xception:?\s*'), '');
      // إزالة نصوص إضافية مثل "فشل في إنشاء الطلب"
      if (errorMessage.contains('فشل في إنشاء الطلب')) {
        errorMessage = errorMessage.split('فشل في إنشاء الطلب').last.trim();
      }
      // إزالة أي نصوص متبقية قبل الرسالة المطلوبة
      if (errorMessage.contains(
        'يجب أن يكون جميع العناصر من نفس صاحب الحظيرة',
      )) {
        errorMessage = 'يجب أن يكون جميع العناصر من نفس صاحب الحظيرة';
      }
      // إذا لم يتم التعرف على الرسالة، استخدم رسالة افتراضية
      errorMessage = errorMessage.isEmpty ? 'حدث خطأ غير متوقع' : errorMessage;
      showDialog(
        context: context,
        builder:
            (context) => CustomeShowDialog(
              text: errorMessage,
              buttonText: 'حسنًا',
              onPressed: () => Navigator.pop(context),
              imagePath: Assets.imagesEror,
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      'CheckoutScreen: Building with selectedItems = ${widget.selectedItems}',
    );
    if (widget.selectedItems.isEmpty) {
      debugPrint('CheckoutScreen: Warning - selectedItems is empty');
      return Scaffold(
        appBar: buildAppBarWithArrowBackButton(
          title: 'تأكيد الطلب',
          context: context,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'خطأ: لم يتم اختيار أي منتجات',
                style: TextStyles.semiBold16,
              ),
              const SizedBox(height: 16),
              CustomButton(
                onPressed: () => Navigator.pop(context),
                text: 'العودة',
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.kWiteColor,
      appBar: buildAppBarWithArrowBackButton(
        title: 'تأكيد الطلب',
        context: context,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: khorizintalPadding,
            vertical: 16.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // قسم المنتجات المختارة
              CheckoutStepsPageView(
                pageController: pageController,
                checkout1DataKey: _checkout1DataKey,
                onPageChanged: (index) {
                  setState(() {
                    currentIndexPage = index;
                    debugPrint('CheckoutScreen: Page changed to index $index');
                  });
                },
                userData: userData,
                onDataSubmitted: (data) {
                  setState(() {
                    userData = data;
                    debugPrint('CheckoutScreen: User data submitted = $data');
                  });
                  pageController.nextPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.linear,
                  );
                },
                selectedItems: widget.selectedItems,
              ),
              const SizedBox(height: 36),
              // زر التالي أو الشراء
              currentIndexPage == 0
                  ? CustomButton(
                    onPressed: () {
                      if (_checkout1DataKey.currentState != null) {
                        _checkout1DataKey.currentState!.submitData();
                      } else {
                        showDialog(
                          context: context,
                          builder:
                              (context) => CustomeShowDialog(
                                text: 'يرجى ملء جميع الحقول بشكل صحيح',
                                buttonText: 'حسنًا',
                                onPressed: () => Navigator.pop(context),
                                imagePath: Assets.imagesEror,
                              ),
                        );
                      }
                    },
                    text: 'التالي',
                  )
                  : CustomCartButton(
                    onPressed: _submitOrder,
                    text: 'الشراء',
                    enabled: userData != null,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
