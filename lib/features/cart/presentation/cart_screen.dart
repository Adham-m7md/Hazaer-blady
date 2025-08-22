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
                  if (state is CartSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }

                  if (state is CartError) {
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
                  if (state is CartLoading) {
                    return const Expanded(
                      child: Center(child: CustomLoadingIndicator()),
                    );
                  }

                  if (state is CartUpdating) {
                    return Expanded(
                      child: Stack(
                        children: [
                          if (context
                              .read<CartCubit>()
                              .lastKnownItems
                              .isNotEmpty)
                            _buildCartList(
                              context,
                              context.read<CartCubit>().lastKnownItems,
                            ),
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

                  if (state is CartLoaded) {
                    if (state.cartItems.isEmpty) {
                      return Expanded(
                        child: EmptyCartView(
                          onBackToShopping: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        const HomeScreen(initialTabIndex: 0),
                              ),
                              (route) => false,
                            );
                          },
                        ),
                      );
                    }

                    return Expanded(
                      child: Column(
                        children: [
                          // أزرار تحديد الكل وإلغاء تحديد الكل
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    context.read<CartCubit>().selectAllItems();
                                  },
                                  child: const Text(
                                    'تحديد الكل',
                                    style: TextStyles.regular13,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    context
                                        .read<CartCubit>()
                                        .deselectAllItems();
                                  },
                                  child: const Text(
                                    'إلغاء تحديد الكل',
                                    style: TextStyles.regular13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _buildCartList(context, state.cartItems),
                          ),
                        ],
                      ),
                    );
                  }

                  final lastKnownItems =
                      context.read<CartCubit>().lastKnownItems;
                  if (lastKnownItems.isNotEmpty) {
                    return Expanded(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    context.read<CartCubit>().selectAllItems();
                                  },
                                  child: const Text(
                                    'تحديد الكل',
                                    style: TextStyles.regular13,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    context
                                        .read<CartCubit>()
                                        .deselectAllItems();
                                  },
                                  child: Text(
                                    'إلغاء تحديد الكل',
                                    style: TextStyles.regular13.copyWith(
                                      color: AppColors.kRedColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _buildCartList(context, lastKnownItems),
                          ),
                        ],
                      ),
                    );
                  }

                  return Expanded(
                    child: EmptyCartView(
                      onBackToShopping: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    const HomeScreen(initialTabIndex: 0),
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
                  final hasItems =
                      state is CartLoaded && state.cartItems.isNotEmpty ||
                      context.read<CartCubit>().lastKnownItems.isNotEmpty;
                  final hasSelectedItems =
                      context.read<CartCubit>().selectedItems.isNotEmpty;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child:
                        hasItems
                            ? CustomCartButton(
                              onPressed: () {
                                final selectedItems =
                                    context
                                        .read<CartCubit>()
                                        .getSelectedItems();
                                debugPrint(
                                  'CartScreen: Navigating to CheckoutFlow with selectedItems = $selectedItems',
                                );
                                Navigator.pushNamed(
                                  context,
                                  CheckoutFlow.id,
                                  arguments: selectedItems,
                                );
                              },
                              text: 'شراء',
                              itemCount:
                                  context
                                      .read<CartCubit>()
                                      .selectedItems
                                      .length,
                              enabled: hasSelectedItems,
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
          isSelected: context.read<CartCubit>().selectedItems.contains(
            item['productId'],
          ),
          onToggleSelection: () {
            context.read<CartCubit>().toggleItemSelection(item['productId']);
          },
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
              onPressed: onBackToShopping,
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
  final bool isSelected;
  final VoidCallback onToggleSelection;
  final VoidCallback onRemove;

  const CartItemWidget({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onToggleSelection,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final productData = item['productData'] as Map<String, dynamic>;

    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.klightGrayColor),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            onChanged: (value) => onToggleSelection(),
            activeColor: AppColors.kprimaryColor,
          ),
          Container(
            width: 50,
            height: 50,
            color: AppColors.kFillGrayColor,
            child: Image.network(
              productData['image_url'] ?? productData['imageUrl'] ?? '',
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) => const Icon(Icons.error),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                spacing: 4,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          productData['name'] ?? 'منتج غير معروف',
                          style: TextStyles.semiBold16,
                          overflow: TextOverflow.ellipsis,
                        ),
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

                  Text(
                    '${productData['price'] ?? productData['price_per_kg'] ?? 0}',
                    style: TextStyles.bold16.copyWith(
                      color: AppColors.kprimaryColor,
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
