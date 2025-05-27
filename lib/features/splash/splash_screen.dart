import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hadaer_blady/core/constants.dart';
import 'package:hadaer_blady/core/services/firebase_auth_service.dart';
import 'package:hadaer_blady/core/services/shared_prefs_singleton.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_directions.dart';
import 'package:hadaer_blady/core/utils/svg_images.dart';
import 'package:hadaer_blady/features/auth/presentation/signin/view/signin_screen.dart';
import 'package:hadaer_blady/features/home/presentation/home_screen.dart';
import 'package:hadaer_blady/features/onboarding/view/onboarding_view.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  static const String id = '/';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    excuteNavigation();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightPrimaryColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: SvgPicture.asset(
              Assets.imagesLogoUpFireSplash,
              height: context.screenHeight * 0.125,
            ),
          ),
          SvgPicture.asset(
            Assets.imagesLogo,
            height: context.screenHeight * 0.25,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: SvgPicture.asset(
              Assets.imagesLogoDownFireSplash,
              height: context.screenHeight * 0.125,
            ),
          ),
        ],
      ),
    );
  }

  void excuteNavigation() async {
    FirebaseAuthService firebaseAuthService = FirebaseAuthService();

    // Check if the user is logged in
    bool isUserLoggedIn = firebaseAuthService.isUserLoggedIn();

    // Check email verification status if the user is logged in
    bool isEmailVerified = false;
    if (isUserLoggedIn) {
      isEmailVerified = await firebaseAuthService.isEmailVerified();
    }

    // Check if onboarding has been seen
    bool isOnBoardingViewSeen = Prefs.getBool(kIsOnBoardigViewSeen);

    Future.delayed(const Duration(seconds: 5), () {
      // If user is logged in and email is verified, go directly to HomeScreen
      if (isUserLoggedIn && isEmailVerified) {
        Navigator.pushReplacementNamed(context, HomeScreen.id);
      }
      // If user is logged in but email is not verified, go to SigninScreen
      else if (isUserLoggedIn && !isEmailVerified) {
        Navigator.pushReplacementNamed(context, SigninScreen.id);
      }
      // If user is not logged in and has seen onboarding, go to SigninScreen
      else if (isOnBoardingViewSeen) {
        Navigator.pushReplacementNamed(context, SigninScreen.id);
      }
      // If user has not seen onboarding, go to OnboardingView
      else {
        Navigator.pushReplacementNamed(context, OnboardingView.id);
      }
    });
  }
}
