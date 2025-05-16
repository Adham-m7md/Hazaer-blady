import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_directions.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';

class ProductImage extends StatelessWidget {
  final String imageUrl;
  final BuildContext context;

  const ProductImage({
    super.key,
    required this.imageUrl,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Check if the imageUrl is empty or null before trying to load it
        imageUrl.isNotEmpty
            ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              height: context.screenHeight * 0.3,
              width: double.infinity,
              errorBuilder:
                  (context, error, stackTrace) => _buildErrorContainer(context),
            )
            : _buildErrorContainer(context),
        Positioned(
          top: 16,
          left: 12,
          child: IconButton.outlined(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(
                AppColors.kWiteColor.withAlpha(50),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            icon: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.arrow_forward_ios_outlined,
                color: AppColors.kBlackColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Extract the error container to a separate method to avoid code duplication
  Widget _buildErrorContainer(BuildContext context) {
    return Container(
      height: context.screenHeight * 0.3,
      color: AppColors.kFillGrayColor,
      child: const Center(
        child: Text('لا يوجد صورة لتحميلها ', style: TextStyles.semiBold16),
      ),
    );
  }
}
