import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../data/biography_content.dart';

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
                      BiographyContent.title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'وفات: 17 نومبر 2014ء، 23 محرم 1436ھ',
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
                        'شیخ القرآن والحدیث',
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

              // Biography supplied by the app's publisher.
              _buildSection(
                icon: Icons.family_restroom_rounded,
                title: 'تعارف و خاندانی پس منظر',
                content: BiographyContent.family,
              ),

              _buildSection(
                icon: Icons.school_rounded,
                title: 'تعلیم و تربیت اور اساتذہ کرام',
                content: BiographyContent.education,
              ),

              _buildSection(
                icon: Icons.account_balance_rounded,
                title: 'درسِ قرآن اور تدریسی خدمات',
                content: BiographyContent.teaching,
              ),

              _buildSection(
                icon: Icons.mosque_rounded,
                title: 'پشاور میں تدریس اور دعوت',
                content: BiographyContent.peshawar,
              ),

              _buildSection(
                icon: Icons.menu_book_rounded,
                title: 'پشتو تفسیر اور علمی مقام',
                content: BiographyContent.pashtoTafsir,
              ),

              _buildSection(
                icon: Icons.auto_stories_rounded,
                title: 'معروف تصانیف',
                content: BiographyContent.books,
              ),

              _buildSection(
                icon: Icons.edit_note_rounded,
                title: 'قید و بند میں علمی خدمات',
                content: BiographyContent.imprisonment,
              ),

              _buildSection(
                icon: Icons.campaign_rounded,
                title: 'دعوتی خدمات',
                content: BiographyContent.outreach,
              ),

              _buildSection(
                icon: Icons.library_books_rounded,
                title: 'علمی میراث',
                content: BiographyContent.legacy,
              ),

              _buildSection(
                icon: Icons.nightlight_round,
                title: 'وفات اور دعا',
                content: BiographyContent.passing,
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
