import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/functions/build_app_bar_with_arrow_back_button.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});
  static const String id = 'PrivacyPolicyScreen';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBarWithArrowBackButton(
        title: 'سياسة الخصوصية',
        context: context,
      ),
      backgroundColor: AppColors.kWiteColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          spacing: 20,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSection(
              title: 'نبذة عنا',
              content: _buildDefinitionsContent(),
            ),

            _buildSection(
              title: 'أنواع البيانات المجمعة',
              content: _buildDataTypesContent(),
            ),

            _buildSection(
              title: 'استخدام بياناتك الشخصية',
              content: _buildDataUsageContent(),
            ),

            _buildSection(
              title: 'بيانات الموقع الجغرافي',
              content: _buildLocationDataContent(),
            ),

            _buildImportantNotice(),

            _buildSection(
              title: 'مشاركة بياناتك الشخصية',
              content: _buildDataSharingContent(),
            ),

            _buildSection(
              title: 'الاحتفاظ ببياناتك الشخصية',
              content: _buildDataRetentionContent(),
            ),

            _buildSection(
              title: 'حذف بياناتك الشخصية',
              content: _buildDataDeletionContent(),
            ),

            _buildSection(
              title: 'أمان بياناتك الشخصية',
              content: _buildSecurityContent(),
            ),

            _buildSection(
              title: 'خصوصية الأطفال',
              content: _buildChildrenPrivacyContent(),
            ),

            _buildSection(
              title: 'التغييرات على سياسة الخصوصية',
              content: _buildChangesContent(),
            ),

            _buildContactSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.kprimaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.kprimaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'سياسة الخصوصية',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.kprimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'آخر تحديث: 01 يونيو 2025',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'تصف سياسة الخصوصية هذه سياساتنا وإجراءاتنا بشأن جمع واستخدام والكشف عن معلوماتك عند استخدام تطبيق حظائر بلادي.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget content}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.kprimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildDefinitionsContent() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'نحن تطبيق حظائر بلادي \n تطبيق خاص بتجارة الدواجن ومستلزماتها\n في الوطن الليبي.',
              textAlign: TextAlign.center,
              style: TextStyles.semiBold16,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDataTypesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'قد تشمل المعلومات الشخصية:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _buildBulletPoint('عنوان البريد الإلكتروني'),
        _buildBulletPoint('الاسم الأول والأخير'),
        _buildBulletPoint('رقم الهاتف'),
        _buildBulletPoint('العنوان والمدينة في ليبيا'),
        _buildBulletPoint('الصورة الشخصية'),
        _buildBulletPoint('نوع المستخدم (تاجر أو صاحب مزرعة)'),
        _buildBulletPoint('بيانات الاستخدام'),
      ],
    );
  }

  Widget _buildLocationDataContent() {
    return Text(
      'نجمع معلومات حول موقعك الجغرافي بإذنك المسبق من أجل عرض العروض والمنتجات الأقرب إليك، وربط التجار بأصحاب المزارع في نفس المنطقة. يمكنك تمكين أو تعطيل الوصول إلى هذه المعلومات في أي وقت من خلال إعدادات جهازك.',
      style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
    );
  }

  Widget _buildDataUsageContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'قد نستخدم البيانات الشخصية للأغراض التالية:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _buildBulletPoint('لتوفير والحفاظ على خدمتنا'),
        _buildBulletPoint('لإدارة حسابك'),
        _buildBulletPoint('لربط التجار بأصحاب المزارع في ليبيا'),
        _buildBulletPoint('لعرض المنتجات والعروض حسب الموقع'),
        _buildBulletPoint('للتواصل معك وإرسال الإشعارات'),
        _buildBulletPoint('لإدارة طلباتك'),
        _buildBulletPoint('لتحليل البيانات وتحسين الخدمة'),
      ],
    );
  }

  Widget _buildImportantNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'إشعار مهم',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'التطبيق يسهل التواصل بين المستخدمين عبر مشاركة أرقام الهاتف. عمليات الشراء والبيع تتم خارج التطبيق مباشرة بين الأطراف. نحن غير مسؤولين عن المعاملات التي تتم خارج نطاق التطبيق.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange[800],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSharingContent() {
    return Text(
      'نحن ملتزمون بحماية خصوصيتك. لن يتم مشاركة بياناتك الشخصية مع أي جهة خارجية دون موافقتك الصريحة، باستثناء ما يقتضيه القانون أو لتقديم الخدمات الأساسية للتطبيق، مثل تحليل استخدام الخدمة من خلال مقدمي خدمات موثوقين يلتزمون بمعايير الخصوصية العالية.',
      style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
      textAlign: TextAlign.right,
    );
  }

  Widget _buildDataRetentionContent() {
    return Text(
      'ستحتفظ الشركة ببياناتك الشخصية فقط طوال الفترة اللازمة للأغراض المحددة في سياسة الخصوصية هذه. سنحتفظ ببياناتك بالقدر اللازم للامتثال لالتزاماتنا القانونية وحل النزاعات.',
      style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
    );
  }

  Widget _buildDataDeletionContent() {
    return Text(
      'لديك الحق في حذف أو طلب مساعدتنا في حذف البيانات الشخصية التي جمعناها عنك. يمكنك تحديث أو تعديل أو حذف معلوماتك في أي وقت من خلال إعدادات الحساب في التطبيق.',
      style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
    );
  }

  Widget _buildSecurityContent() {
    return Text(
      'أمان بياناتك الشخصية مهم بالنسبة لنا. بينما نسعى لاستخدام وسائل مقبولة تجارياً لحماية بياناتك الشخصية، لا يمكننا ضمان أمانها المطلق حيث أنه لا توجد طريقة نقل عبر الإنترنت آمنة بنسبة 100%.',
      style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
    );
  }

  Widget _buildChildrenPrivacyContent() {
    return Text(
      'خدمتنا لا تتوجه لأي شخص تحت سن 13 عاماً. نحن لا نجمع عن قصد معلومات شخصية من أي شخص تحت سن 13 عاماً.',
      style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
    );
  }

  Widget _buildChangesContent() {
    return Text(
      'قد نحدث سياسة الخصوصية الخاصة بنا من وقت لآخر. سنخطرك بأي تغييرات عن طريق نشر سياسة الخصوصية الجديدة وعبر البريد الإلكتروني و/أو إشعار بارز في خدمتنا.',
      style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.kprimaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.kprimaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'اتصل بنا',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.kprimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.phone, color: AppColors.kprimaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'رقم الهاتف: 00218926827172',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'إذا كانت لديك أي أسئلة حول سياسة الخصوصية هذه، يمكنك الاتصال بنا على الرقم أعلاه.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 8),
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: AppColors.kprimaryColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
