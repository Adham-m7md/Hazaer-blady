import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/widgets/custom_text_form_feild.dart';

class CustomPasswordFeild extends StatefulWidget {
  const CustomPasswordFeild({
    super.key,
    this.onSaved,
    required this.name,
    this.controller,
  });
  final void Function(String?)? onSaved;
  final String name;
  final TextEditingController? controller;
  @override
  State<CustomPasswordFeild> createState() => _CustomPasswordFeildState();
}

class _CustomPasswordFeildState extends State<CustomPasswordFeild> {
  bool obscure = true;

  @override
  Widget build(BuildContext context) {
    return CustomTextFormFeild(
      maxLines: 1,
      obscureText: obscure,
      hintText: widget.name,
      controller: widget.controller,
      keyBoardType: TextInputType.visiblePassword,
      suffixIcon: IconButton(
        onPressed: () {
          obscure = !obscure;
          setState(() {});
        },
        icon:
            obscure
                ? const Icon(Icons.remove_red_eye, color: AppColors.kGrayColor)
                : const Icon(Icons.visibility_off, color: AppColors.kGrayColor),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'يرجى ادخال كلمة المرور';
        }
        if (value.length < 6) {
          return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
        }
        return null;
      },
      onSaved: widget.onSaved,
    );
  }
}
