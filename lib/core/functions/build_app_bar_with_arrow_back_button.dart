import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';

AppBar buildAppBarWithArrowBackButton({
  required String title,
  required BuildContext context,
}) {
  return AppBar(
    title: Text(title, style: TextStyles.bold19),
    centerTitle: true,
    backgroundColor: AppColors.kWiteColor,
    automaticallyImplyLeading: false,
    actions: [
      IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.arrow_forward_ios_outlined),
      ),
    ],
  );
}
