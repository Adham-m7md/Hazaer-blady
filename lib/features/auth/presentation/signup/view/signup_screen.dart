import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hadaer_blady/core/functions/build_app_bar_with_arrow_back_button.dart';
import 'package:hadaer_blady/core/services/get_it.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/svg_images.dart';
import 'package:hadaer_blady/core/widgets/custome_show_dialog.dart';
import 'package:hadaer_blady/core/widgets/loading_indicator.dart';
import 'package:hadaer_blady/features/auth/domain/repos/auth_repo.dart';
import 'package:hadaer_blady/features/auth/presentation/cubits/signup_cubit/signup_cubit.dart';
import 'package:hadaer_blady/features/auth/presentation/signin/view/signin_screen.dart';
import 'package:hadaer_blady/features/auth/presentation/signup/widgets/signup_screen_body.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});
  static const String id = 'SignupScreen';
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SignupCubit(getIt<AuthRepo>()),
      child: Scaffold(
        backgroundColor: AppColors.kWiteColor,
        appBar: buildAppBarWithArrowBackButton(
          title: 'حساب جديد',
          context: context,
        ),
        body: Builder(
          builder: (context) {
            return BlocConsumer<SignupCubit, SignupState>(
              listener: (context, state) {
                if (state is SignupSuccess) {
                  // عرض تنبيه لتأكيد البريد الإلكتروني
                  showDialog(
                    context: context,
                    builder:
                        (context) => CustomeShowDialog(
                          text:
                              'تم إنشاء حسابك بنجاح ! \n قم بتأكيد بريدك الإلكتروني ثم عاود لتسجيل الدخول',
                          buttonText: 'تسجيل الدخول',
                          onPressed: () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              SigninScreen.id,
                              (route) => false,
                            );
                          },
                        ),
                  );
                }
                if (state is SignupFailure) {
                  showDialog(
                    context: context,
                    builder:
                        (dialogContext) => CustomeShowDialog(
                          text: state.message,
                          buttonText: 'حاول مرة أخرى',
                          onPressed: () => Navigator.pop(dialogContext),
                          imagePath: Assets.imagesEror, // صورة الخطأ
                        ),
                  );
                }
              },

              builder: (context, state) {
                return LoadingOverlay(
                  isLoading: state is SignupLoading,
                  child: const SignupScreenBody(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
