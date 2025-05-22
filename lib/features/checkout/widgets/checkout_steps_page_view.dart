import 'package:flutter/material.dart';
import 'package:hadaer_blady/features/checkout/presentation/checkout_1_data.dart';
import 'package:hadaer_blady/features/checkout/presentation/checkout_2_review.dart';

class CheckoutStepsPageView extends StatefulWidget {
  final PageController pageController;
  final GlobalKey<Checkout1DataState> checkout1DataKey;
  final ValueChanged<int> onPageChanged;
  final Map<String, String>? userData;
  final Function(Map<String, String>)? onDataSubmitted;
  final List<Map<String, dynamic>> selectedItems;

  const CheckoutStepsPageView({
    super.key,
    required this.pageController,
    required this.checkout1DataKey,
    required this.onPageChanged,
    this.userData,
    this.onDataSubmitted,
    required this.selectedItems,
  });

  @override
  State<CheckoutStepsPageView> createState() => _CheckoutStepsPageViewState();
}

class _CheckoutStepsPageViewState extends State<CheckoutStepsPageView> {
  late List<Map<String, dynamic>> _selectedItems;

  @override
  void initState() {
    super.initState();
    _selectedItems = widget.selectedItems;
    debugPrint(
      'CheckoutStepsPageView: Initialized with selectedItems = $_selectedItems',
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      'CheckoutStepsPageView: Building with selectedItems = $_selectedItems',
    );
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: widget.pageController,
        onPageChanged: widget.onPageChanged,
        children: [
          Checkout1Data(
            key: widget.checkout1DataKey,
            onDataSubmitted: widget.onDataSubmitted,
          ),
          Checkout2Review(
            userData: widget.userData,
            selectedItems: _selectedItems,
          ),
        ],
      ),
    );
  }
}
