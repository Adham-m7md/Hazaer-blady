import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/core/utils/svg_images.dart' show Assets;
import 'package:hadaer_blady/core/widgets/custom_button.dart';
import 'package:hadaer_blady/features/home/presentation/home_screen.dart';

class CongratesScreen extends StatelessWidget {
  static const id = 'CongratesScreen';
  final String orderNumber;

  const CongratesScreen({super.key, required this.orderNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kWiteColor,

      body: Center(
        child: Column(
          spacing: 20,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('تهانينا', style: TextStyles.bold23),
            const SizedBox(height: 20),
            SvgPicture.asset(Assets.imagesCongrates),
            const SizedBox(height: 40),
            const Text('تم إرسال طلبك بنجاح', style: TextStyles.bold19),
            const Text(
              'سيتم التواصل معك من قبل صاحب الحظيرة ',
              style: TextStyles.bold16,
            ),

            Text(
              'رقم الطلب: $orderNumber',
              style: TextStyles.bold16.copyWith(color: AppColors.kGrayColor),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CustomButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    HomeScreen.id,
                    (route) => false,
                  );
                },
                text: 'العودة للرئيسية',
                color: AppColors.kprimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
