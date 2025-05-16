import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withAlpha(50),
            width: double.infinity,
            height: double.infinity,
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.lightPrimaryColor,
              ),
            ),
          ),
      ],
    );
  }
}
