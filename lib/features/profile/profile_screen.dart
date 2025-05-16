// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/constants.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/features/profile/widgets/profile_screen_body.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  static const id = 'ProfileScreen';
  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          right: khorizintalPadding,
          left: khorizintalPadding,
          top: 12,
        ),
        child: Column(
          spacing: 8,
          children: [
            Text('حسابي', style: TextStyles.bold19),
            Expanded(child: ProfileScreenBody()),
          ],
        ),
      ),
    );
  }
}
