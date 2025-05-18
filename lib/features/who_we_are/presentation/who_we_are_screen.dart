import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/constants.dart';
import 'package:hadaer_blady/core/functions/build_app_bar_with_arrow_back_button.dart';
import 'package:hadaer_blady/core/functions/show_snack_bar.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:url_launcher/url_launcher.dart';

class WhoWeAreScreen extends StatelessWidget {
  const WhoWeAreScreen({super.key});
  static const String id = 'WhoWeAreScreen';
  final String phoneNumber = "+218926827172";
  final String message = "مرحبًا، أريد الاستفسار عن خدمات حضائر بلادي";
  Future<void> _openWhatsApp(BuildContext context) async {
    final String encodedMessage = Uri.encodeComponent(message);
    final String whatsappUrl =
        "https://wa.me/$phoneNumber?text=$encodedMessage";
    final Uri url = Uri.parse(whatsappUrl);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        showSnackBarMethode(
          context,
          'لا يمكن فتح واتساب، تأكد من تثبيت التطبيق',
        );
      }
    } catch (e) {
      showSnackBarMethode(context, 'حدث خطأ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kWiteColor,
      appBar: buildAppBarWithArrowBackButton(title: 'من نحن', context: context),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: khorizintalPadding),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,

            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '"حضائر بلادي" هو تطبيق مبتكر يربط بين  اصحاب حظائر الدجاج اللاحم  والتجار، مما يسهل عملية بيع وشراء الدجاج اللاحم ومستلزمات الحظائر بكل سهولة ويسر عبر التطبيق، يمكنك استكشاف العروض المتاحة، التفاوض على الأسعار، وإتمام الصفقات بأمان وسرعة. سواء كنت مربيًا أو تاجرًا، ستجد في "حضائر بلادي" أداة فعالة لتنمية أعمالك وتوسيع شبكتك التجارية.\nابدأ الآن وسهّل تجارتك مع حضائر بلادي!',
                textAlign: TextAlign.center,
                style: TextStyles.semiBold16,
              ),
              const SizedBox(height: 20),
              Text(
                'تواصلوا معنا عبر واتساب:',
                style: TextStyles.semiBold19.copyWith(
                  color: AppColors.kBlackColor,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _openWhatsApp(context),
                child: Row(
                  spacing: 8,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.chat, color: Colors.green),
                    Text(
                      phoneNumber,
                      style: TextStyles.semiBold16.copyWith(
                        color: Colors.green,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
