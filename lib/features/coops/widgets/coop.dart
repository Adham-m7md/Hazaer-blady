import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hadaer_blady/core/services/rating_service.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_directions.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/core/widgets/custom_loading_indicator.dart';
import 'package:hadaer_blady/features/coops/presentation/coop_details.dart';
import 'package:hadaer_blady/features/rateing/cubit/rating_cubit.dart';
import 'package:hadaer_blady/features/rateing/cubit/rating_state.dart';

class Coop extends StatelessWidget {
  final String id;
  final String name;
  final String city;

  const Coop({
    super.key,
    required this.id,
    required this.name,
    required this.city,
  });

  @override
  Widget build(BuildContext context) {
    log('Building Coop widget with id: $id, name: $name');
    return GestureDetector(
      onTap: () {
        log('Navigating to CoopDetails with ID: "$id"');
        if (id.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CoopDetails(farmerId: id)),
          );
        } else {
          log('Invalid ID: ID is empty');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('معرف الحضيرة غير صالح')),
          );
        }
      },
      child: Container(
        width: context.screenWidth,
        decoration: BoxDecoration(
          color: AppColors.kFillGrayColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.lightPrimaryColor.withAlpha(40)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.kprimaryColor,
                    radius: 12.5,
                    child: const Icon(
                      Icons.person,
                      color: AppColors.kWiteColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(name, style: TextStyles.bold16),
                ],
              ),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppColors.kprimaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text.rich(
                    textAlign: TextAlign.right,
                    TextSpan(
                      style: TextStyles.regular16,
                      children: [
                        const TextSpan(text: 'المدينة :'),
                        TextSpan(text: city),
                      ],
                    ),
                  ),
                ],
              ),
              id.isEmpty
                  ? const Text(
                      'معرف الحضيرة غير متوفر',
                      style: TextStyles.regular16,
                    )
                  : BlocProvider(
                      create: (context) => RatingCubit(
                        ratingService: RatingService(),
                        auth: FirebaseAuth.instance,
                        userId: id,
                      ),
                      child: RatingDisplay(),
                    ),
              Row(
                children: [
                  const Icon(
                    Icons.local_offer_outlined,
                    color: AppColors.kRedColor,
                    size: 24,
                  ),
                  const SizedBox(width: 14),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('products')
                        .where('farmer_id', isEqualTo: id)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      if (snapshot.hasError || !snapshot.hasData) {
                        return Text.rich(
                          textAlign: TextAlign.right,
                          TextSpan(
                            style: TextStyles.regular16,
                            children: [
                              const TextSpan(text: 'اجمالي العروض :'),
                              const TextSpan(text: ' 0'),
                            ],
                          ),
                        );
                      }
                      final productCount = snapshot.data!.docs.length;
                      return Text.rich(
                        textAlign: TextAlign.right,
                        TextSpan(
                          style: TextStyles.regular16,
                          children: [
                            const TextSpan(text: 'اجمالي العروض :'),
                            TextSpan(text: ' $productCount'),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ويدجت منفصلة لعرض التقييمات
class RatingDisplay extends StatelessWidget {
  const RatingDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RatingCubit, RatingState>(
      builder: (context, state) {
        if (state is RatingLoadingState) {
          return const Center(child: CustomLoadingIndicator());
        }
        if (state is RatingErrorState) {
          log('Error fetching ratings: ${state.message}');
          return const Text(
            'خطأ في جلب التقييمات',
            style: TextStyles.regular16,
          );
        }
        double averageRating = 0.0;
        if (state is RatingSuccessState) {
          averageRating = state.averageRating;
        }
        return Row(
          children: [
            const Icon(Icons.star, color: Color(0xffFFC529), size: 24),
            const SizedBox(width: 12),
            Text.rich(
              textAlign: TextAlign.right,
              TextSpan(
                style: TextStyles.regular16,
                children: [
                  const TextSpan(text: 'التقييم :'),
                  TextSpan(text: ' ${averageRating.toStringAsFixed(1)}'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
