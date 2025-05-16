part of 'add_product_cubit.dart';

class AddProductState {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController priceController;
  final File? image;
  final int minWeight;
  final int maxWeight;
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  AddProductState({
    TextEditingController? nameController,
    TextEditingController? descriptionController,
    TextEditingController? priceController,
    this.image,
    this.minWeight = 1,
    this.maxWeight = 1,
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  }) : nameController = nameController ?? TextEditingController(),
       descriptionController = descriptionController ?? TextEditingController(),
       priceController = priceController ?? TextEditingController();

  AddProductState copyWith({
    TextEditingController? nameController,
    TextEditingController? descriptionController,
    TextEditingController? priceController,
    File? image,
    int? minWeight,
    int? maxWeight,
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return AddProductState(
      nameController: nameController ?? this.nameController,
      descriptionController:
          descriptionController ?? this.descriptionController,
      priceController: priceController ?? this.priceController,
      image: image ?? this.image,
      minWeight: minWeight ?? this.minWeight,
      maxWeight: maxWeight ?? this.maxWeight,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  // Calculate average weight
  double get averageWeight => (minWeight + maxWeight) / 2;

  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
  }
}
