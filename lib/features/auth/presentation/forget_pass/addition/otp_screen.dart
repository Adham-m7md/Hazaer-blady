import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/constants.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_directions.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/core/widgets/custom_button.dart';
import 'package:hadaer_blady/core/widgets/otp_form.dart';
import 'package:hadaer_blady/features/auth/presentation/forget_pass/addition/change_new_pass.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});
  static const String id = 'OtpScreen';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kWiteColor,
      appBar: AppBar(
        backgroundColor: AppColors.kWiteColor,
        centerTitle: true,
        title: const Text('التحقق من الرمز', style: TextStyles.bold19),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios_outlined),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: khorizintalPadding),
          child: Column(
            children: [
              SizedBox(height: context.screenHeight * 0.02),
              Row(
                children: [
                  Text(
                    'أدخل الرمز الذي أرسلناه إلى رقم هاتفك',
                    style: TextStyles.semiBold16.copyWith(
                      color: AppColors.kGrayColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.screenHeight * 0.03),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [OtpForm(), OtpForm(), OtpForm(), OtpForm()],
              ),
              SizedBox(height: context.screenHeight * 0.03),
              CustomButton(
                onPressed: () {
                  Navigator.pushNamed(context, ChangeNewPass.id);
                },
                text: 'تحقق من الرمز',
              ),
              SizedBox(height: context.screenHeight * 0.03),
              Text(
                'إعادة إرسال الرمز',
                style: TextStyles.semiBold16.copyWith(
                  color: AppColors.lightPrimaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
