import 'package:flutter/material.dart';

void showSnackBarMethode(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
