import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hadaer_blady/core/utils/app_directions.dart';
import 'package:hadaer_blady/core/widgets/custom_button.dart';
import 'package:hadaer_blady/core/widgets/custom_text_form_feild.dart';
import 'package:hadaer_blady/core/widgets/custome_password_feild.dart';
import 'package:hadaer_blady/core/widgets/have_an_account.dart';
import 'package:hadaer_blady/core/widgets/sellected_jop_titel.dart';
import 'package:hadaer_blady/features/auth/presentation/cubits/signup_cubit/signup_cubit.dart';

class SignupScreenBody extends StatefulWidget {
  const SignupScreenBody({super.key});

  @override
  State<SignupScreenBody> createState() => _SignupScreenBodyState();
}

class _SignupScreenBodyState extends State<SignupScreenBody> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  AutovalidateMode autovalidateMode = AutovalidateMode.disabled;
  late String jopTitle;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Form(
          key: formKey,
          autovalidateMode: autovalidateMode,
          child: Column(
            spacing: 16,
            children: [
              SizedBox(height: context.screenHeight * 0.01),
              CustomTextFormFeild(
                hintText: 'الأسم كامل',
                keyBoardType: TextInputType.name,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى ادخال الاسم كامل';
                  }
                  return null;
                },
                controller: _nameController,
              ),

              CustomTextFormFeild(
                hintText: 'رقم الهاتف',
                keyBoardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى ادخال رقم الهاتف';
                  }
                  // You can add phone number format validation here
                  if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                    return 'يرجى ادخال رقم هاتف صحيح';
                  }
                  return null;
                },
                controller: _phoneController,
              ),

              CustomTextFormFeild(
                hintText: 'البريد الإلكتروني',
                keyBoardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى ادخال البريد الإلكتروني';
                  }
                  return null;
                },
                controller: _emailController,
              ),
              SelectJopTitel(
                validator: (value) {
                  if (value == 'الوظيفة' || value == null) {
                    return 'يرجى اختيار الوظيفة';
                  }
                  return null;
                },
                onSaved: (value) {
                  jopTitle = value!;
                },
              ),

              CustomPasswordFeild(
                controller: _passwordController,

                name: 'كلمة المرور',
              ),
              SizedBox(height: context.screenHeight * 0.015),
              CustomButton(
                onPressed: () {
                  signUpMethod();
                },
                text: 'إنشاء حساب جديد',
              ),

              const HaveAnAccount(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> signUpMethod() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      context.read<SignupCubit>().createUser(
        email: _emailController.text,
        password: _passwordController.text,
        name: _nameController.text,
        phone: _phoneController.text,
        jopTitle: jopTitle,
      );
    } else {
      setState(() {
        autovalidateMode = AutovalidateMode.always;
      });
    }
  }
}
