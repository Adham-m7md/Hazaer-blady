import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/features/home/presentation/widgets/custom_offers_list/custom_offer.dart';

class OfferModel {
  final String id;
  final String title;
  final String description;
  final String buttonText;
  final String? imageUrl;
  final Color? backgroundColor;
  final Color? overlayColor;

  OfferModel({
    required this.id,
    required this.title,
    required this.description,
    required this.buttonText,
    this.imageUrl,
    this.backgroundColor,
    this.overlayColor,
  });

  factory OfferModel.fromProduct(CustomProduct customProduct, int index) {
    final List<Map<String, Color>> colorPairs = [
      {'background': Colors.green.shade50, 'overlay': Colors.green.shade700},
      {'background': Colors.orange.shade50, 'overlay': Colors.orange.shade700},
      {'background': Colors.blue.shade50, 'overlay': Colors.blue.shade700},
      {'background': Colors.red.shade50, 'overlay': Colors.red.shade700},
    ];
    final colorIndex = index % colorPairs.length;
    final colors = colorPairs[colorIndex];

    return OfferModel(
      id: customProduct.id,
      title: customProduct.title,
      description: customProduct.description,
      buttonText: 'تسوق الآن',
      imageUrl: customProduct.imageUrl,
      backgroundColor: colors['background'],
      overlayColor: colors['overlay'],
    );
  }
}

class OffersCarousel extends StatefulWidget {
  final List<CustomProduct> products;

  const OffersCarousel({super.key, required this.products});

  @override
  State<OffersCarousel> createState() => _OffersCarouselState();
}

class _OffersCarouselState extends State<OffersCarousel>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  List<OfferModel> _offers = [];

  @override
  void initState() {
    super.initState();
    _offers =
        widget.products.asMap().entries.map((entry) {
          final index = entry.key;
          final product = entry.value;
          log(
            'Mapping offer $index: ${product.title}, ID: ${product.id}, Image: ${product.imageUrl}',
          );
          return OfferModel.fromProduct(product, index);
        }).toList();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _startTimer(_offers.length);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _startTimer(int itemCount) {
    _timer?.cancel();
    if (itemCount > 0) {
      _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
        if (_pageController.hasClients && mounted) {
          int nextPage = (_currentPage + 1) % itemCount;
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_offers.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد عروض متاحة حاليًا',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _offers.length,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
                _animationController.reset();
                _animationController.forward();
              });
            },
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: index == _currentPage ? _scaleAnimation.value : 0.9,
                    child: Opacity(
                      opacity: index == _currentPage ? 1.0 : 0.7,
                      child: child,
                    ),
                  );
                },
                child: CustomOffer(
                  key: ValueKey(_offers[index].id),
                  offer: _offers[index],
                  product: widget.products[index],
                  onButtonPressed: () {
                    log('Button pressed for offer: ${_offers[index].title}');
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _offers.length,
            (index) => GestureDetector(
              onTap: () {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color:
                      _currentPage == index
                          ? AppColors.kprimaryColor
                          : AppColors.kprimaryColor.withOpacity(0.3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CustomProduct {
  final String id;
  final String title;
  final String description;
  final double price;
  final String displayLocation;
  final String imageUrl;
  final String farmerId;
  final DateTime createdAt;

  CustomProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.displayLocation,
    required this.imageUrl,
    required this.farmerId,
    required this.createdAt,
  });

  factory CustomProduct.fromMap(Map<String, dynamic> map, String id) {
    log('Mapping CustomProduct from Firestore: $map');
    return CustomProduct(
      id: id,
      title: map['title']?.toString() ?? 'غير معروف',
      description: map['description']?.toString() ?? '',
      price:
          (map['price'] is num)
              ? (map['price'] as num).toDouble()
              : double.tryParse(map['price']?.toString() ?? '0') ?? 0.0,
      displayLocation: map['display_location']?.toString() ?? 'غير محدد',
      imageUrl: map['image_url']?.toString() ?? '',
      farmerId: map['farmer_id']?.toString() ?? '',
      createdAt:
          (map['created_at'] is Timestamp)
              ? (map['created_at'] as Timestamp).toDate()
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'display_location': displayLocation,
      'image_url': imageUrl,
      'farmer_id': farmerId,
      'created_at': createdAt,
    };
  }

  @override
  String toString() {
    return 'CustomProduct(id: $id, title: $title, price: $price, imageUrl: $imageUrl)';
  }
}
