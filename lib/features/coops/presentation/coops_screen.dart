import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/constants.dart';
import 'package:hadaer_blady/core/services/farmer_service.dart';
import 'package:hadaer_blady/core/services/get_it.dart';
import 'package:hadaer_blady/core/services/location_service.dart';
import 'package:hadaer_blady/core/services/rating_service.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/features/coops/widgets/coops_screen_filter_widgets.dart';

class CoopsScreen extends StatefulWidget {
  const CoopsScreen({super.key});
  static const String id = 'CoopsScreen';

  @override
  _CoopsScreenState createState() => _CoopsScreenState();
}

class _CoopsScreenState extends State<CoopsScreen> {
  final FarmerService farmerService = getIt<FarmerService>();
  final LocationService locationService = getIt<LocationService>();
  final RatingService ratingService = RatingService();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(
          right: khorizintalPadding,
          left: khorizintalPadding,
          top: 12,
        ),
        child: Column(
          children: [
            const Text('الحظائر', style: TextStyles.bold19),
            const SizedBox(height: 8),
            Expanded(
              child: CoopsFilterWidget(
                farmerService: farmerService,
                locationService: locationService,
                ratingService: ratingService,
              ),
            ),
          ],
        ),
      ),
    );
  }
}