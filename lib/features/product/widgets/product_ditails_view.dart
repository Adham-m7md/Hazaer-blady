import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/core/widgets/custom_loading_indicator.dart'
    show CustomLoadingIndicator;
import 'package:hadaer_blady/features/product/cubit/product_details_cubit.dart';
import 'package:hadaer_blady/features/product/cubit/product_details_state.dart';
import 'package:hadaer_blady/features/product/widgets/product_details_content.dart';

class ProductDetailsView extends StatelessWidget {
  final String productId;

  const ProductDetailsView({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    if (productId.isEmpty) {
      return _buildInvalidProductIdView(context);
    }

    return BlocBuilder<ProductDetailsCubit, ProductDetailsState>(
      builder: (context, state) {
        if (state.status == ProductDetailsStatus.error) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'خطأ غير معروف')),
            );
          });
          return const Center(child: Text('حدث خطأ، يرجى المحاولة لاحقًا'));
        }

        if (state.productData == null ||
            state.status == ProductDetailsStatus.loading) {
          return const Center(child: CustomLoadingIndicator());
        }

        return FutureBuilder<Map<String, dynamic>>(
          future: context.read<ProductDetailsCubit>().fetchFarmerData(
            state.productData!['farmer_id'] ?? '',
          ),
          builder: (context, farmerSnapshot) {
            return ProductDetailsContent(
              productData: state.productData!,
              farmerData: farmerSnapshot.data,
              quantity: state.quantity,
            );
          },
        );
      },
    );
  }

  Widget _buildInvalidProductIdView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('معرف المنتج غير صالح', style: TextStyles.semiBold19),
          const SizedBox(height: 16),
          const Text(
            'يرجى المحاولة مرة أخرى أو التواصل مع الدعم',
            style: TextStyles.semiBold16,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('العودة'),
          ),
        ],
      ),
    );
  }
}
