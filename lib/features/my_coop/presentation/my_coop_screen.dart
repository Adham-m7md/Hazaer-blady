import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hadaer_blady/core/constants.dart';
import 'package:hadaer_blady/core/functions/build_app_bar_with_arrow_back_button.dart';
import 'package:hadaer_blady/core/functions/show_snack_bar.dart';
import 'package:hadaer_blady/core/services/custom_product_servise.dart';
import 'package:hadaer_blady/core/services/firebase_auth_service.dart';
import 'package:hadaer_blady/core/services/get_it.dart';
import 'package:hadaer_blady/core/services/product_service.dart';
import 'package:hadaer_blady/core/services/rating_service.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/core/widgets/custom_loading_indicator.dart';
import 'package:hadaer_blady/features/add_custom_product/presentation/custom_product_screen_details.dart';
import 'package:hadaer_blady/features/add_product/data/product_model.dart';
import 'package:hadaer_blady/features/home/presentation/widgets/custom_offers_list/custom_offer.dart';
import 'package:hadaer_blady/features/home/presentation/widgets/custom_offers_list/offer_carousel.dart';
import 'package:hadaer_blady/features/my_coop/cubit/my_coop_cubit.dart';
import 'package:hadaer_blady/features/product/presentation/product.dart';
import 'package:hadaer_blady/features/product/presentation/product_details_screen.dart';
import 'package:hadaer_blady/features/rateing/cubit/rating_cubit.dart';
import 'package:hadaer_blady/features/rateing/cubit/rating_state.dart';
import 'package:hadaer_blady/features/rateing/view/rating_screen.dart';

class MyCoopScreen extends StatefulWidget {
  const MyCoopScreen({super.key});
  static const id = 'MyCoopScreen';

  @override
  State<MyCoopScreen> createState() => _MyCoopScreenState();
}

class _MyCoopScreenState extends State<MyCoopScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final MyCoopCubit _coopCubit;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _coopCubit = MyCoopCubit(
      authService: getIt<FirebaseAuthService>(),
      productService: getIt<ProductService>(),
      customProductService: getIt<CustomProductService>(),
    );
    _coopCubit.initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _coopCubit,
      child: BlocBuilder<MyCoopCubit, MyCoopState>(
        builder: (context, state) {
          if (state is MyCoopInitial || state is MyCoopLoading) {
            return _buildLoadingScaffold();
          } else if (state is MyCoopUnauthenticated) {
            return _buildLoginRequiredScaffold(context);
          } else if (state is MyCoopAccessDenied) {
            return _buildAccessDeniedScaffold(context);
          } else if (state is MyCoopError) {
            return _buildErrorScaffold(context, state.message);
          } else if (state is MyCoopUserData) {
            return _buildMainScaffold(context, state);
          }
          return _buildErrorScaffold(context, 'حالة غير معروفة');
        },
      ),
    );
  }

  Widget _buildLoadingScaffold() {
    return const Scaffold(
      backgroundColor: AppColors.kWiteColor,
      body: Center(child: CustomLoadingIndicator()),
    );
  }

  Widget _buildLoginRequiredScaffold(BuildContext context) {
    return Scaffold(
      appBar: buildAppBarWithArrowBackButton(title: 'حظيرتي', context: context),
      body: const Center(child: Text('يرجى تسجيل الدخول لعرض الحظيرة')),
    );
  }

  Widget _buildAccessDeniedScaffold(BuildContext context) {
    return Scaffold(
      appBar: buildAppBarWithArrowBackButton(title: 'حظيرتي', context: context),
      body: const Center(
        child: Text(
          'هذه الصفحة متاحة فقط لأصحاب الحظائر أو المشرفين',
          style: TextStyles.semiBold16,
        ),
      ),
    );
  }

  Widget _buildErrorScaffold(BuildContext context, String errorMessage) {
    return Scaffold(
      appBar: buildAppBarWithArrowBackButton(title: 'حظيرتي', context: context),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color: AppColors.kRedColor,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                style: TextStyles.semiBold16,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _coopCubit.initialize(),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainScaffold(BuildContext context, MyCoopUserData state) {
    return Scaffold(
      backgroundColor: AppColors.kWiteColor,
      appBar: buildAppBarWithArrowBackButton(title: 'حظيرتي', context: context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileSection(state),
          if (state.isAdmin) _buildTabBar(),
          Expanded(
            child:
                state.isAdmin
                    ? _buildTabBarView(state)
                    : _buildProductsList(state, false),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(MyCoopUserData state) {
    return Container(
      color: AppColors.kWiteColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileImage(state.userData),
          _buildProfileDetails(state),
        ],
      ),
    );
  }

  Widget _buildProfileImage(Map<String, dynamic> userData) {
    final hasImage = userData['profile_image_url']?.isNotEmpty ?? false;
    return hasImage
        ? Image.network(
          userData['profile_image_url'],
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) => _buildDefaultProfileContainer(),
        )
        : _buildDefaultProfileContainer();
  }

  Widget _buildDefaultProfileContainer() {
    return Container(
      color: AppColors.kFillGrayColor,
      width: double.infinity,
      height: 180,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person, color: AppColors.kGrayColor, size: 40),
            Text('لا يوجد صورة', style: TextStyles.semiBold16),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileDetails(MyCoopUserData state) {
    final userData = state.userData;
    final userId = state.userId;
    log('Passing userId to RatingDisplay: $userId');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: khorizintalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          _buildProfileRow('مدينتى  : ', userData['city'] ?? 'غير محدد'),
          _buildProfileRow(
            'عنوانى : ',
            userData['address'] ?? 'غير محدد',
            true,
          ),
          BlocProvider(
            create:
                (context) => RatingCubit(
                  ratingService: RatingService(),
                  auth: FirebaseAuth.instance,
                  userId: userId,
                ),
            child: RatingDisplay(userId: userId),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildProfileRow(
    String label,
    String value, [
    bool isExpanded = false,
  ]) {
    return Row(
      children: [
        Text(label, style: TextStyles.semiBold16),
        const SizedBox(width: 8),
        isExpanded
            ? Expanded(child: Text(value, style: TextStyles.semiBold16))
            : Text(value, style: TextStyles.semiBold16),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.kprimaryColor.withOpacity(0.1),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.kprimaryColor,
        labelColor: AppColors.kprimaryColor,
        unselectedLabelColor: AppColors.kGrayColor,
        tabs: const [Tab(text: 'المنتجات العادية'), Tab(text: 'العروض الخاصة')],
      ),
    );
  }

  Widget _buildTabBarView(MyCoopUserData state) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildProductsList(state, false),
        _buildProductsList(state, true),
      ],
    );
  }

  Widget _buildProductsList(MyCoopUserData state, bool isSpecialOffer) {
    final isLoading =
        isSpecialOffer
            ? state.isSpecialOffersLoading
            : state.isRegularProductsLoading;
    final error =
        isSpecialOffer ? state.specialOffersError : state.regularProductsError;
    final products =
        isSpecialOffer ? state.specialOffers : state.regularProducts;

    if (isLoading) {
      return const Center(child: CustomLoadingIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('خطأ: $error', style: TextStyles.semiBold16),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed:
                  () =>
                      isSpecialOffer
                          ? _coopCubit.loadSpecialOffers(state.userId)
                          : _coopCubit.loadRegularProducts(state.userId),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (products == null || products.isEmpty) {
      return _buildEmptyState(isSpecialOffer);
    }

    return _buildProductListView(
      products,
      state.userData,
      isSpecialOffer,
      state.userId,
    );
  }

  Widget _buildEmptyState(bool isSpecialOffer) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSpecialOffer
                  ? Icons.local_offer_outlined
                  : Icons.inventory_2_outlined,
              size: 60,
              color: AppColors.kGrayColor,
            ),
            const SizedBox(height: 16),
            Text(
              isSpecialOffer ? 'لا توجد عروض خاصة' : 'لا توجد منتجات',
              style: TextStyles.semiBold16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductListView(
    List<ProductModel> products,
    Map<String, dynamic> userData,
    bool isSpecialOffer,
    String userId,
  ) {
    if (isSpecialOffer) {
      final customProducts =
          products
              .map(
                (product) => _coopCubit.convertToCustomProduct(product, userId),
              )
              .toList();
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: khorizintalPadding,
                vertical: 8,
              ),
              child: Text(
                'العروض الخاصة (${products.length})',
                style: TextStyles.bold19,
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              scrollDirection: Axis.vertical,
              padding: const EdgeInsets.symmetric(
                horizontal: khorizintalPadding,
              ),
              itemCount: customProducts.length,
              itemBuilder: (context, index) {
                final customProduct = customProducts[index];
                final offer = OfferModel.fromProduct(customProduct, index);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap:
                            () => _handleProductTap(
                              products[index],
                              products[index].id,
                              userData,
                              isSpecialOffer,
                              userId,
                            ),
                        child: SizedBox(
                          width: 300,
                          child: CustomOffer(
                            key: ValueKey(customProduct.id),
                            offer: offer,
                            product: customProduct,
                            onButtonPressed: () {
                              log('Button pressed for offer: ${offer.title}');
                            },
                          ),
                        ),
                      ),
                      _buildDeleteButton(products[index], isSpecialOffer),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: khorizintalPadding,
              vertical: 8,
            ),
            child: Text(
              'المنتجات (${products.length})',
              style: TextStyles.bold19,
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            itemBuilder:
                (context, index) => _buildProductItem(
                  products[index],
                  userData,
                  isSpecialOffer,
                  index,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(
    ProductModel product,
    Map<String, dynamic> userData,
    bool isSpecialOffer,
    int index,
  ) {
    final productMap = product.toMap();
    final productId = product.id;

    if (productId.isEmpty) {
      log('Warning: Empty productId at index $index');
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: khorizintalPadding,
        vertical: 8,
      ),
      child: Stack(
        children: [
          GestureDetector(
            onTap:
                () => _handleProductTap(
                  product,
                  productId,
                  userData,
                  isSpecialOffer,
                  userData['uid'] ?? '',
                ),
            child: Product(
              product: {
                ...productMap,
                'city': userData['city'] ?? 'غير محدد',
                'quantity': productMap['quantity'] ?? 1000,
              },
              productId: productId,
            ),
          ),
          _buildDeleteButton(product, isSpecialOffer),
        ],
      ),
    );
  }

  void _handleProductTap(
    ProductModel product,
    String productId,
    Map<String, dynamic> userData,
    bool isSpecialOffer,
    String userId,
  ) {
    log('Tapped product with ID: $productId, isSpecialOffer: $isSpecialOffer');
    if (isSpecialOffer) {
      try {
        final customProduct = _coopCubit.convertToCustomProduct(
          product,
          userId,
        );
        log(
          'CustomProduct created successfully: ${customProduct.id}, ${customProduct.title}',
        );
        Navigator.pushNamed(
          context,
          CustomProductDetailScreen.id,
          arguments: customProduct,
        );
      } catch (e) {
        log('Error converting to CustomProduct: $e');
        showSnackBarMethode(context, 'خطأ في عرض التفاصيل: $e');
      }
    } else {
      Navigator.pushNamed(
        context,
        ProductDetailsScreen.id,
        arguments: {
          'productId': productId,
          'product': {
            ...product.toMap(),
            'city': userData['city'] ?? 'غير محدد',
            'quantity': product.toMap()['quantity'] ?? 1000,
          },
        },
      );
    }
  }

  Widget _buildDeleteButton(ProductModel product, bool isSpecialOffer) {
    return Positioned(
      top: 1,
      left: 1,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.kRedColor.withOpacity(0.8),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.delete, color: AppColors.kWiteColor, size: 18),
          onPressed:
              () => _showDeleteConfirmationDialog(
                context,
                product.id,
                product.toMap()['name'] ??
                    product.toMap()['title'] ??
                    'غير معروف',
                isSpecialOffer,
              ),
          constraints: const BoxConstraints(minHeight: 20, minWidth: 20),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    String productId,
    String productName,
    bool isSpecialOffer,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: AppColors.kWiteColor,
            title: const Text('تأكيد الحذف'),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  Text(
                    'هل أنت متأكد من حذف ${isSpecialOffer ? 'العرض' : 'المنتج'} "$productName"؟',
                  ),
                  const Text('لا يمكن التراجع عن هذا الإجراء.'),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text(
                  'إلغاء',
                  style: TextStyle(color: AppColors.kprimaryColor),
                ),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              TextButton(
                child: const Text(
                  'حذف',
                  style: TextStyle(color: AppColors.kRedColor),
                ),
                onPressed: () async {
                  try {
                    await _coopCubit.deleteProduct(productId, isSpecialOffer);
                    if (mounted) {
                      showSnackBarMethode(
                        context,
                        'تم حذف ${isSpecialOffer ? 'العرض' : 'المنتج'} "$productName" بنجاح',
                      );
                    }
                  } catch (error) {
                    if (mounted) {
                      showSnackBarMethode(
                        context,
                        'حدث خطأ أثناء الحذف: $error',
                      );
                    }
                  }
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          ),
    );
  }
}

class RatingDisplay extends StatelessWidget {
  final String userId;

  const RatingDisplay({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) {
      log('Invalid userId: empty userId provided');
      return const Text('معرف المستخدم غير صالح', style: TextStyles.semiBold16);
    }

    return BlocBuilder<RatingCubit, RatingState>(
      builder: (context, state) {
        if (state is RatingLoadingState) {
          return const Center(child: CustomLoadingIndicator());
        }
        if (state is RatingErrorState) {
          log('Error fetching ratings for userId $userId: ${state.message}');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'حدث خطأ أثناء جلب التقييمات',
                style: TextStyles.semiBold16,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.read<RatingCubit>().refreshRatings(),
                child: const Text(
                  'إعادة المحاولة',
                  style: TextStyle(color: AppColors.kprimaryColor),
                ),
              ),
            ],
          );
        }
        double averageRating = 0.0;
        if (state is RatingSuccessState) {
          averageRating = state.averageRating;
        }
        return Row(
          children: [
            const Text('التقييمات :', style: TextStyles.semiBold16),
            const SizedBox(width: 8),
            Row(
              spacing: 4,
              children: [
                Text(
                  averageRating.toStringAsFixed(1),
                  style: TextStyles.semiBold16,
                ),
                const Icon(Icons.star, color: Color(0xffFFC529), size: 28),
                InkWell(
                  onTap:
                      () => Navigator.pushNamed(
                        context,
                        RatingScreen.id,
                        arguments: userId,
                      ),
                  child: Text(
                    'تقييماتي',
                    style: TextStyles.semiBold16.copyWith(
                      color: AppColors.kprimaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
