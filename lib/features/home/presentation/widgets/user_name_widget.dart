import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/services/shared_prefs_singleton.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';

class UserNameWidget extends StatefulWidget {
  const UserNameWidget({super.key});

  @override
  _UserNameWidgetState createState() => _UserNameWidgetState();
}

class _UserNameWidgetState extends State<UserNameWidget> {
  String userName = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  void _loadUserName() {
    setState(() {
      userName = Prefs.getUserName();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(userName, style: TextStyles.bold19);
  }
}
