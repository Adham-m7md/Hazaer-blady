import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hadaer_blady/core/constants.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_directions.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/core/utils/svg_images.dart';
import 'package:hadaer_blady/core/widgets/custom_button.dart';
import 'package:hadaer_blady/core/widgets/custome_password_feild.dart';
import 'package:hadaer_blady/features/auth/presentation/signin/view/signin_screen.dart';

class ChangeNewPass extends StatelessWidget {
  const ChangeNewPass({super.key});
  static const String id = 'ChangeNewPass';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kWiteColor,
      appBar: AppBar(
        backgroundColor: AppColors.kWiteColor,
        title: const Text('كلمة مرور جديدة', style: TextStyles.bold19),
        centerTitle: true,
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
              Text(
                'قم بإنشاء كلمة مرور جديدة لتسجيل الدخول',

                style: TextStyles.semiBold16.copyWith(
                  color: AppColors.kGrayColor,
                ),
              ),
              SizedBox(height: context.screenHeight * 0.04),
              CustomPasswordFeild(
                onSaved: (value) {},
                name: 'كلمة المرور الجديدة',
              ),
              SizedBox(height: context.screenHeight * 0.02),
              CustomPasswordFeild(
                onSaved: (value) {},
                name: 'تاكيد كلمة المرور ',
              ),
              SizedBox(height: context.screenHeight * 0.04),
              CustomButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          backgroundColor: AppColors.kWiteColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Center(
                            child: Column(
                              children: [
                                SizedBox(height: context.screenHeight * 0.02),
                                SvgPicture.asset(Assets.imagesCongrates),
                                SizedBox(height: context.screenHeight * 0.02),
                                Text(
                                  'تم تغيير كلمة المرور بنجاح',
                                  style: TextStyles.semiBold16.copyWith(
                                    color: AppColors.kprimaryColor,
                                  ),
                                ),
                                SizedBox(height: context.screenHeight * 0.04),
                                CustomButton(
                                  onPressed: () {
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      SigninScreen.id,
                                      (route) => false,
                                    );
                                  },
                                  text: 'العودة لتسجيل الدخول',
                                ),
                                SizedBox(height: context.screenHeight * 0.02),
                              ],
                            ),
                          ),
                        ),
                  );
                },
                text: 'إنشاء كلمة مرور جديدة',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
