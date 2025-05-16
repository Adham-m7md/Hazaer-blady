// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

class NavBarEntity {
  final IconData activeIcon, inActiveIcon;
  final String name;
  final bool isForFarmerOnly;

  NavBarEntity({
    required this.activeIcon,
    required this.inActiveIcon,
    required this.name,
    this.isForFarmerOnly = false,
  });
}

List<NavBarEntity> get navBarItems => [
  NavBarEntity(
    activeIcon: Icons.home,
    inActiveIcon: Icons.home_outlined,
    name: 'الرئيسية',
  ),
  NavBarEntity(
    activeIcon: Icons.store,
    inActiveIcon: Icons.store_outlined,
    name: 'الحضائر',
  ),

  NavBarEntity(
    activeIcon: Icons.add,
    inActiveIcon: Icons.add_circle_outline,
    name: 'إضافة منتج',
    isForFarmerOnly: true,
  ),
  NavBarEntity(
    activeIcon: Icons.shopping_cart,
    inActiveIcon: Icons.shopping_cart_outlined,
    name: 'عربة التسوق',
  ),
  NavBarEntity(
    activeIcon: Icons.person,
    inActiveIcon: Icons.person_outlined,
    name: 'حسابي',
  ),
];
