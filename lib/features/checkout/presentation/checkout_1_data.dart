import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/services/shared_prefs_singleton.dart';
import 'package:hadaer_blady/core/utils/app_directions.dart';
import 'package:hadaer_blady/core/widgets/custom_text_form_feild.dart';
import 'package:hadaer_blady/core/widgets/custom_tittel.dart';
import 'package:hadaer_blady/core/widgets/my_custom_check_togel.dart';

class Checkout1Data extends StatefulWidget {
  final Function(Map<String, String>)? onDataSubmitted;

  const Checkout1Data({super.key, this.onDataSubmitted});

  @override
  State<Checkout1Data> createState() => Checkout1DataState();
}

class Checkout1DataState extends State<Checkout1Data> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  bool isActive = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  void _loadSavedData() {
    final isSaved = Prefs.isCheckoutSaved();
    final savedToggle = Prefs.getCheckoutToggle();

    setState(() {
      isActive = savedToggle;
      if (isSaved) {
        _nameController.text = Prefs.getCheckoutName();
        _phoneController.text = Prefs.getCheckoutPhone();
        _cityController.text = Prefs.getCheckoutCity();
        _addressController.text = Prefs.getCheckoutAddress();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void submitData() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (isActive) {
        await Prefs.setCheckoutName(_nameController.text);
        await Prefs.setCheckoutPhone(_phoneController.text);
        await Prefs.setCheckoutCity(_cityController.text);
        await Prefs.setCheckoutAddress(_addressController.text);
        await Prefs.setCheckoutSaved(true); // نحفظ إنها محفوظة
      } else {
        await Prefs.clearCheckoutData(); // نمسح البيانات القديمة
      }

      widget.onDataSubmitted?.call({
        'name': _nameController.text,
        'phone': _phoneController.text,
        'city': _cityController.text,
        'address': _addressController.text,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: CustomTittel(text: "املأ البيانات :"),
            ),
            CustomTextFormFeild(
              hintText: 'الاسم كامل',
              controller: _nameController,
              keyBoardType: TextInputType.name,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال الاسم';
                }
                return null;
              },
            ),
            CustomTextFormFeild(
              hintText: 'رقم الهاتف',
              controller: _phoneController,
              keyBoardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال رقم الهاتف';
                }
                if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                  return 'رقم الهاتف غير صالح';
                }
                return null;
              },
            ),
            CustomTextFormFeild(
              hintText: 'المدينة',
              controller: _cityController,
              keyBoardType: TextInputType.name,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال المدينة';
                }
                return null;
              },
            ),
            CustomTextFormFeild(
              hintText: 'العنوان التفصيلي',
              controller: _addressController,
              keyBoardType: TextInputType.streetAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال العنوان';
                }
                return null;
              },
            ),
            Row(
              spacing: context.screenWidth * 0.03,
              children: [
                MyCustomCheckTogel(
                  isActive: isActive,
                  onChanged: () async {
                    setState(() {
                      isActive = !isActive;
                    });
                    await Prefs.setCheckoutToggle(isActive);
                  },
                ),
                Text('حفظ البيانات لعمليات الشراء القادمة'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
