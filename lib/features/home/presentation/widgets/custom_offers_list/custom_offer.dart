// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/features/add_custom_product/presentation/custom_product_screen_details.dart';
import 'package:hadaer_blady/features/home/presentation/widgets/custom_offers_list/offer_carousel.dart';

class CustomOffer extends StatelessWidget {
  final OfferModel offer;
  final CustomProduct product;
  final VoidCallback? onButtonPressed;

  const CustomOffer({
    super.key,
    required this.offer,
    required this.product,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        offer.backgroundColor ?? AppColors.kprimaryColor.withOpacity(0.1);
    final overlayColor = offer.overlayColor ?? AppColors.kprimaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.lightPrimaryColor, width: 1),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [backgroundColor, Colors.white],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.kprimaryColor.withAlpha(30),
              blurRadius: 6,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Background decoration
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: overlayColor.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                left: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: overlayColor.withOpacity(0.15),
                  ),
                ),
              ),

              // Main content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Offer information
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Title badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: overlayColor.withOpacity(0.9),
                            ),
                            child: Text(
                              offer.title,
                              style: TextStyles.semiBold13.copyWith(
                                color: AppColors.kWiteColor,
                              ),
                              maxLines: 1,
                            ),
                          ),
                          // Offer description
                          Text(
                            offer.description,
                            style: TextStyles.bold16.copyWith(
                              color: Colors.black87,
                              height: 1.2,
                            ),
                            maxLines: 1,
                          ),
                          // Shop button
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                CustomProductDetailScreen.id,
                                arguments: product,
                              );
                              onButtonPressed?.call();
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: AppColors.lightPrimaryColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.lightPrimaryColor
                                        .withOpacity(0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      offer.buttonText,
                                      style: TextStyles.semiBold13.copyWith(
                                        color: AppColors.kWiteColor,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      color: AppColors.kWiteColor,
                                      size: 12,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Product image
                    Hero(
                      tag: 'offer_${offer.title}',
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: AppColors.kFillGrayColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child:
                              product.imageUrl.isNotEmpty
                                  ? Image.network(
                                    product.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      debugPrint('Image load error: $error');
                                      return const Center(
                                        child: Text(
                                          'لا يوجد صورة',
                                          style: TextStyles.semiBold16,
                                          textAlign: TextAlign.center,
                                        ),
                                      );
                                    },
                                    loadingBuilder: (
                                      context,
                                      child,
                                      loadingProgress,
                                    ) {
                                      if (loadingProgress == null) {
                                        return child;
                                      }
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value:
                                              loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                  : null,
                                          color: AppColors.kprimaryColor,
                                          strokeWidth: 2,
                                        ),
                                      );
                                    },
                                  )
                                  : const Center(
                                    child: Icon(
                                      Icons.shopping_basket,
                                      size: 42,
                                      color: Colors.black38,
                                    ),
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Featured offer badge
              if (offer.title.contains('العيد') || offer.title.contains('حصري'))
                Positioned(
                  top: 0,
                  left: 20,
                  child: Transform.rotate(
                    angle: -0.2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                      ),
                      child: Text(
                        'حصري',
                        style: TextStyles.semiBold13.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
