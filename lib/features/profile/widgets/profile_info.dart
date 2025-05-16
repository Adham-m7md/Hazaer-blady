import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/services/shared_prefs_singleton.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';

class UserInfoColumn extends StatefulWidget {
  const UserInfoColumn({super.key});

  @override
  _UserInfoColumnState createState() => _UserInfoColumnState();
}

class _UserInfoColumnState extends State<UserInfoColumn> {
  String userName = 'Loading...';
  String userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    setState(() {
      userName = Prefs.getUserName();
      userEmail = Prefs.getUserEmail();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(userName, style: TextStyles.bold19),
        Text(
          userEmail,
          style: TextStyles.semiBold13.copyWith(color: AppColors.kGrayColor),
        ),
      ],
    );
  }
}
