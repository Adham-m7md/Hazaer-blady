import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/functions/build_app_bar_with_arrow_back_button.dart';

class FarmerRequestOrdersScreen extends StatelessWidget {
  const FarmerRequestOrdersScreen({super.key});
  static const String id = '/farmer-request-orders-screen';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBarWithArrowBackButton(
        title: 'طلبات الحضيرة',
        context: context,
      ),
    );
  }
}
