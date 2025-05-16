import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';

class CustomTittel extends StatelessWidget {
  const CustomTittel({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Row(children: [Text(text, style: TextStyles.semiBold16)]);
  }
}
