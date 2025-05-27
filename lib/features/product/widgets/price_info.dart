import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';

class PriceInfo extends StatelessWidget {
  final double pricePerKg;

  const PriceInfo({super.key, required this.pricePerKg});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('السعر للكيلو: ', style: TextStyles.semiBold16),
        Text('$pricePerKg دينار', style: TextStyles.semiBold16),
      ],
    );
  }
}
