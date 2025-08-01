import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hadaer_blady/core/constants.dart';
import 'package:hadaer_blady/core/functions/build_app_bar_with_arrow_back_button.dart';
import 'package:hadaer_blady/core/functions/show_snack_bar.dart';
import 'package:hadaer_blady/core/functions/validate_method.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_directions.dart';
import 'package:hadaer_blady/core/widgets/custom_button.dart';
import 'package:hadaer_blady/core/widgets/custom_text_form_feild.dart';
import 'package:hadaer_blady/core/widgets/custom_tittel.dart';
import 'package:hadaer_blady/core/widgets/custome_show_dialog.dart';
import 'package:hadaer_blady/features/add_custom_product/cubit/add_custom_product_cubit.dart';
import 'package:hadaer_blady/features/add_custom_product/cubit/add_custom_product_state.dart';
import 'package:hadaer_blady/features/add_product/view/add_product_screen.dart';
import 'package:hadaer_blady/features/home/presentation/home_screen.dart';

class AddCustomProductScreen extends StatelessWidget {
  const AddCustomProductScreen({super.key});

  static const id = 'AddCustomProductScreen';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AddCustomProductCubit(),
      child: BlocConsumer<AddCustomProductCubit, AddCustomProductState>(
        listener: (context, state) {
          if (state is AddCustomProductSuccess) {
            showDialog(
              context: context,
              builder:
                  (context) => CustomeShowDialog(
                    text: 'تم إضافة عرض مميز بنجاح',
                    buttonText: 'العودة للرئيسية',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(initialTabIndex: 0),
                        ),
                      );
                    },
                  ),
            );
          } else if (state is AddCustomProductFailure) {
            showSnackBarMethode(context, state.errorMessage);
          }
        },
        builder: (context, state) {
          final cubit = context.read<AddCustomProductCubit>();
          return Scaffold(
            backgroundColor: AppColors.kWiteColor,
            appBar: buildAppBarWithArrowBackButton(
              title: 'إضافة عرض مميز',
              context: context,
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(khorizintalPadding),
                child: Form(
                  key: cubit.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CustomTittel(text: 'صورة العرض :'),
                      ImagePickerWidget(
                        image: cubit.selectedImage,
                        onTap: () => cubit.pickImage(context),
                      ),
                      if (state is AddCustomProductImageError)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            state.errorMessage,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      const SizedBox(height: 12),
                      const CustomTittel(text: 'بيانات العرض :'),
                      AddCustomProductFields(cubit: cubit),
                      SizedBox(height: context.screenHeight * 0.08),
                      CustomButton(
                        onPressed: () => cubit.submitProduct(context),
                        text:
                            state is AddCustomProductLoading
                                ? 'جاري الإضافة'
                                : 'إضافة',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AddCustomProductFields extends StatelessWidget {
  final AddCustomProductCubit cubit;

  const AddCustomProductFields({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        CustomTextFormFeild(
          controller: cubit.titleController,
          hintText: 'أضف عنوان وصف العرض',
          keyBoardType: TextInputType.text,
          validator: (value) => validateField(value, 'عنوان العرض'),
        ),
        const SizedBox(height: 8),
        CustomTextFormFeild(
          controller: cubit.descriptionController,
          hintText: 'أضف وصف العرض',
          keyBoardType: TextInputType.text,
          validator: (value) => validateField(value, 'وصف العرض'),
          maxLines: 3,
        ),
        const SizedBox(height: 8),
        CustomTextFormFeild(
          controller: cubit.priceController,
          hintText: 'ادخل سعر العرض',
          keyBoardType: TextInputType.number,
          validator: (value) => validateField(value, 'سعر العرض'),
        ),
        const SizedBox(height: 8),
        CustomTextFormFeild(
          controller: cubit.locationController,
          hintText: 'أضف المكان المتاح للعرض',
          keyBoardType: TextInputType.text,
          validator: (value) => validateField(value, 'مكان العرض'),
        ),
      ],
    );
  }
}
