import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';

class InActiveIcon extends StatelessWidget {
  const InActiveIcon({super.key, required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Icon(icon, color: AppColors.kprimaryColor, size: 24);
  }
}
