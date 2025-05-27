import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/features/product/cubit/product_details_cubit.dart';

class QuantitySelector extends StatefulWidget {
  final int quantity;

  const QuantitySelector({super.key, required this.quantity});

  @override
  State<QuantitySelector> createState() => _QuantitySelectorState();
}

class _QuantitySelectorState extends State<QuantitySelector> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.quantity.toString());
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(QuantitySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quantity != widget.quantity) {
      _controller.text = widget.quantity.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateQuantity(String value) {
    final newQuantity = int.tryParse(value);
    if (newQuantity != null && newQuantity > 0) {
      context.read<ProductDetailsCubit>().updateQuantity(newQuantity);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('الكمية: ', style: TextStyles.semiBold16),
        const Spacer(),
        GestureDetector(
          onTap: () => context.read<ProductDetailsCubit>().incrementQuantity(),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: AppColors.lightPrimaryColor.withAlpha(80),
            ),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Text('+50', style: TextStyles.semiBold16),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 80,
          height: 35,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6), // حد أقصى 6 أرقام
            ],
            style: TextStyles.semiBold16,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              isDense: true,
            ),
            onChanged: _updateQuantity,
            onSubmitted: (value) {
              _updateQuantity(value);
              _focusNode.unfocus();
            },
            onTapOutside: (event) {
              _updateQuantity(_controller.text);
              _focusNode.unfocus();
            },
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => context.read<ProductDetailsCubit>().decrementQuantity(),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(100)),
              color: AppColors.kGrayColor.withAlpha(40),
            ),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Text('-50', style: TextStyles.semiBold16),
            ),
          ),
        ),
      ],
    );
  }
}
