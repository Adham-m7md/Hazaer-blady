import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hadaer_blady/core/functions/build_app_bar.dart';
import 'package:hadaer_blady/core/functions/show_snack_bar.dart';
import 'package:hadaer_blady/core/services/get_it.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/widgets/loading_indicator.dart';
import 'package:hadaer_blady/features/auth/domain/repos/auth_repo.dart';
import 'package:hadaer_blady/features/auth/presentation/cubits/signin_cubit/signin_cubit.dart';
import 'package:hadaer_blady/features/auth/presentation/signin/widgets/signin_screen_body.dart';
import 'package:hadaer_blady/features/home/presentation/home_screen.dart';

class SigninScreen extends StatelessWidget {
  const SigninScreen({super.key});

  // Use a static const for route names to avoid typos
  static const String id = 'SigninScreen';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Using a factory constructor for better state management
      create: (_) => SigninCubit(getIt<AuthRepo>()),
      child: const _SigninScreenContent(),
    );
  }
}

// Extract content to a private widget for better separation of concerns
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
            showSnackBarMethode(context, state.message);
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
