// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:hadaer_blady/core/constants.dart';
// import 'package:hadaer_blady/core/services/cart_service.dart';
// import 'package:hadaer_blady/core/services/get_it.dart';
// import 'package:hadaer_blady/core/utils/app_colors.dart';
// import 'package:hadaer_blady/core/utils/app_directions.dart';
// import 'package:hadaer_blady/core/utils/app_text_styles.dart';
// import 'package:hadaer_blady/core/widgets/custom_button.dart';
// import 'package:hadaer_blady/features/checkout/presentation/checkout_screen.dart';

// class CartScreen extends StatelessWidget {
//   const CartScreen({super.key});
//   static const String id = '/cart-screen';

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (context) => CartCubit(getIt<CartService>()),
//       child: Builder(
//         builder: (context) {
//           return SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.only(
//                 right: khorizintalPadding,
//                 left: khorizintalPadding,
//                 top: 12,
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text('عربة التسوق', style: TextStyles.bold19),
//                       ClearCartButton(),
//                     ],
//                   ),
//                   BlocBuilder<CartCubit, CartState>(
//                     builder: (context, state) {
//                       if (state is CartLoading) {
//                         return const Expanded(
//                           child: Center(
//                             child: CircularProgressIndicator(),
//                           ),
//                         );
//                       } else if (state is CartLoaded) {
//                         return state.cartItems.isEmpty
//                             ? const EmptyCartWidget()
//                             : Expanded(
//                                 child: Column(
//                                   children: [
//                                     SizedBox(height: context.screenHeight * 0.02),
//                                     Expanded(
//                                       child: ListView.builder(
//                                         itemCount: state.cartItems.length,
//                                         itemBuilder: (context, index) {
//                                           final cartItem = state.cartItems[index];
//                                           return Padding(
//                                             padding: const EdgeInsets.only(bottom: 8),
//                                             child: CartItemWidget(cartItem: cartItem),
//                                           );
//                                         },
//                                       ),
//                                     ),
//                                     CartSummary(totalPrice: state.totalPrice),
//                                     SizedBox(height: context.screenHeight * 0.02),
//                                     CustomButton(
//                                       onPressed: state.cartItems.isEmpty
//                                           ? null
//                                           : () {
//                                               Navigator.pushNamed(
//                                                 context,
//                                                 CheckoutScreen.id,
//                                                 arguments: {
//                                                   'cartItems': state.cartItems,
//                                                   'totalPrice': state.totalPrice,
//                                                 },
//                                               );
//                                             },
//                                       text: 'متابعة الشراء',
//                                       isDisabled: state.cartItems.isEmpty,
//                                     ),
//                                     SizedBox(height: context.screenHeight * 0.02),
//                                   ],
//                                 ),
//                               );
//                       } else if (state is CartError) {
//                         return Expanded(
//                           child: Center(
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Text(
//                                   state.message,
//                                   style: TextStyles.semiBold16.copyWith(
//                                     color: AppColors.kRedColor,
//                                   ),
//                                   textAlign: TextAlign.center,
//                                 ),
//                                 const SizedBox(height: 16),
//                                 CustomButton(
//                                   onPressed: () {
//                                     context.read<CartCubit>().loadCart();
//                                   },
//                                   text: 'إعادة المحاولة',
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       }
//                       return const EmptyCartWidget();
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// class ClearCartButton extends StatelessWidget {
//   const ClearCartButton({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<CartCubit, CartState>(
//       builder: (context, state) {
//         if (state is CartLoaded && state.cartItems.isNotEmpty) {
//           return TextButton.icon(
//             onPressed: () {
//               _showClearCartConfirmation(context);
//             },
//             icon: const Icon(
//               Icons.delete_sweep,
//               color: AppColors.kRedColor,
//               size: 18,
//             ),
//             label: Text(
//               'إفراغ السلة',
//               style: TextStyles.semiBold13.copyWith(
//                 color: AppColors.kRedColor,
//               ),
//             ),
//           );
//         }
//         return const SizedBox.shrink();
//       },
//     );
//   }

//   void _showClearCartConfirmation(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('إفراغ السلة'),
//         content: const Text('هل أنت متأكد من إفراغ جميع المنتجات من السلة؟'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('إلغاء'),
//           ),
//           TextButton(
//             onPressed: () {
//               context.read<CartCubit>().clearCart();
//               Navigator.pop(context);
//             },
//             child: Text(
//               'إفراغ',
//               style: TextStyles.semiBold13.copyWith(
//                 color: AppColors.kRedColor,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class CartSummary extends StatelessWidget {
//   final double totalPrice;

//   const CartSummary({super.key, required this.totalPrice});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         border: Border.all(color: AppColors.klightGrayColor),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text('إجمالي السلة', style: TextStyles.semiBold16),
//               Text(
//                 '${totalPrice.toStringAsFixed(2)} دينار',
//                 style: TextStyles.bold16.copyWith(
//                   color: AppColors.kprimaryColor,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
