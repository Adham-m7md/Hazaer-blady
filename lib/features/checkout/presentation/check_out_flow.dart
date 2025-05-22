import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hadaer_blady/features/cart/cubit/cart_cubit.dart';
import 'package:hadaer_blady/features/checkout/presentation/checkout_screen.dart';

class CheckoutFlow extends StatelessWidget {
  const CheckoutFlow({super.key});

  static const id = 'CheckoutFlow';

  @override
  Widget build(BuildContext context) {
    // استقبال المنتجات المختارة من arguments
    final selectedItems =
        ModalRoute.of(context)?.settings.arguments
            as List<Map<String, dynamic>>? ??
        [];
    debugPrint('CheckoutFlow: selectedItems = $selectedItems'); // إضافة تسجيل
    return BlocProvider<CartCubit>(
      create: (context) => CartCubit()..loadCartItems(),
      child: CheckoutScreen(selectedItems: selectedItems),
    );
  }
}
