import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hadaer_blady/core/constants.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/core/widgets/custom_button.dart';
import 'package:hadaer_blady/core/widgets/custom_loading_indicator.dart';
import 'package:hadaer_blady/features/cart/cubit/cart_cubit.dart';
import 'package:hadaer_blady/features/checkout/presentation/check_out_flow.dart';
import 'package:hadaer_blady/features/home/presentation/home_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});
  static const String id = 'cart-screen';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CartCubit()..loadCartItems(),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            right: khorizintalPadding,
            left: khorizintalPadding,
            top: 12,
          ),
          child: Column(
            children: [
              const Text('عربة التسوق', style: TextStyles.bold19),
              BlocConsumer<CartCubit, CartState>(
                listener: (context, state) {
                  // عرض رسالة نجاح عند إضافة منتج للسلة
                  if (state is CartSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }

                  // عرض رسالة الخطأ فقط في حالة وجود خطأ حقيقي
                  if (state is CartError) {
                    // تجاهل الخطأ إذا كان بسبب السلة الفاضية
                    if (!state.message.contains(
                          'انتهت مهلة جلب محتويات السلة',
                        ) ||
                        context.read<CartCubit>().lastKnownItems.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
                builder: (context, state) {
                  // عرض مؤشر التحميل عند بدء تحميل السلة
                  if (state is CartLoading) {
                    return const Expanded(
                      child: Center(child: CustomLoadingIndicator()),
                    );
                  }

                  // عرض مؤشر التحديث عند إجراء عمليات على السلة
                  if (state is CartUpdating) {
                    return Expanded(
                      child: Stack(
                        children: [
                          // عرض قائمة المنتجات الحالية إذا كانت موجودة
                          if (context
                              .read<CartCubit>()
                              .lastKnownItems
                              .isNotEmpty)
                            _buildCartList(
                              context,
                              context.read<CartCubit>().lastKnownItems,
                            ),

                          // طبقة شفافة مع مؤشر دوّار
                          Container(
                            color: Colors.black.withOpacity(0.1),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 16),
                                  Text(
                                    state.message,
                                    style: TextStyles.semiBold16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // عرض قائمة المنتجات عند توفرها
                  if (state is CartLoaded) {
                    if (state.cartItems.isEmpty) {
                      return Expanded(
                        child: EmptyCartView(
                          onBackToShopping: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => HomeScreen(initialTabIndex: 0),
                              ),
                              (route) => false,
                            );
                          },
                        ),
                      );
                    }

                    return Expanded(
                      child: _buildCartList(context, state.cartItems),
                    );
                  }

                  // حالات أخرى - استخدام آخر بيانات معروفة أو عرض السلة فارغة
                  final lastKnownItems =
                      context.read<CartCubit>().lastKnownItems;
                  if (lastKnownItems.isNotEmpty) {
                    return Expanded(
                      child: _buildCartList(context, lastKnownItems),
                    );
                  }

                  return Expanded(
                    child: EmptyCartView(
                      onBackToShopping: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => HomeScreen(initialTabIndex: 0),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                  );
                },
              ),
              // زر الشراء
              BlocBuilder<CartCubit, CartState>(
                builder: (context, state) {
                  // إظهار زر الشراء فقط إذا كانت هناك منتجات في السلة
                  final hasItems =
                      state is CartLoaded && state.cartItems.isNotEmpty ||
                      context.read<CartCubit>().lastKnownItems.isNotEmpty;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child:
                        hasItems
                            ? CustomButton(
                              onPressed:
                                  () => Navigator.pushNamed(
                                    context,
                                    CheckoutFlow.id,
                                  ),
                              text: 'شراء',
                              color: AppColors.kprimaryColor,
                            )
                            : const SizedBox(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة مساعدة لبناء قائمة منتجات السلة
  Widget _buildCartList(
    BuildContext context,
    List<Map<String, dynamic>> items,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return CartItemWidget(
          item: item,
          onRemove:
              () => context.read<CartCubit>().removeFromCart(item['productId']),
        );
      },
    );
  }
}

class EmptyCartView extends StatelessWidget {
  final VoidCallback? onBackToShopping;

  const EmptyCartView({super.key, required this.onBackToShopping});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: AppColors.klightGrayColor,
          ),
          const SizedBox(height: 24),
          const Text('عربة التسوق فارغة', style: TextStyles.semiBold16),
          const SizedBox(height: 12),
          const Text(
            'قم بإضافة بعض المنتجات إلى عربة التسوق الخاصة بك',
            style: TextStyles.regular13,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (onBackToShopping != null)
            CustomButton(
              onPressed: onBackToShopping!,
              text: 'استمر في التسوق',
              color: AppColors.kprimaryColor,
            ),
        ],
      ),
    );
  }
}

class CartItemWidget extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onRemove;

  const CartItemWidget({super.key, required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final productData = item['productData'] as Map<String, dynamic>;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.klightGrayColor),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Row(
        children: [
          Container(
            height: 100,
            width: 100,
            color: AppColors.kFillGrayColor,
            child: Image.network(
              productData['image_url'] ?? productData['imageUrl'] ?? '',
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) => const Icon(Icons.error),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        productData['name'] ?? 'منتج غير معروف',
                        style: TextStyles.semiBold16,
                      ),
                      IconButton(
                        onPressed: onRemove,
                        icon: const Icon(
                          Icons.delete_sweep,
                          color: AppColors.kRedColor,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    productData['description'] ?? 'لا يوجد وصف',
                    style: TextStyles.bold13.copyWith(
                      color: AppColors.kGrayColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الكمية: ${item['quantity']}',
                        style: TextStyles.bold13,
                      ),
                      Text(
                        '${item['totalPrice']} دينار',
                        style: TextStyles.bold16.copyWith(
                          color: AppColors.kprimaryColor,
                        ),
                      ),
                    ],
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
