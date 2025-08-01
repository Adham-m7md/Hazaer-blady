import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';

class LocationWidget extends StatelessWidget {
  const LocationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(AppColors.kFillGrayColor),
      ),
      onPressed: () {},
      icon: const Padding(
        padding: EdgeInsets.all(4.0),
        child: Icon(
          Icons.location_on,
          color: AppColors.kprimaryColor,
          size: 24,
        ),
      ),
    );
  }
}
