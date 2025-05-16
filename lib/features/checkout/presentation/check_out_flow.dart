import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hadaer_blady/features/cart/cubit/cart_cubit.dart';
import 'package:hadaer_blady/features/checkout/presentation/checkout_screen.dart';

class CheckoutFlow extends StatelessWidget {
  const CheckoutFlow({super.key});

  static const id = 'CheckoutFlow';

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CartCubit>(
      create: (context) => CartCubit()..loadCartItems(),
      child: const CheckoutScreen(),
    );
  }
}
