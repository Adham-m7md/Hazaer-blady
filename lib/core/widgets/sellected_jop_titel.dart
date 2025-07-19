import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart' show TextStyles;

class SelectJopTitel extends StatefulWidget {
  final void Function(String?)? onSaved;
  final String? Function(String?)? validator;

  const SelectJopTitel({super.key, required this.onSaved, this.validator});

  @override
  State<SelectJopTitel> createState() => _SelectJopTitelState();
}

class _SelectJopTitelState extends State<SelectJopTitel> {
  String selectedJob = 'الوظيفة';
  final ExpansibleController controller = ExpansibleController();

  // Create a FormFieldState to integrate with Form
  final GlobalKey<FormFieldState> _fieldKey = GlobalKey<FormFieldState>();

  @override
  Widget build(BuildContext context) {
    final Color textColor =
        selectedJob == 'الوظيفة' ? AppColors.kGrayColor : AppColors.kBlackColor;

    final ThemeData theme = Theme.of(context);
    final Color errorColor = theme.colorScheme.error;

    return FormField<String>(
      key: _fieldKey,
      validator: widget.validator,
      onSaved: widget.onSaved,
      initialValue: selectedJob,
      builder: (FormFieldState<String> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  width: 1,
                  color:
                      state.hasError ? errorColor : AppColors.klightGrayColor,
                ),
                color: AppColors.kFillGrayColor,
              ),
              width: double.infinity,
              child: ExpansionTile(
                controller: controller,
                tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                title: Text(
                  selectedJob,
                  style: TextStyles.semiBold13.copyWith(color: textColor),
                ),
                collapsedIconColor: AppColors.kGrayColor,
                children: [
                  ListTile(
                    title: const Text('تاجر'),
                    onTap: () {
                      setState(() {
                        selectedJob = 'تاجر';
                        state.didChange(selectedJob);
                        state.validate(); // Rerun validation after selection
                      });
                      controller.collapse();
                    },
                  ),
                  ListTile(
                    title: const Text('صاحب حظيرة'),
                    onTap: () {
                      setState(() {
                        selectedJob = 'صاحب حظيرة';
                        state.didChange(selectedJob);
                        state.validate(); // Rerun validation after selection
                      });
                      controller.collapse();
                    },
                  ),
                ],
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(right: 12, top: 8),
                child: Text(
                  state.errorText!,
                  style: TextStyle(color: errorColor, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }
}
