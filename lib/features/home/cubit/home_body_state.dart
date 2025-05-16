
import 'package:equatable/equatable.dart';
import 'package:hadaer_blady/features/home/cubit/home_body_cubit.dart';
import 'package:hadaer_blady/features/product/presentation/product.dart';

abstract class ProductFilterState extends Equatable {
  final ProductFilter currentFilter;
  final List<Product> products;
  final String? errorMessage;

  const ProductFilterState({
    required this.currentFilter,
    required this.products,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [currentFilter, products, errorMessage];
}

// حالة التحميل
class ProductFilterLoading extends ProductFilterState {
  const ProductFilterLoading({
    required super.currentFilter,
    required super.products,
  });
}

// حالة النجاح مع البيانات
class ProductFilterSuccess extends ProductFilterState {
  const ProductFilterSuccess({
    required super.currentFilter,
    required super.products,
  });
}

// حالة الخطأ
class ProductFilterError extends ProductFilterState {
  const ProductFilterError({
    required super.currentFilter,
    required super.products,
    required super.errorMessage,
  });
}

// حالة عدم وجود بيانات
class ProductFilterEmpty extends ProductFilterState {
  const ProductFilterEmpty({
    required super.currentFilter,
    required super.products,
  });
}