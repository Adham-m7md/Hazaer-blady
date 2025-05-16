import 'package:get_it/get_it.dart';
import 'package:hadaer_blady/core/services/cart_service.dart';
import 'package:hadaer_blady/core/services/custom_product_servise.dart';
import 'package:hadaer_blady/core/services/firebase_auth_service.dart';
import 'package:hadaer_blady/core/services/product_service.dart';
import 'package:hadaer_blady/features/auth/data/repos/auth_repo_implimentation.dart';
import 'package:hadaer_blady/features/auth/domain/repos/auth_repo.dart';

final getIt = GetIt.instance;

void setupGetIt() {
  getIt.registerSingleton<FirebaseAuthService>(FirebaseAuthService());
  getIt.registerSingleton<AuthRepo>(
    AuthRepoImplimentation(firebaseAuthService: getIt<FirebaseAuthService>()),
  );
  getIt.registerSingleton<ProductService>(ProductService());

  // Register CustomProductService
  getIt.registerSingleton<CustomProductService>(CustomProductService());
  getIt.registerSingleton<CartService>(CartService());
}
