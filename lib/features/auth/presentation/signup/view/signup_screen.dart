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
import 'package:url_launcher/url_launcher.dart'; // إضافة هذا الاستيراد

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});
  static const String id = 'SignupScreen';

  // دالة لفتح تطبيق الإيميل مع حلول متعددة
  Future<void> _openEmailApp(BuildContext context) async {
    try {
      bool appOpened = false;

      // محاولة فتح Gmail بالطريقة الصحيحة
      try {
        final Uri gmailUri = Uri.parse('android-app://com.google.android.gm');
        if (await canLaunchUrl(gmailUri)) {
          await launchUrl(gmailUri, mode: LaunchMode.externalApplication);
          appOpened = true;
        }
      } catch (e) {
        print('Gmail app scheme failed: $e');
      }

      // إذا لم ينجح Gmail، محاولة Outlook
      if (!appOpened) {
        try {
          final Uri outlookUri = Uri.parse('ms-outlook://');
          if (await canLaunchUrl(outlookUri)) {
            await launchUrl(outlookUri, mode: LaunchMode.externalApplication);
            appOpened = true;
          }
        } catch (e) {
          print('Outlook app scheme failed: $e');
        }
      }

      // محاولة فتح تطبيق الإيميل الافتراضي
      if (!appOpened) {
        try {
          final Uri mailtoUri = Uri(scheme: 'mailto', path: '');
          if (await canLaunchUrl(mailtoUri)) {
            await launchUrl(mailtoUri, mode: LaunchMode.externalApplication);
            appOpened = true;
          }
        } catch (e) {
          print('Mailto scheme failed: $e');
        }
      }

      // إذا لم ينجح أي تطبيق، إظهار الخيارات البديلة
      if (!appOpened) {
        await _showEmailAppOptions(context);
      }
    } catch (e) {
      print('Error opening email app: $e');
      await _showEmailAppOptions(context);
    }
  }

  // دالة لإظهار خيارات بديلة
  Future<void> _showEmailAppOptions(BuildContext context) async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('لا يوجد تطبيق بريد إلكتروني'),
            content: const Text(
              'يمكنك تحميل تطبيق بريد إلكتروني أو التحقق من بريدك عبر المتصفح',
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  // فتح متجر جوجل بلاي للبحث عن Gmail
                  const playStoreUrl =
                      'https://play.google.com/store/apps/details?id=com.google.android.gm';
                  final Uri uri = Uri.parse(playStoreUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: const Text('تحميل Gmail'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  // فتح Gmail عبر المتصفح
                  const webGmailUrl = 'https://mail.google.com';
                  final Uri uri = Uri.parse(webGmailUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: const Text('فتح عبر المتصفح'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // العودة لصفحة تسجيل الدخول
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    SigninScreen.id,
                    (route) => false,
                  );
                },
                child: const Text('متابعة لتسجيل الدخول'),
              ),
            ],
          ),
    );
  }

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
                              'تم إنشاء حسابك بنجاح ! \n قم بتأكيد بريدك الإلكتروني',
                          buttonText: 'فتح تطبيق الإيميل',
                          onPressed: () async {
                            Navigator.pop(context); // إغلاق الحوار أولاً
                            await _openEmailApp(context); // فتح تطبيق البريد
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
