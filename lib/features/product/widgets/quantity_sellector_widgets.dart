import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/features/product/cubit/product_details_cubit.dart';

class QuantitySelector extends StatelessWidget {
  final int quantity;

  const QuantitySelector({super.key, required this.quantity});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('الكمية: ', style: TextStyles.semiBold19),
        const Spacer(),
        GestureDetector(
          onTap: () => context.read<ProductDetailsCubit>().incrementQuantity(),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: AppColors.lightPrimaryColor.withAlpha(80),
            ),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Text('+50', style: TextStyles.semiBold16),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$quantity', style: TextStyles.semiBold19),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => context.read<ProductDetailsCubit>().decrementQuantity(),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(100)),
              color: AppColors.kGrayColor.withAlpha(40),
            ),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Text('-50', style: TextStyles.semiBold16),
            ),
          ),
        ),
      ],
    );
  }
}
