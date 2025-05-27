import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';

class LocationInfo extends StatelessWidget {
  final Map<String, dynamic>? farmerData;

  const LocationInfo({super.key, required this.farmerData});

  @override
  Widget build(BuildContext context) {
    // Extract city and address with proper null safety and empty string handling
    final String city =
        (farmerData?['city']?.toString() ?? '').isEmpty
            ? 'المدينة غير محددة'
            : farmerData!['city'].toString();
    final String address =
        (farmerData?['address']?.toString() ?? '').isEmpty
            ? 'العنوان غير محدد'
            : farmerData!['address'].toString();

    return Row(
      children: [
        const Icon(
          Icons.near_me_outlined,
          color: AppColors.kprimaryColor,
          size: 28,
        ),
        const SizedBox(width: 8),
        Text(
          '($city - $address)',
          style: TextStyles.semiBold13.copyWith(color: AppColors.kGrayColor),
        ),
      ],
    );
  }
}
