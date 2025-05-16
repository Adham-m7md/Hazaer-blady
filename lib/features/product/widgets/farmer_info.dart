import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/core/widgets/custom_loading_indicator.dart';
import 'package:hadaer_blady/features/coops/presentation/coop_details.dart';

class FarmerInfo extends StatelessWidget {
  final Map<String, dynamic>? farmerData;
  final String farmerId;

  const FarmerInfo({
    super.key,
    required this.farmerData,
    required this.farmerId,
  });

  @override
  Widget build(BuildContext context) {
    final farmerName = farmerData?['name'] ?? 'حظيرة غير معروفة';

    return InkWell(
      onTap: () {
        if (farmerId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CoopDetails(farmerId: farmerId),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('معرف الحضيرة غير متوفر')),
          );
        }
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.kprimaryColor,
            child: _buildProfileImage(),
          ),
          const SizedBox(width: 8),
          Text(farmerName, style: TextStyles.bold16),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    // Check if profile image URL exists and is valid
    final imageUrl = farmerData?['profile_image_url'];
    if (imageUrl != null &&
        imageUrl is String &&
        imageUrl.trim().isNotEmpty &&
        _isValidUrl(imageUrl)) {
      return ClipOval(
        child: Image.network(
          imageUrl,
          width: 38,
          height: 38,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Log the error for debugging
            debugPrint('Error loading image: $error');
            return const Icon(Icons.person, color: AppColors.kWiteColor);
          },
          loadingBuilder:
              (context, child, loadingProgress) =>
                  loadingProgress == null
                      ? child
                      : const CustomLoadingIndicator(),
        ),
      );
    } else {
      return const Icon(Icons.person, color: AppColors.kWiteColor);
    }
  }

  // Helper method to validate URL
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
}
