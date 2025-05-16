import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';

class ActiveIcon extends StatelessWidget {
  const ActiveIcon({super.key, required this.icon, required this.name});
  final IconData icon;
  final String name;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.only(left: 16),
        decoration: ShapeDecoration(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(30)),
          ),
          color: AppColors.lightPrimaryColor.withAlpha(40),
        ),

        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const ShapeDecoration(
                color: AppColors.kprimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                ),
              ),
              child: Center(child: Icon(icon, color: AppColors.kWiteColor)),
            ),
            const SizedBox(width: 4),
            Text(
              name,
              style: TextStyles.semiBold13.copyWith(
                color: AppColors.kprimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
