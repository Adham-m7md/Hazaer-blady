import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/constants.dart';
import 'package:hadaer_blady/core/services/shared_prefs_singleton.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_directions.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/core/widgets/custom_button.dart';
import 'package:hadaer_blady/features/auth/presentation/signin/view/signin_screen.dart';

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});
  static const String id = 'OnboardingView';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kWiteColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Image.asset('assets/images/two.jpg'),
              SizedBox(height: context.screenHeight * 0.03),
              const Text('حظائر بلادي', style: TextStyles.bold28),
              const SizedBox(height: 10),
              const Text(
                'منصتك الذكية لتجارة الدجاج اللاحم',
                style: TextStyles.bold23,
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 24),
                child: Text(
                  'نحن تطبيق مبتكر يربط بين أصحاب الحظائر والتجار، مما يسهل عملية بيع وشراء الدجاج اللاحم ومستلزمات الحظائر بكل سهولة وشفافية. عبر التطبيق، يمكنك استكشاف العروض المتاحة، التفاوض على الأسعار، وإتمام الصفقات بأمان وسرعة. سواء كنت مربيًا أو تاجرًا، ستجد في "حظائر بلادي" أداة فعالة لتنمية أعمالك وتوسيع شبكتك التجارية.',
                  textAlign: TextAlign.center,
                  style: TextStyles.semiBold16,
                ),
              ),
              SizedBox(height: context.screenHeight * 0.14),
              DotsIndicator(
                dotsCount: 1,
                position: 0,
                decorator: const DotsDecorator(activeColor: AppColors.kprimaryColor),
              ),
              SizedBox(height: context.screenHeight * 0.02),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CustomButton(
                  onPressed: () {
                    Prefs.setBool(kIsOnBoardigViewSeen, true);
                    Navigator.pushReplacementNamed(context, SigninScreen.id);
                  },
                  text: "ابدأ الان",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
  // Stack(
              //   children: [
              //     SizedBox(
              //       width: double.infinity,
              //       child: SvgPicture.asset(
              //         Assets.imagesBackgroundOnboarding,
              //         fit: BoxFit.fill,
              //       ),
              //     ),

              //     Positioned(
              //       top: 10,
              //       right: 10,
              //       child: Container(height: 185,width: 185,decoration: BoxDecoration(
              //         border: BorderSide(color: )
              //       ),
              //         child: ClipOval(
              //           child: Image.asset(
              //             'assets/images/one.jpg',
              //             height: 180,
              //             width: 180,
              //             fit: BoxFit.cover,
              //           ),
              //         ),
              //       ),

              //     ),
              //     Positioned(
              //       top: 70,
              //       left: 10,
              //       child: ClipOval(
              //         child: Image.asset(
              //           'assets/images/three.jpg',
              //           height: 180,
              //           width: 180,
              //           fit: BoxFit.cover,
              //         ),
              //       ),
              //       //  SvgPicture.asset(Assets.imagesLogo, height: 150),
              //     ),
              //     Positioned(
              //       bottom: 0,
              //       right: 115,
              //       child: SvgPicture.asset(Assets.imagesLogo, height: 150),
              //     ),
              //   ],
              // ),