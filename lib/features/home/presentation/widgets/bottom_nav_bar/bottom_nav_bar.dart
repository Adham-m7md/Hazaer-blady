import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/features/home/domain/entitis/nav_bar_entity.dart';
import 'package:hadaer_blady/features/home/presentation/widgets/bottom_nav_bar/navigation_bar.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isFarmer;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.isFarmer,
  });

  @override
  Widget build(BuildContext context) {
    final filteredNavBarItems =
        navBarItems
            .asMap()
            .entries
            .where((entry) => !entry.value.isForFarmerOnly || isFarmer)
            .map((entry) => entry.value)
            .toList();

    print(
      'Filtered NavBar Items: ${filteredNavBarItems.asMap().entries.map((e) => "${e.key}: ${e.value.name}").toList()}',
    );

    return SafeArea(
      child: Container(
        height: 70,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          border: Border.all(width: 1, color: AppColors.klightGrayColor),
          color: AppColors.kWiteColor,
        ),
        child: Row(
          children:
              filteredNavBarItems.asMap().entries.map((entry) {
                final index = entry.key;
                final entity = entry.value;
                final isSelected = currentIndex == index;

                return Expanded(
                  flex: isSelected ? (isFarmer ? 5 : 4) : 2,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      print('Tapped index: $index, item: ${entity.name}');
                      onTap(index);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.linear,
                      margin:
                          isSelected
                              ? const EdgeInsets.symmetric(vertical: 8)
                              : EdgeInsets.zero,

                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 100),
                        scale: isSelected ? 1.1 : 1.0,
                        child: CustomNavigationBarlogic(
                          isSelected: isSelected,
                          navBarEntity: entity,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}
