// bottom_nav_bar.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/services/farmer_request_order_service.dart';
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
                        scale: isSelected ? 1.1 : 0.9,
                        child:
                            entity.showBadge && isFarmer
                                ? NavigationBarWithBadge(
                                  isSelected: isSelected,
                                  navBarEntity: entity,
                                )
                                : CustomNavigationBarlogic(
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

class NavigationBarWithBadge extends StatelessWidget {
  final bool isSelected;
  final NavBarEntity navBarEntity;

  const NavigationBarWithBadge({
    super.key,
    required this.isSelected,
    required this.navBarEntity,
  });

  @override
  Widget build(BuildContext context) {
    final FarmerOrderService farmerOrderService = FarmerOrderService();

    return StreamBuilder<QuerySnapshot>(
      stream: farmerOrderService.getFarmerOrders(),
      builder: (context, snapshot) {
        int pendingOrdersCount = 0;

        if (snapshot.hasData && snapshot.data != null) {
          final pendingOrders =
              snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final status = data['status'] as String? ?? '';
                return status == 'pending';
              }).toList();

          pendingOrdersCount = pendingOrders.length;
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            CustomNavigationBarlogic(
              isSelected: isSelected,
              navBarEntity: navBarEntity,
            ),
            if (pendingOrdersCount > 0)
              Positioned(
                right: isSelected ? 25 : -5,
                top: isSelected ? 4 : -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.kRedColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    pendingOrdersCount > 99
                        ? '99+'
                        : pendingOrdersCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
