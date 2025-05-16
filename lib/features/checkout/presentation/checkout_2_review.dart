import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hadaer_blady/core/constants.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_directions.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/core/widgets/custom_tittel.dart';
import 'package:hadaer_blady/features/cart/cubit/cart_cubit.dart';

class Checkout2Review extends StatelessWidget {
  final Map<String, String>? userData;

  const Checkout2Review({super.key, this.userData});

  @override
  Widget build(BuildContext context) {
    // استخدام الـ CartCubit الموجود بالفعل في شجرة الـ widget
    // بدلاً من إنشاء نسخة جديدة
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        if (state is CartLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is CartError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('خطأ: ${state.message}'),
                ElevatedButton(
                  onPressed: () {
                    context.read<CartCubit>().loadCartItems(); // إعادة المحاولة
                  },
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        final cartItems = state is CartLoaded ? state.cartItems : [];
        final totalPrice = cartItems.fold<double>(
          0,
          (sum, item) => sum + (item['totalPrice'] as num).toDouble(),
        );

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(khorizintalPadding),
            child: Column(
              children: [
                const CustomTittel(text: 'ملخص الطلب :'),
                SizedBox(height: context.screenHeight * 0.02),
                Container(
                  color: AppColors.kFillGrayColor,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (cartItems.isEmpty)
                        const Text('السلة فارغة', style: TextStyles.semiBold16)
                      else
                        ...cartItems.map((item) {
                          final productData =
                              item['productData'] as Map<String, dynamic>;
                          return Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    productData['name'] ?? 'منتج غير معروف',
                                    style: TextStyles.semiBold16,
                                  ),
                                  Text(
                                    '${item['totalPrice']} دينار',
                                    style: TextStyles.bold13,
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: const Divider(
                                  color: AppColors.kGrayColor,
                                  thickness: 0.4,
                                ),
                              ),
                            ],
                          );
                        }),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('الإجمالي:', style: TextStyles.bold16),
                          Text('$totalPrice دينار', style: TextStyles.bold16),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.screenHeight * 0.02),
                const CustomTittel(text: 'يرجى التأكد من العنوان'),
                SizedBox(height: context.screenHeight * 0.02),
                Container(
                  color: AppColors.kFillGrayColor,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'عنوان التوصيل:',
                            style: TextStyles.bold13,
                          ),
                          IconButton(
                            onPressed: () {
                              // العودة إلى الخطوة الأولى لتعديل العنوان
                              final pageController =
                                  context
                                      .findAncestorWidgetOfExactType<PageView>()
                                      ?.controller;
                              if (pageController != null) {
                                pageController.jumpToPage(0);
                              }
                            },
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: AppColors.kGrayColor,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.location_on,
                              color: AppColors.kGrayColor,
                              size: 24,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              userData != null
                                  ? '${userData!['name']} - ${userData!['city']} - ${userData!['address']}'
                                  : 'لم يتم إدخال عنوان',
                              style: TextStyles.semiBold13.copyWith(
                                color: AppColors.kGrayColor,
                              ),
                            ),
                          ),
                        ],
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
