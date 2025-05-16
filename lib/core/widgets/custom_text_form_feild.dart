// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';

class CustomTextFormFeild extends StatelessWidget {
  const CustomTextFormFeild({
    super.key,
    required this.hintText,
    this.suffixIcon,
    required this.keyBoardType,
    this.onSaved,
    this.validator,
    this.obscureText = false,
    this.controller,
    this.enabled = true,
    this.maxLines,
  });
  final String hintText;
  final Widget? suffixIcon;
  final TextInputType keyBoardType;
  final void Function(String?)? onSaved;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextEditingController? controller;
  final bool enabled;
  final int? maxLines;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      enabled: enabled,
      obscureText: obscureText,
      validator: validator,
      onSaved: onSaved,
      keyboardType: keyBoardType,
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.kFillGrayColor,
        border: BuildBorder(),
        enabledBorder: BuildBorder(),
        focusedBorder: BuildBorder(),
        hintText: hintText,
        hintStyle: TextStyles.bold13.copyWith(color: AppColors.kGrayColor),
        suffixIcon: suffixIcon,
      ),
    );
  }

  OutlineInputBorder BuildBorder() {
    return const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(width: 1, color: AppColors.klightGrayColor),
    );
  }
}
