import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class BiographyScreen extends StatelessWidget {
  const BiographyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryEmerald = AppTheme.primary;
    const accentGold = AppTheme.accent;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'سوانح حیات و علمی خدمات',
            style: TextStyle(
              color: primaryEmerald,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: primaryEmerald),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Header Card with Sheikh Portrait
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryLight],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: primaryEmerald.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                        border: Border.all(color: accentGold, width: 3.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: SizedBox(
                          width: 120,
                          height: 120,
                          child: Image.asset(
                            'assets/images/banners/sheikh_portrait.png',
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => Container(
                                  color: Colors.white12,
                                  child: const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.white,
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'حضرت مولانا شیخ عبدالسلام الرستمی',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'رحمہ اللہ تعالیٰ (۱۹۳۸ء - ۲۰۱۴ء)',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFFF3E2C4),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accentGold.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'استاذ العلماء ومفسر قرآن کریم',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Biography Timeline Sections
              _buildSection(
                icon: Icons.child_care_rounded,
                title: 'ولادت اور خاندانی پس منظر',
                content:
                    'حضرت شیخ مولانا عبدالسلام الرستمی رحمہ اللہ کی ولادت ۱۹۳۸ء میں خیبر پختونخوا کے تاریخی اور علمی قصبے "رستم" (ضلع مردان) کے ایک معزز اور دینی گھرانے میں ہوئی۔ آپ کے والد محترم ایک متقی اور دیندار انسان تھے جنہوں نے بچپن ہی سے آپ کی تربیت اسلامی خطوط پر فرمائی۔',
              ),

              _buildSection(
                icon: Icons.school_rounded,
                title: 'تعلیم و تربیت اور اساتذہ کرام',
                content:
                    'ابتدائی تعلیم اپنے آبائی علاقے کے کبار علماء سے حاصل کی، جس کے بعد آپ نے دینی علوم کے حصول کے لیے اکابر اہل علم کا رخ کیا۔ آپ نے علوم قرآن، حدیث، فقہ، اصول، عربی ادب اور منطق وفلسفہ کی اعلیٰ ترین کتب کا گہرا مطالعہ کیا۔ آپ کے اساتذہ میں اپنے دور کے جید اور نامور شیوخ الحدیث والتفسیر شامل تھے۔',
              ),

              _buildSection(
                icon: Icons.account_balance_rounded,
                title: 'جامعہ تعلیم القرآن رستم کا قیام',
                content:
                    'فراغت کے بعد آپ نے دعوت و تدریس کو اپنا اوڑھنا بچھونا بنایا اور مردان میں "جامعہ تعلیم القرآن والسنۃ" کی بنیاد رکھی۔ یہ ادارہ نہ صرف پاکستان بلکہ افغانستان اور دنیا بھر کے طلبہ کے لیے علوم قرآنی اور تفسیری دروس کا عظیم الشان مرکز بن گیا۔ ہزاروں تشنگانِ علم نے آپ سے قرآن و حدیث کا فیض حاصل کیا۔',
              ),

              _buildSection(
                icon: Icons.menu_book_rounded,
                title: 'شاہکار تصنیف: تفسیر احسن الکلام',
                content:
                    'شیخ رحمہ اللہ کی علمی زندگی کا سب سے درخشندہ کارنامہ قرآن مجید کی مفصل و مدلل تفسیر "احسن الکلام" ہے۔ یہ تفسیر قرآنی آیات کی تشریح، توحید خالص کے دلائل، سنت نبوی کی اہمیت اور باطل نظریات کے رد پر مشتمل ایک نادر علمی خزانہ ہے جس سے امت مسلمہ آج بھی رہنمائی حاصل کر رہی ہے۔',
              ),

              _buildSection(
                icon: Icons.auto_stories_rounded,
                title: 'دیگر اہم علمی تصانیف',
                content:
                    'تفسیر کے علاوہ آپ نے عقیدہ، فقہ اور حدیث پر گرانقدر کتب تصنیف فرمائیں، جن میں "التوحید فی القرآن"، "البنیان المرصوص"، "احکام الصلاۃ فی ضوء السنۃ"، "تبیین القرآن"، "رد البدعات والمنکرات"، اور خطبات کے متعدد مجموعے شامل ہیں جو اس ایپ میں بھی دستیاب ہیں۔',
              ),

              _buildSection(
                icon: Icons.mic_external_on_rounded,
                title: 'دعوت و تدریس اور اصلاحی خدمات',
                content:
                    'شیخ صاحب بیک وقت مفسر، خطیب، فقیہ اور مصلح تھے۔ آپ کے سالانہ دورہ ہائے تفسیر میں ہر سال ہزاروں علماء اور طلبہ دور دراز سے شرکت کرتے۔ آپ کی دعوت کا بنیادی محور "خالص توحید اور اتباع سنت" تھا۔ آپ نے شرک، بدعات اور رسوماتِ جاہلیت کے خاتمے کے لیے انتھک محنت فرمائی۔',
              ),

              _buildSection(
                icon: Icons.nightlight_round,
                title: 'وفات اور علمی میراث',
                content:
                    'تقریباً نصف صدی تک خدمت دین، تدریس قرآن اور اشاعت توحید میں گزارنے کے بعد نومبر ۲۰۱۴ء میں یہ آفتابِ علم غروب ہو گیا۔ آپ کے جنازے میں لاکھوں عقیدت مندوں، علماء اور شاگردوں نے شرکت کی۔ آپ اپنے پیچھے ہزاروں علماء اور بیش قیمت کتب کا ورثہ چھوڑ گئے۔',
              ),

              const SizedBox(height: 10),

              // Supplication Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: accentGold.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentGold.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.favorite_rounded,
                      color: accentGold,
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'رَحِمَهُ اللَّهُ رَحْمَةً وَاسِعَةً وَأَسْكَنَهُ فَسِيحَ جَنَّاتِهِ',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: primaryEmerald,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'اے اللہ! شیخ مرحوم کو اپنی رحمت اور مغفرت کے سایہ میں جگہ عطا فرما، ان کی قبر کو نور سے بھر دے، اور ان کے علمی آثار و تصانیف کو تا قیامت امت مسلمہ کے لیے مشعل راہ اور ان کے لیے صدقہ جاریہ بنا۔ آمین یا رب العالمین۔',
                      style: TextStyle(
                        fontSize: 14.5,
                        height: 1.85,
                        color: Color(0xFF1E2522),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    const primaryEmerald = AppTheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryEmerald.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: primaryEmerald, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E2522),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.85,
              color: Colors.black.withValues(alpha: 0.75),
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}
