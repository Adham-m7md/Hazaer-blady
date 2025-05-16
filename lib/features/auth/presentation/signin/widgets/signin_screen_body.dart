import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_directions.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/core/widgets/custom_button.dart';
import 'package:hadaer_blady/core/widgets/custom_text_form_feild.dart';
import 'package:hadaer_blady/core/widgets/custome_password_feild.dart';
import 'package:hadaer_blady/core/widgets/dont_Have_An_Account.dart';
import 'package:hadaer_blady/features/auth/presentation/cubits/signin_cubit/signin_cubit.dart';
import 'package:hadaer_blady/features/auth/presentation/forget_pass/view/forget_pass.dart';

class SigninScreenBody extends StatefulWidget {
  const SigninScreenBody({super.key});

  @override
  State<SigninScreenBody> createState() => _SigninScreenBodyState();
}

class _SigninScreenBodyState extends State<SigninScreenBody> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  AutovalidateMode autovalidateMode = AutovalidateMode.disabled;

  final _emailOrPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Form(
          key: formKey,
          autovalidateMode: autovalidateMode,
          child: Column(
            children: [
              SizedBox(height: context.screenHeight * 0.03),

              CustomTextFormFeild(
                maxLines: 1,
                hintText: 'البريد الألكتروني او رقم الهاتف',
                keyBoardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى ادخال البريد الإلكتروني';
                  }
                  return null;
                },
                controller: _emailOrPhoneController,
              ),
              SizedBox(height: context.screenHeight * 0.02),
              CustomPasswordFeild(
                controller: _passwordController,
                name: 'كلمة المرور',
              ),
              SizedBox(height: context.screenHeight * 0.03),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, ForgetPass.id);
                },
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Text(
                    'نسيت كلمة المرور؟',
                    style: TextStyles.semiBold13.copyWith(
                      color: AppColors.lightPrimaryColor,
                    ),
                  ),
                ),
              ),
              SizedBox(height: context.screenHeight * 0.03),
              CustomButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();

                    context.read<SigninCubit>().signIn(
                      _emailOrPhoneController.text,
                      _passwordController.text,
                    );
                  } else {
                    setState(() {
                      autovalidateMode = AutovalidateMode.always;
                    });
                  }
                },
                text: 'تسجيل دخول',
              ),
              SizedBox(height: context.screenHeight * 0.03),
              const DontHaveAnAccount(),
            ],
          ),
        ),
      ),
    );
  }
}
