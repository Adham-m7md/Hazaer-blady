abstract class AddCustomProductState {}

class AddCustomProductInitial extends AddCustomProductState {}

class AddCustomProductLoading extends AddCustomProductState {}

class AddCustomProductSuccess extends AddCustomProductState {
  final String productId;
  AddCustomProductSuccess({required this.productId});
}

class AddCustomProductFailure extends AddCustomProductState {
  final String errorMessage;
  AddCustomProductFailure({required this.errorMessage});
}

class AddCustomProductImageError extends AddCustomProductState {
  final String errorMessage;
  AddCustomProductImageError({required this.errorMessage});
}
