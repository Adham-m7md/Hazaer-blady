part of 'my_coop_cubit.dart';

// State classes
abstract class MyCoopState {}

class MyCoopInitial extends MyCoopState {}

class MyCoopLoading extends MyCoopState {}

class MyCoopError extends MyCoopState {
  final String message;
  MyCoopError(this.message);
}

class MyCoopUserData extends MyCoopState {
  final Map<String, dynamic> userData;
  final bool isCoopOwner;
  final bool isAdmin;
  final String userId;
  final List<ProductModel>? regularProducts;
  final List<ProductModel>? specialOffers;
  final bool isRegularProductsLoading;
  final bool isSpecialOffersLoading;
  final String? regularProductsError;
  final String? specialOffersError;

  MyCoopUserData({
    required this.userData,
    required this.isCoopOwner,
    required this.isAdmin,
    required this.userId,
    this.regularProducts,
    this.specialOffers,
    this.isRegularProductsLoading = false,
    this.isSpecialOffersLoading = false,
    this.regularProductsError,
    this.specialOffersError,
  });

  MyCoopUserData copyWith({
    Map<String, dynamic>? userData,
    bool? isCoopOwner,
    bool? isAdmin,
    String? userId,
    List<ProductModel>? regularProducts,
    List<ProductModel>? specialOffers,
    bool? isRegularProductsLoading,
    bool? isSpecialOffersLoading,
    String? regularProductsError,
    String? specialOffersError,
  }) {
    return MyCoopUserData(
      userData: userData ?? this.userData,
      isCoopOwner: isCoopOwner ?? this.isCoopOwner,
      isAdmin: isAdmin ?? this.isAdmin,
      userId: userId ?? this.userId,
      regularProducts: regularProducts ?? this.regularProducts,
      specialOffers: specialOffers ?? this.specialOffers,
      isRegularProductsLoading:
          isRegularProductsLoading ?? this.isRegularProductsLoading,
      isSpecialOffersLoading:
          isSpecialOffersLoading ?? this.isSpecialOffersLoading,
      regularProductsError: regularProductsError ?? this.regularProductsError,
      specialOffersError: specialOffersError ?? this.specialOffersError,
    );
  }
}

class MyCoopUnauthenticated extends MyCoopState {}

class MyCoopAccessDenied extends MyCoopState {}
