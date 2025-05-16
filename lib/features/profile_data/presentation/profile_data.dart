import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hadaer_blady/core/constants.dart';
import 'package:hadaer_blady/core/functions/build_app_bar_with_arrow_back_button.dart';
import 'package:hadaer_blady/core/functions/show_snack_bar.dart';
import 'package:hadaer_blady/core/services/shared_prefs_singleton.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/widgets/loading_indicator.dart';
import 'package:hadaer_blady/features/profile_data/cubit/profile_cubit.dart';
import 'package:hadaer_blady/features/profile_data/widgets/profile_data_body.dart';
import 'package:image_picker/image_picker.dart';

class ProfileData extends StatefulWidget {
  const ProfileData({super.key});
  static const id = 'ProfileData';

  @override
  _ProfileDataState createState() => _ProfileDataState();
}

class _ProfileDataState extends State<ProfileData> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  File? _selectedImage;
  late ProfileCubit _profileCubit;
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _profileCubit = ProfileCubit();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    // First check if we have cached data in SharedPreferences
    bool hasLocalData = _loadFromSharedPreferences();

    // Only fetch from Firebase if necessary
    if (!hasLocalData) {
      await _profileCubit.fetchUserData();
      _userData =
          (_profileCubit.state is ProfileLoaded)
              ? (_profileCubit.state as ProfileLoaded).userData
              : {};
    }

    setState(() {
      _isLoading = false;
    });
  }

  bool _loadFromSharedPreferences() {
    // Check if we have sufficient data in SharedPreferences
    final hasName =
        Prefs.getUserName().isNotEmpty && Prefs.getUserName() != 'User';
    final hasEmail = Prefs.getUserEmail().isNotEmpty;
    final hasPhone = Prefs.getUserPhone().isNotEmpty;
    final hasCity = Prefs.getUserCity().isNotEmpty;
    final hasAddress = Prefs.getUserAddress().isNotEmpty;

    // If we have most of the data locally, consider it sufficient
    final hasLocalData = hasName && hasEmail && hasPhone;

    if (hasLocalData) {
      // Construct userData from SharedPreferences
      _userData = {
        'name': Prefs.getUserName(),
        'email': Prefs.getUserEmail(),
        'phone': Prefs.getUserPhone(),
        'city': Prefs.getUserCity(),
        'address': Prefs.getUserAddress(),
        'profile_image_url': Prefs.getProfileImageUrl(),
      };
    }

    return hasLocalData;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _profileCubit,
      child: Scaffold(
        backgroundColor: AppColors.kWiteColor,
        appBar: buildAppBarWithArrowBackButton(
          title: 'الملف الشخصي',
          context: context,
        ),
        body: SafeArea(
          child: BlocConsumer<ProfileCubit, ProfileState>(
            listener: (context, state) {
              if (state is ProfileError) {
                showSnackBarMethode(context, state.message);
              } else if (state is ProfileUpdated) {
                showSnackBarMethode(context, 'تم تحديث البيانات بنجاح');
                // Update local data after successful update
                setState(() {
                  _userData = state.userData;
                });
              }
            },
            builder: (context, state) {
              // Show loading indicator only when initially loading or updating profile
              final isLoading = _isLoading || state is ProfileLoading;

              return LoadingOverlay(
                isLoading: isLoading,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: khorizintalPadding,
                  ),
                  child: ProfileDataBody(
                    userData: _userData,
                    nameController: _nameController,
                    emailController: _emailController,
                    phoneController: _phoneController,
                    cityController: _cityController,
                    addressController: _addressController,
                    selectedImage: _selectedImage,
                    onImagePick: _pickImage,
                    onSave: () => _onSaved(context),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _onSaved(BuildContext context) {
    context.read<ProfileCubit>().updateUserData(
      name: _nameController.text,
      phone: _phoneController.text,
      city: _cityController.text,
      address: _addressController.text,
      profileImage: _selectedImage,
    );
  }
}
