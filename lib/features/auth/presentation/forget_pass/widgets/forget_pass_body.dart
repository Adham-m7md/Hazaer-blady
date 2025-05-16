import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hadaer_blady/core/constants.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_directions.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/core/widgets/custom_button.dart';
import 'package:hadaer_blady/core/widgets/custom_text_form_feild.dart';
import 'package:hadaer_blady/features/auth/presentation/cubits/forget_pass/reset_pass_cubit/reset_pass_cubit.dart';

class ForgetPassBody extends StatefulWidget {
  const ForgetPassBody({super.key});

  @override
  State<ForgetPassBody> createState() => _ForgetPassBodyState();
}

class _ForgetPassBodyState extends State<ForgetPassBody> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  AutovalidateMode autoValidateMode = AutovalidateMode.disabled;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: khorizintalPadding),
        child: Form(
          key: formKey,
          autovalidateMode: autoValidateMode,
          child: Column(
            children: [
              SizedBox(height: context.screenHeight * 0.02),
              Text(
                'لا تقلق, قم بكتابة البريد الإلكترونى لإعادة تعيين كلمة المرور',
                style: TextStyles.semiBold16.copyWith(
                  color: AppColors.kGrayColor,
                ),
              ),
              SizedBox(height: context.screenHeight * 0.04),
              CustomTextFormFeild(
                hintText: 'البريد الإلكترونى',
                keyBoardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى ادخال البريد الإلكتروني';
                  }
                  final emailRegex = RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  );
                  if (!emailRegex.hasMatch(value)) {
                    return 'يرجى إدخال بريد إلكتروني صحيح';
                  }
                  return null;
                },
                controller: _emailController,
              ),
              SizedBox(height: context.screenHeight * 0.04),
              CustomButton(
                onPressed: forgetPassMethod,
                text: 'إعادة تعيين كلمة المرور',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> forgetPassMethod() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      final email = _emailController.text;
      log('Calling resetPassword in Cubit with email: $email');
      context.read<ResetPassCubit>().resetPassword(email: email);
    } else {
      log('Form validation failed');
      setState(() {
        autoValidateMode = AutovalidateMode.always;
      });
    }
  }
}
