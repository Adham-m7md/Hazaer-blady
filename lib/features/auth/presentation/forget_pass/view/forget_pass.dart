import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hadaer_blady/core/functions/build_app_bar_with_arrow_back_button.dart';
import 'package:hadaer_blady/core/functions/show_snack_bar.dart';
import 'package:hadaer_blady/core/services/firebase_auth_service.dart';
import 'package:hadaer_blady/core/services/get_it.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/widgets/custome_show_dialog.dart';
import 'package:hadaer_blady/core/widgets/loading_indicator.dart';
import 'package:hadaer_blady/features/auth/presentation/cubits/forget_pass/reset_pass_cubit/reset_pass_cubit.dart';
import 'package:hadaer_blady/features/auth/presentation/forget_pass/widgets/forget_pass_body.dart';
import 'package:hadaer_blady/features/auth/presentation/signin/view/signin_screen.dart';

class ForgetPass extends StatelessWidget {
  const ForgetPass({super.key});
  static const String id = 'ForgetPass';
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ResetPassCubit(getIt<FirebaseAuthService>()),
      child: Scaffold(
        backgroundColor: AppColors.kWiteColor,
        appBar: buildAppBarWithArrowBackButton(
          title: 'نسيان كلمة المرور',
          context: context,
        ),
        body: BlocConsumer<ResetPassCubit, ResetPassState>(
          listener: (context, state) {
            if (state is ResetPassSuccess) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder:
                    (context) => CustomeShowDialog(
                      text:
                          'تم إرسال رابط إلى بريدك الإلكترونى لإعادة تعيين كلمة المرور',
                      buttonText: 'حسنا',
                      onPressed:
                          () => Navigator.pushNamedAndRemoveUntil(
                            context,
                            SigninScreen.id,
                            (route) => false,
                          ),
                    ),
              );
            } else if (state is ResetPassFailure) {
              showSnackBarMethode(context, state.message);
            }
          },
          builder: (context, state) {
            return LoadingOverlay(
              isLoading: state is ResetPassLoading,
              child: const ForgetPassBody(),
            );
          },
        ),
      ),
    );
  }
}
