import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hadaer_blady/core/constants.dart';
import 'package:hadaer_blady/core/services/get_it.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_directions.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/core/widgets/custom_text_form_feild.dart';
import 'package:hadaer_blady/core/widgets/custom_tittel.dart';
import 'package:hadaer_blady/core/widgets/custome_show_dialog.dart';
import 'package:hadaer_blady/features/add_product/cubit/add_product_cubit.dart';
import 'package:hadaer_blady/features/add_product/widgets/add_product_button.dart';
import 'package:hadaer_blady/features/home/presentation/home_screen.dart';

class AddProductScreen extends StatelessWidget {
  const AddProductScreen({super.key});
  static const String id = 'AddProductScreen';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AddProductCubit(getIt()),
      child: const _AddProductView(),
    );
  }
}

class _AddProductView extends StatelessWidget {
  const _AddProductView();

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();

    return Scaffold(
      backgroundColor: AppColors.kWiteColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            right: khorizintalPadding,
            left: khorizintalPadding,
            top: 12,
          ),
          child: Column(
            spacing: 12,
            children: [
              const Text('اضافة منتج', style: TextStyles.bold19),
              Expanded(
                child: BlocConsumer<AddProductCubit, AddProductState>(
                  listener: (context, state) {
                    if (state.isSuccess) {
                      showDialog(
                        context: context,
                        builder:
                            (context) => CustomeShowDialog(
                              text: 'تم إضافة منتج بنجاح',
                              buttonText: 'العودة للرئيسية',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            HomeScreen(initialTabIndex: 0),
                                  ),
                                );
                              },
                            ),
                      );
                    }
                    if (state.errorMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.errorMessage!)),
                      );
                    }
                  },
                  builder: (context, state) {
                    final cubit = context.read<AddProductCubit>();
                    // Calculate totalPrice for UI display

                    return Form(
                      key: formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          spacing: 12,
                          children: [
                            SizedBox(height: 12),
                            const CustomTittel(text: 'صورة المنتج :'),
                            ImagePickerWidget(
                              image: state.image,
                              onTap: cubit.pickImage,
                            ),
                            const CustomTittel(text: 'بيانات المنتج :'),
                            _ProductFormFields(
                              nameController: state.nameController,
                              descriptionController:
                                  state.descriptionController,
                              priceController: state.priceController,
                              formKey: formKey,
                            ),
                            _WeightSelector(
                              minWeight: state.minWeight,
                              maxWeight: state.maxWeight,
                              onMinWeightChanged: cubit.updateMinWeight,
                              onMaxWeightChanged: cubit.updateMaxWeight,
                            ),

                            SizedBox(height: context.screenHeight * 0.02),
                            AddProductButton(
                              onPressed:
                                  state.isLoading
                                      ? null
                                      : () {
                                        if (formKey.currentState!.validate()) {
                                          cubit.addProduct();
                                        }
                                      },
                              text:
                                  state.isLoading
                                      ? 'جاري الإضافة...'
                                      : 'أضف المنتج',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ImagePickerWidget extends StatelessWidget {
  final File? image;
  final VoidCallback onTap;

  const ImagePickerWidget({
    super.key,
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: context.screenHeight * 0.25,
        decoration: BoxDecoration(
          color: AppColors.kFillGrayColor,
          borderRadius: const BorderRadius.all(Radius.circular(4)),
          image:
              image != null
                  ? DecorationImage(image: FileImage(image!), fit: BoxFit.cover)
                  : null,
        ),
        child:
            image == null
                ? const Icon(
                  Icons.add_a_photo_outlined,
                  color: AppColors.kGrayColor,
                  size: 40,
                )
                : null,
      ),
    );
  }
}

class _ProductFormFields extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController priceController;
  final GlobalKey<FormState> formKey;

  const _ProductFormFields({
    required this.nameController,
    required this.descriptionController,
    required this.priceController,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      children: [
        CustomTextFormFeild(
          hintText: 'اسم المنتج',
          controller: nameController,
          keyBoardType: TextInputType.text,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'الرجاء إدخال اسم المنتج';
            }
            return null;
          },
        ),
        CustomTextFormFeild(
          hintText: 'وصف المنتج',
          controller: descriptionController,
          keyBoardType: TextInputType.text,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'الرجاء إدخال وصف المنتج';
            }
            return null;
          },
        ),
        CustomTextFormFeild(
          maxLength: 6,
          hintText: 'السعر للكيلو',
          controller: priceController,
          keyBoardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'الرجاء إدخال السعر';
            }
            if (double.tryParse(value) == null || double.parse(value) <= 0) {
              return 'الرجاء إدخال سعر صحيح';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class _WeightSelector extends StatelessWidget {
  final int minWeight;
  final int maxWeight;
  final ValueChanged<int> onMinWeightChanged;
  final ValueChanged<int> onMaxWeightChanged;

  const _WeightSelector({
    required this.minWeight,
    required this.maxWeight,
    required this.onMinWeightChanged,
    required this.onMaxWeightChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('الوزن : ', style: TextStyles.semiBold16),
        Row(
          children: [
            const Text('من', style: TextStyles.semiBold16),
            PopupMenuButton<int>(
              position: PopupMenuPosition.under,
              color: AppColors.kFillGrayColor,
              onSelected: onMinWeightChanged,
              itemBuilder:
                  (context) => List.generate(
                    6,
                    (index) => PopupMenuItem(
                      value: index + 1,
                      child: Text('${index + 1}', style: TextStyles.bold16),
                    ),
                  ),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.klightGrayColor,
                  borderRadius: BorderRadius.all(Radius.circular(50)),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Text('$minWeight', style: TextStyles.semiBold16),
              ),
            ),
            const Text('~', style: TextStyles.bold28),
            const Text('الى', style: TextStyles.semiBold16),
            PopupMenuButton<int>(
              position: PopupMenuPosition.under,
              color: AppColors.kFillGrayColor,
              onSelected: onMaxWeightChanged,
              itemBuilder:
                  (context) => List.generate(
                    6,
                    (index) => PopupMenuItem(
                      value: index + 1,
                      child: Text('${index + 1}', style: TextStyles.bold16),
                    ),
                  ),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.klightGrayColor,
                  borderRadius: BorderRadius.all(Radius.circular(50)),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Text('$maxWeight', style: TextStyles.semiBold16),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
