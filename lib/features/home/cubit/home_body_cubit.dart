import 'package:flutter_bloc/flutter_bloc.dart';

enum ProductFilter { none, topRated, nearest, mostOffers }

class ProductFilterCubit extends Cubit<ProductFilter> {
  ProductFilterCubit() : super(ProductFilter.none);

  void changeFilter(ProductFilter filter) => emit(filter);
}