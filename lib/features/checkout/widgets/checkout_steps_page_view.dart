import 'package:flutter/material.dart';
import 'package:hadaer_blady/features/checkout/presentation/checkout_1_data.dart';
import 'package:hadaer_blady/features/checkout/presentation/checkout_2_review.dart';

class CheckoutStepsPageView extends StatelessWidget {
  final PageController pageController;
  final Function(int) onPageChanged;
  final GlobalKey<Checkout1DataState> checkout1DataKey;
  final Map<String, String>? userData;
  final Function(Map<String, String>) onDataSubmitted;

  const CheckoutStepsPageView({
    super.key,
    required this.pageController,
    required this.onPageChanged,
    required this.checkout1DataKey,
    required this.onDataSubmitted,
    this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: PageView(
        controller: pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: onPageChanged,
        children: [
          Checkout1Data(
            key: checkout1DataKey,
            onDataSubmitted: onDataSubmitted,
          ),
          Checkout2Review(userData: userData),
        ],
      ),
    );
  }
}
