import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';

AppBar buildAppBar({required String title}) {
  return AppBar(
    title: Text(title, style: TextStyles.bold19),
    centerTitle: true,
    backgroundColor: AppColors.kWiteColor,
    automaticallyImplyLeading: false,
  );
}
