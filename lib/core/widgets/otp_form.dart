import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';

class OtpForm extends StatelessWidget {
  const OtpForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      width: 70,

      decoration: BoxDecoration(
        color: AppColors.kFillGrayColor,
        border: Border.all(width: 1, color: AppColors.klightGrayColor),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      ),
      child: TextField(
        style: Theme.of(context).textTheme.headlineLarge,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: const InputDecoration(
          border: InputBorder.none,

          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}
