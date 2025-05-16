import 'package:flutter/material.dart';
import 'package:hadaer_blady/features/home/domain/entitis/nav_bar_entity.dart';
import 'package:hadaer_blady/features/home/presentation/widgets/bottom_nav_bar/active_icon.dart';
import 'package:hadaer_blady/features/home/presentation/widgets/bottom_nav_bar/in_active_icon.dart';

class CustomNavigationBarlogic extends StatelessWidget {
  const CustomNavigationBarlogic({
    super.key,
    required this.isSelected,
    required this.navBarEntity,
  });
  final bool isSelected;
  final NavBarEntity navBarEntity;
  @override
  Widget build(BuildContext context) {
    return isSelected
        ? ActiveIcon(icon: navBarEntity.activeIcon, name: navBarEntity.name)
        : InActiveIcon(icon: navBarEntity.inActiveIcon);
  }
}
