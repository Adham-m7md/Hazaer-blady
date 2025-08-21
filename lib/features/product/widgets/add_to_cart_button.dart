import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_directions.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/core/widgets/custome_show_dialog.dart';
import 'package:hadaer_blady/features/cart/cubit/cart_cubit.dart';
import 'package:hadaer_blady/features/home/presentation/home_screen.dart';
import 'package:hadaer_blady/features/product/cubit/product_details_cubit.dart';

class AddToCartButton extends StatelessWidget {
  final Map<String, dynamic> productData;
  // final int quantity;
  final double totalPrice;

  const AddToCartButton({
    super.key,
    required this.productData,
    // required this.quantity,
    required this.totalPrice,
  });

  Future<void> _handleAddToCart(BuildContext context) async {
    try {
      final cartCubit = context.read<CartCubit>();
      print('productData: $productData'); // تسجيل productData
      final productId = productData['id'];

      // فحص إن productId موجود وغير فارغ
      if (productId == null || productId.isEmpty) {
        print('Invalid productId: $productId'); // تسجيل productId
        _showErrorMessage(context, 'معرف المنتج غير صالح');
        return;
      }

      // 1. إضافة المنتج إلى السلة
      await cartCubit.addToCart(
        productId: productId,
        productData: productData,
 
        totalPrice: totalPrice,
      );
      // 2. التحقق من نوع المستخدم (مزارع أم مستخدم عادي)
      final isFarmer = await context.read<ProductDetailsCubit>().isFarmer();

      if (isFarmer) {
        // انتقال المزارع إلى شاشة الرئيسية عند التبويب المناسب
        _navigateToHomeScreen(context, isFarmer);
      } else {
        // إظهار رسالة تأكيد للمستخدم العادي
        _showSuccessMessage(context);
      }
    } catch (error) {
      // عرض رسالة خطأ إذا فشلت عملية الإضافة
      _showErrorMessage(context, error.toString());
    }
  }

  void _navigateToHomeScreen(BuildContext context, bool isFarmer) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(initialTabIndex: isFarmer ? 3 : 2),
      ),
      (route) => false,
    );
  }

  void _showSuccessMessage(BuildContext context) async {
    final productName = productData['name'] ?? 'المنتج';
    final isFarmer = await context.read<ProductDetailsCubit>().isFarmer();

    // إظهار CustomeShowDialog بدلاً من SnackBar
    showDialog(
      context: context,
      builder:
          (context) => CustomeShowDialog(
            text: 'تمت إضافة $productName  إلى السلة',
            buttonText: 'عرض السلة',
            onPressed: () {
              Navigator.pop(context); // إغلاق الـ Dialog
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          HomeScreen(initialTabIndex: isFarmer ? 3 : 2),
                ),
                (route) => false,
              );
            },
          ),
    );
  }

  void _showErrorMessage(BuildContext context, String errorMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'فشلت عملية الإضافة: $errorMessage',
                style: TextStyles.semiBold16.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.kRedColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        return Column(
          children: [
            EnhancedButton(
              onPressed:
                  state is CartLoading
                      ? null // تعطيل الزر أثناء التحميل
                      : () => _handleAddToCart(context),
              text:
                  state is CartLoading ? 'جاري الإضافة...' : 'إضافة إلى السلة',
              icon: Icons.shopping_cart,
              color:
                  state is CartLoading
                      ? AppColors.klightGrayColor
                      : AppColors.kprimaryColor,
            ),
            if (state is CartError)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'فشلت عملية الإضافة، حاول مرة أخرى',
                  style: TextStyles.regular13.copyWith(
                    color: AppColors.kRedColor,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class EnhancedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final Color color;
  final IconData? icon;
  final double? width;
  final double? height;

  const EnhancedButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.color = AppColors.kprimaryColor,
    this.icon,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? context.screenHeight * 0.06,
      width: width ?? double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor:
              onPressed == null ? AppColors.klightGrayColor : color,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.kWiteColor, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: TextStyles.bold16.copyWith(color: AppColors.kWiteColor),
            ),
          ],
        ),
      ),
    );
  }
}
