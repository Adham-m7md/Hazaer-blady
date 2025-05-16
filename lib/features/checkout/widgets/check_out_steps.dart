import 'package:flutter/material.dart';
import 'package:hadaer_blady/features/checkout/widgets/active_step_item.dart';
import 'package:hadaer_blady/features/checkout/widgets/in_active_icon.dart';

class CheckOutSteps extends StatelessWidget {
  const CheckOutSteps({super.key, required this.currentIndexPage});
  final int currentIndexPage;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(getStepsTitles().length, (index) {
        return StepItem(
          isActive: index <= currentIndexPage,
          text: getStepsTitles()[index],
          index: index.toString(),
        );
      }),
    );
  }
}

List<String> getStepsTitles() => const ['البيانات', 'المراجعة'];

class StepItem extends StatelessWidget {
  const StepItem({
    super.key,
    required this.isActive,
    required this.text,
    required this.index,
  });
  final bool isActive;
  final String text, index;
  @override
  Widget build(BuildContext context) {
    return isActive
        ? ActiveStepItem(text: text)
        : InActiveStepIcon(text: text, index: index);
  }
}
