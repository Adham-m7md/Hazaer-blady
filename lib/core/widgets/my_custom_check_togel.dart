import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_directions.dart';

class MyCustomCheckTogel extends StatelessWidget {
  final bool isActive;
  final Function() onChanged;

  const MyCustomCheckTogel({
    super.key,
    required this.isActive,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.screenHeight * 0.028,
      width: context.screenWidth * 0.11,
      decoration: BoxDecoration(
        color: AppColors.kWiteColor,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.klightGrayColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: InkWell(
          onTap: onChanged,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              isActive
                  ? Container(
                    height: context.screenHeight * 0.025,
                    width: context.screenWidth * 0.05,
                    decoration: const BoxDecoration(
                      color: AppColors.kprimaryColor,
                      shape: BoxShape.circle,
                    ),
                  )
                  : const SizedBox(),
              isActive
                  ? const SizedBox()
                  : Container(
                    height: context.screenHeight * 0.025,
                    width: context.screenWidth * 0.05,
                    decoration: const BoxDecoration(
                      color: AppColors.kGrayColor,
                      shape: BoxShape.circle,
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
