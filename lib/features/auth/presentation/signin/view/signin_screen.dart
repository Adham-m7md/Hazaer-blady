import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hadaer_blady/core/functions/build_app_bar.dart';
import 'package:hadaer_blady/core/services/firebase_auth_service.dart';
import 'package:hadaer_blady/core/services/get_it.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/svg_images.dart';
import 'package:hadaer_blady/core/widgets/custome_show_dialog.dart';
import 'package:hadaer_blady/core/widgets/loading_indicator.dart';
import 'package:hadaer_blady/features/auth/domain/repos/auth_repo.dart';
import 'package:hadaer_blady/features/auth/presentation/cubits/signin_cubit/signin_cubit.dart';
import 'package:hadaer_blady/features/auth/presentation/signin/widgets/signin_screen_body.dart';
import 'package:hadaer_blady/features/home/presentation/home_screen.dart';

class SigninScreen extends StatelessWidget {
  const SigninScreen({super.key});

  static const String id = 'SigninScreen';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SigninCubit(getIt<AuthRepo>()),
      child: const _SigninScreenContent(),
    );
  }
}

class _SigninScreenContent extends StatelessWidget {
  const _SigninScreenContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kWiteColor,
      appBar: buildAppBar(title: 'تسجيل الدخول'),
      body: BlocConsumer<SigninCubit, SigninState>(
        listenWhen:
            (previous, current) =>
                current is SigninSuccess || current is SigninFailure,
        listener: (context, state) {
          if (state is SigninSuccess) {
            _navigateToHomeScreen(context);
          } else if (state is SigninFailure) {
            if (state.message == 'يرجى تأكيد بريدك الإلكتروني أولاً') {
              showDialog(
                context: context,
                builder:
                    (dialogContext) => CustomeShowDialog(
                      text:
                          'يرجى تأكيد بريدك الإلكتروني. هل تريد إعادة إرسال رابط التأكيد؟',
                      buttonText: 'إعادة إرسال',
                      imagePath: Assets.imagesEror,
                      onPressed: () async {
                        try {
                          await getIt<FirebaseAuthService>()
                              .resendEmailVerification();
                          Navigator.pop(dialogContext);
                          showDialog(
                            context: context,
                            builder:
                                (dialogContext) => CustomeShowDialog(
                                  text:
                                      'تم إعادة إرسال رابط التأكيد إلى بريدك الإلكتروني.',
                                  buttonText: 'موافق',
                                  imagePath: Assets.imagesCongrates,
                                  onPressed: () => Navigator.pop(dialogContext),
                                ),
                          );
                        } catch (e) {
                          Navigator.pop(dialogContext);
                          showDialog(
                            context: context,
                            builder:
                                (dialogContext) => CustomeShowDialog(
                                  text: e.toString(),
                                  buttonText: 'موافق',
                                  imagePath: Assets.imagesEror,
                                  onPressed: () => Navigator.pop(dialogContext),
                                ),
                          );
                        }
                      },
                    ),
              );
            } else {
              showDialog(
                context: context,
                builder:
                    (dialogContext) => CustomeShowDialog(
                      text: state.message,
                      buttonText: 'موافق',
                      imagePath: Assets.imagesEror,
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
              );
            }
          }
        },
        buildWhen:
            (previous, current) =>
                previous is SigninLoading != current is SigninLoading,
        builder: (context, state) {
          return LoadingOverlay(
            isLoading: state is SigninLoading,
            child: const SigninScreenBody(),
          );
        },
      ),
    );
  }

  void _navigateToHomeScreen(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, HomeScreen.id, (route) => false);
  }
}
