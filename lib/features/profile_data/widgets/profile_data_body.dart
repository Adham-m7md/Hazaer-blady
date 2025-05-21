import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/services/shared_prefs_singleton.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_directions.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/core/widgets/custom_button.dart';
import 'package:hadaer_blady/core/widgets/custom_text_form_feild.dart';
import 'package:hadaer_blady/core/widgets/custom_tittel.dart';

class ProfileDataBody extends StatelessWidget {
  final Map<String, dynamic> userData;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController cityController;
  final TextEditingController addressController;
  final VoidCallback onSave;
  final File? selectedImage;
  final VoidCallback onImagePick;
  final VoidCallback onUpdateLocation;

  const ProfileDataBody({
    super.key,
    required this.userData,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.cityController,
    required this.addressController,
    required this.onSave,
    this.selectedImage,
    required this.onImagePick,
    required this.onUpdateLocation,
  });

  @override
  Widget build(BuildContext context) {
    // Always prioritize SharedPreferences data first
    final userName =
        Prefs.getUserName().isNotEmpty && Prefs.getUserName() != 'User'
            ? Prefs.getUserName()
            : userData['name'] as String? ?? 'أدخل اسمك';

    final userEmail =
        Prefs.getUserEmail().isNotEmpty
            ? Prefs.getUserEmail()
            : userData['email'] as String? ?? 'البريد الإلكتروني';

    final userPhone =
        Prefs.getUserPhone().isNotEmpty
            ? Prefs.getUserPhone()
            : userData['phone'] as String? ?? '';

    final userCity =
        Prefs.getUserCity().isNotEmpty
            ? Prefs.getUserCity()
            : userData['city'] as String? ?? '';

    final userAddress =
        Prefs.getUserAddress().isNotEmpty
            ? Prefs.getUserAddress()
            : userData['address'] as String? ?? '';

    // Set controller values only once when building
    nameController.text = userName;
    emailController.text = userEmail;
    phoneController.text = userPhone;
    cityController.text = userCity;
    addressController.text = userAddress;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        spacing: 4,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomTittel(text: 'صورة الملف الشخصي:'),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ValueListenableBuilder<String>(
                valueListenable: Prefs.profileImageNotifier,
                builder: (context, profileImageUrl, child) {
                  return _buildProfileImageContainer(
                    context,
                    profileImageUrl.isNotEmpty
                        ? profileImageUrl
                        : userData['profile_image_url'] as String? ?? '',
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          const CustomTittel(text: 'اسم الحساب:'),
          CustomTextFormFeild(
            controller: nameController,
            hintText: 'أدخل اسمك',
            enabled: false,
            keyBoardType: TextInputType.name,
            suffixIcon: _buildLockIcon(),
          ),
          const CustomTittel(text: 'البريد الإلكتروني:'),
          CustomTextFormFeild(
            controller: emailController,
            hintText: 'البريد الإلكتروني',
            enabled: false,
            keyBoardType: TextInputType.emailAddress,
            suffixIcon: _buildLockIcon(),
          ),
          const CustomTittel(text: 'رقم الهاتف:'),
          CustomTextFormFeild(
            controller: phoneController,
            hintText: 'أدخل رقم الهاتف',
            enabled: false,
            keyBoardType: TextInputType.phone,
            suffixIcon: _buildLockIcon(),
          ),
          const CustomTittel(text: 'المدينة:'),
          CustomTextFormFeild(
            controller: cityController,
            hintText: 'أدخل المدينة',
            keyBoardType: TextInputType.text,
            suffixIcon: _buildEditIcon(),
            onSaved: (value) {
              // If text is empty, controller will remain empty and hint text will show
              if (value!.isEmpty) {
                Prefs.setUserCity('');
              }
            },
          ),
          const CustomTittel(text: 'العنوان:'),
          CustomTextFormFeild(
            controller: addressController,
            hintText: 'أدخل العنوان',
            keyBoardType: TextInputType.text,
            suffixIcon: _buildEditIcon(),
            onSaved: (value) {
              // If text is empty, controller will remain empty and hint text will show
              if (value!.isEmpty) {
                Prefs.setUserAddress('');
              }
            },
          ),
          const CustomTittel(text: 'الموقع:'),
          InkWell(
            onTap: onUpdateLocation,
            child: Container(
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.kFillGrayColor,
                border: Border.all(width: 1, color: AppColors.klightGrayColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Text(
                      'قم بتحديد الموقع',
                      style: TextStyles.bold13.copyWith(
                        color: AppColors.kGrayColor,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.location_on_outlined,
                      color: AppColors.kGrayColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Display current location if available
          if (Prefs.getUserLatitude() != null &&
              Prefs.getUserLongitude() != null &&
              Prefs.getUserLatitude() != 0 &&
              Prefs.getUserLongitude() != 0)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Text(
                'الموقع الحالي: ${Prefs.getUserLatitude()?.toStringAsFixed(4)}, ${Prefs.getUserLongitude()?.toStringAsFixed(4)}',
                style: TextStyles.regular13.copyWith(
                  color: AppColors.kGrayColor,
                ),
              ),
            ),
          const SizedBox(height: 8),
          CustomButton(onPressed: onSave, text: 'حفظ التغييرات'),
        ],
      ),
    );
  }

  Widget _buildProfileImageContainer(BuildContext context, String imageUrl) {
    final hasImage = selectedImage != null || imageUrl.isNotEmpty;

    return Stack(
      children: [
        ClipOval(
          child: Container(
            height: context.screenHeight * 0.2,
            width: context.screenHeight * 0.2,
            decoration: const BoxDecoration(
              color: AppColors.kFillGrayColor,
              shape: BoxShape.circle,
            ),
            child: GestureDetector(
              onTap: hasImage
                  ? () {
                      showDialog(
                        context: context,
                        builder: (context) => _buildImageDialog(
                          context,
                          selectedImage,
                          imageUrl,
                        ),
                      );
                    }
                  : onImagePick,
              child: selectedImage != null
                  ? Image.file(
                      selectedImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(
                          Icons.person,
                          color: AppColors.kGrayColor,
                          size: 60,
                        ),
                      ),
                    )
                  : imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                            child: Icon(
                              Icons.person,
                              color: AppColors.kGrayColor,
                              size: 60,
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.person,
                            color: AppColors.kGrayColor,
                            size: 60,
                          ),
                        ),
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          left: 10,
          child: Container(
            height: context.screenHeight * 0.04,
            width: context.screenHeight * 0.04,
            decoration: BoxDecoration(
              color: AppColors.kWiteColor,
              border: Border.all(color: AppColors.kGrayColor),
              borderRadius: const BorderRadius.all(Radius.circular(100)),
            ),
            child: InkWell(
              onTap: onImagePick,
              child: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.kGrayColor,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageDialog(
    BuildContext context,
    File? selectedImage,
    String imageUrl,
  ) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.kWiteColor,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: context.screenHeight * 0.6,
          maxWidth: context.screenWidth * 0.8,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            selectedImage != null
                ? Image.file(
                    selectedImage,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Text(
                        'فشل تحميل الصورة',
                        style: TextStyle(color: AppColors.kGrayColor),
                      ),
                    ),
                  )
                : imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                          child: Text(
                            'فشل تحميل الصورة',
                            style: TextStyle(color: AppColors.kGrayColor),
                          ),
                        ),
                      )
                    : const Center(
                        child: Text(
                          'لا توجد صورة',
                          style: TextStyle(color: AppColors.kGrayColor),
                        ),
                      ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close,
                  color: AppColors.kGrayColor,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Icon _buildEditIcon() =>
      const Icon(Icons.edit_outlined, color: AppColors.kGrayColor);

  Icon _buildLockIcon() =>
      const Icon(Icons.lock_outlined, color: AppColors.kGrayColor);
}