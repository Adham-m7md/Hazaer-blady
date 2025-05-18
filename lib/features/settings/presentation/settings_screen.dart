import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/errors/exeptions.dart';
import 'package:hadaer_blady/core/functions/build_app_bar_with_arrow_back_button.dart';
import 'package:hadaer_blady/core/functions/show_snack_bar.dart';
import 'package:hadaer_blady/core/services/delete_user_service.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/core/widgets/custom_loading_indicator.dart';
import 'package:hadaer_blady/core/widgets/custome_password_feild.dart';
import 'package:hadaer_blady/core/widgets/row_profile_content.dart';
import 'package:hadaer_blady/features/auth/presentation/signin/view/signin_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  static const String id = 'SettingsScreen';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kWiteColor,
      appBar: buildAppBarWithArrowBackButton(
        title: 'الإعدادات',
        context: context,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            spacing: 12,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomeRowProfileContent(
                icon: Icons.notifications_outlined,
                titelText: 'الأشعارات',
                secondIcon: Icons.notifications_active_outlined,
                actionButton: () {},
              ),
              GestureDetector(
                onTap: () => _showDeleteAccountDialog(context),
                child: Container(
                  height: 30,
                  width: double.infinity,
                  decoration: const BoxDecoration(color: Color(0xffEBF9F1)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.delete_forever_outlined,
                        color: AppColors.kRedColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'حذف الحساب نهائيا',
                        style: TextStyles.semiBold16.copyWith(
                          color: AppColors.kRedColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final TextEditingController passwordController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    bool isLoading = false;

    // استخدام الخدمة الجديدة التي أنشأناها
    final userDeletionService = UserDeletionService();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.kWiteColor,
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('حذف الحساب', style: TextStyles.bold16),
                        SizedBox(width: 12),
                        Icon(Icons.warning, color: AppColors.kRedColor),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'هذا الإجراء لا يمكن التراجع عنه. سيتم حذف حسابك وجميع بياناتك ومنتجاتك.',
                      style: TextStyles.semiBold13,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    CustomPasswordFeild(
                      name: 'أضف كلمة المرور الحالية',
                      controller: passwordController,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: Text(
                    'إلغاء',
                    style: TextStyles.semiBold13.copyWith(
                      color: AppColors.lightPrimaryColor,
                    ),
                  ),
                ),
                isLoading
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CustomLoadingIndicator(),
                    )
                    : TextButton(
                      onPressed: () async {
                        if (formKey.currentState?.validate() ?? false) {
                          setState(() {
                            isLoading = true;
                          });

                          try {
                            // استخدام الخدمة الجديدة لحذف المستخدم وجميع بياناته
                            await userDeletionService.deleteUserWithAllData(
                              password: passwordController.text,
                            );

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'تم حذف الحساب وجميع بياناتك بنجاح',
                                  ),
                                ),
                              );
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const SigninScreen(),
                                ),
                                (route) => false,
                              );
                            }
                          } on CustomException catch (e) {
                            setState(() {
                              isLoading = false;
                            });
                            if (context.mounted) {
                              showSnackBarMethode(context, e.message);
                            }
                          } catch (e) {
                            setState(() {
                              isLoading = false;
                            });
                            if (context.mounted) {
                              showSnackBarMethode(
                                context,
                                'حدث خطأ ما، الرجاء المحاولة مرة أخرى',
                              );
                            }
                          }
                        }
                      },
                      child: Text(
                        'حذف الحساب',
                        style: TextStyles.semiBold13.copyWith(
                          color: AppColors.kRedColor,
                        ),
                      ),
                    ),
              ],
            );
          },
        );
      },
    );
  }
}
