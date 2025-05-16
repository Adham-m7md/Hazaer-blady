import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';

class WeightInfo extends StatelessWidget {
  final double minWeight;
  final double maxWeight;

  const WeightInfo({
    super.key,
    required this.minWeight,
    required this.maxWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('الوزن لكل وحدة: ', style: TextStyles.semiBold19),
        Text('$minWeight~$maxWeight كيلو', style: TextStyles.semiBold19),
      ],
    );
  }
}
