import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/services/shared_prefs_singleton.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/widgets/custom_loading_indicator.dart';

class ProfileImageWidget extends StatelessWidget {
  const ProfileImageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: Prefs.profileImageNotifier,
      builder: (context, profileImageUrl, child) {
        return ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(100)),
          child: Container(
            decoration: const BoxDecoration(color: AppColors.kFillGrayColor),
            height: 60,
            width: 60,
            child:
                profileImageUrl.isNotEmpty
                    ? _buildImageWidget(profileImageUrl)
                    : const Center(
                      child: Icon(
                        Icons.person,
                        color: AppColors.kGrayColor,
                        size: 40,
                      ),
                    ),
          ),
        );
      },
    );
  }

  Widget _buildImageWidget(String imageUrl) {
    // Check if the imageUrl is a local file path
    if (File(imageUrl).existsSync()) {
      return Image.file(
        File(imageUrl),
        height: 60,
        width: 60,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) => const Center(
              child: Icon(Icons.person, color: AppColors.kGrayColor, size: 40),
            ),
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }
          return const CustomLoadingIndicator(); // Show custom loader while loading
        },
      );
    } else {
      return Image.network(
        imageUrl,
        height: 60,
        width: 60,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) => const Center(
              child: Icon(Icons.person, color: AppColors.kGrayColor, size: 40),
            ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return const CustomLoadingIndicator(); // Show custom loader while loading
        },
      );
    }
  }
}
