// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:hadaer_blady/core/services/firebase_auth_service.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/features/product/cubit/product_details_cubit.dart';
import 'package:hadaer_blady/features/product/widgets/product_ditails_view.dart';

class ProductDetailsScreen extends StatelessWidget {
  final String productId;
  final Map<String, dynamic> product;

  const ProductDetailsScreen({
    super.key,
    required this.productId,
    required this.product,
  });

  static const id = 'ProductScreen';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) =>
              ProductDetailsCubit(GetIt.instance<FirebaseAuthService>())
                ..fetchProductData(productId, product),
      child: Scaffold(
        backgroundColor: AppColors.kWiteColor,
        body: SafeArea(child: ProductDetailsView(productId: productId)),
      ),
    );
  }
}
