import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/biography_content.dart';
import 'screens/books_screen.dart';
import 'screens/audio_screen.dart';
import 'screens/biography_screen.dart';
import 'screens/pdf_viewer_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'utils/pdf_cache_manager.dart';
import 'utils/app_launcher_helper.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'constants/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.shaikhrustami.maktabat.audio',
      androidNotificationChannelName: 'صدائے شیخ عبدالسلام',
      androidNotificationIcon: 'drawable/ic_stat_audio',
      notificationColor: AppTheme.primary,
      androidNotificationOngoing: false,
      androidShowNotificationBadge: false,
      preloadArtwork: true,
    );
  } catch (_) {}
  runApp(const MaktabatApp());
}

class MaktabatApp extends StatelessWidget {
  const MaktabatApp({super.key});

  // Imperial Burgundy & Burnished Gold Theme Tokens
  static const Color primaryBurgundy = AppTheme.primary;
  static const Color primaryEmerald = AppTheme.primary; // backward-compat alias
  static const Color accentGold = AppTheme.accent;
  static const Color lightBg = AppTheme.background;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مکتبہ شیخ عبدالسلام رستمی',
      theme: AppTheme.lightTheme,
      home: const OpeningScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class OpeningScreen extends StatefulWidget {
  const OpeningScreen({super.key});

  @override
  State<OpeningScreen> createState() => _OpeningScreenState();
}

class _OpeningScreenState extends State<OpeningScreen> {
  Timer? _openingTimer;
  bool _showHome = false;

  @override
  void initState() {
    super.initState();
    _openingTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _showHome = true);
    });
  }

  @override
  void dispose() {
    _openingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child:
          _showHome
              ? const HomePage(key: ValueKey('home'))
              : Scaffold(
                key: const ValueKey('opening'),
                backgroundColor: AppTheme.primary,
                body: SizedBox.expand(
                  child: Image.asset(
                    'assets/images/banners/app-logo-burgundy.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _remindersChannel = MethodChannel(
    'com.shaikhrustami.maktabat/reminders',
  );
  String? _lastReadBook;
  int? _lastReadPage;
  String? _lastReadLocalPath;

  @override
  void initState() {
    super.initState();
    _checkLastRead();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _initializeReminders();
    }
  }

  Future<void> _initializeReminders() async {
    try {
      await _remindersChannel.invokeMethod<bool>('initialize');
    } on PlatformException catch (_) {
      // Reminders are optional; the rest of the app remains available.
    } on MissingPluginException catch (_) {
      // Other platforms do not have the Android reminder channel.
    }
  }

  Future<void> _checkLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    final lastBook = prefs.getString('last_opened_book');
    if (lastBook != null && lastBook.isNotEmpty) {
      final lastPage = prefs.getInt('last_page_$lastBook') ?? 0;
      final cachedPath = await PDFCacheManager.getCachedPDF(lastBook);
      if (cachedPath != null && mounted) {
        setState(() {
          _lastReadBook = lastBook;
          _lastReadPage = lastPage;
          _lastReadLocalPath = cachedPath;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'مکتبہ شیخ عبدالسلام رستمی',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: MaktabatApp.primaryEmerald,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Hero Curved Islamic Gradient Banner
                _buildHeroBanner(),

                const SizedBox(height: 18),

                // Continue Reading Widget (if available)
                if (_lastReadBook != null && _lastReadLocalPath != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 4.0,
                    ),
                    child: _buildContinueReadingCard(),
                  ),

                // Welcome Card
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 8.0,
                  ),
                  child: _buildWelcomeCard(),
                ),

                const SizedBox(height: 14),

                // Section Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'علمی ذخیرہ',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: MaktabatApp.primaryEmerald,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: MaktabatApp.accentGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'کتب و بیانات',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: MaktabatApp.accentGold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Navigation Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      _buildNavigationCard(
                        title: 'کتابیں و مؤلفات (PDF)',
                        subtitle: 'شیخ کی کتب اور متعلقہ علمی مواد',
                        badgeText: '${BooksScreen.booksCount} کتب',
                        icon: Icons.menu_book_rounded,
                        cardColor: MaktabatApp.primaryEmerald,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BooksScreen(),
                            ),
                          ).then((_) => _checkLastRead());
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildNavigationCard(
                        title: 'آڈیو لیکچرز و تقاریر',
                        subtitle: 'قرآنی دروس، تفسیری بیانات اور خطبات',
                        badgeText: 'صوتی دروس',
                        icon: Icons.headphones_rounded,
                        cardColor: const Color(0xFF4C1521),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AudioScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildNavigationCard(
                        title: 'شیخ کا تعارف و سوانح',
                        subtitle: 'حالات زندگی، تدریسی خدمات اور تصانیف',
                        badgeText: 'سوانح حیات',
                        icon: Icons.person_pin_rounded,
                        cardColor: MaktabatApp.accentGold,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BiographyScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Contact & Share Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: _buildContactCard(),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Row(
          children: [
            // Sheikh's Portrait with Gold Ring
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
                border: Border.all(color: MaktabatApp.accentGold, width: 3.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: SizedBox(
                  width: 130,
                  height: 130,
                  child: Image.asset(
                    'assets/images/banners/sheikh_portrait.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.white12,
                        child: const Icon(
                          Icons.person,
                          size: 65,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Sheikh's Titles & Salutation
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: MaktabatApp.accentGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: MaktabatApp.accentGold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Text(
                      'شیخ القرآن والحدیث',
                      style: TextStyle(
                        color: Color(0xFFF3E2C4),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'مولانا سید عبدالسلام رستمی',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: MaktabatApp.accentGold,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'رحمہ اللہ (وفات: 17 نومبر 2014ء)',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueReadingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: MaktabatApp.accentGold.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: MaktabatApp.accentGold.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: MaktabatApp.primaryEmerald.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: MaktabatApp.primaryEmerald,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'جہاں سے چھوڑا تھا (مطالعہ جاری رکھیں)',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: MaktabatApp.accentGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _lastReadBook ?? '',
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E2522),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'صفحہ نمبر: ${(_lastReadPage ?? 0) + 1}',
                  style: const TextStyle(fontSize: 12.5, color: Colors.black54),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => PDFViewerScreen(
                        title: _lastReadBook!,
                        localPath: _lastReadLocalPath!,
                      ),
                ),
              ).then((_) => _checkLastRead());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MaktabatApp.primaryEmerald,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text(
              'پڑھیں',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: MaktabatApp.primaryEmerald,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            BiographyContent.legacy,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.85,
              color: Colors.black.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationCard({
    required String title,
    required String subtitle,
    required String badgeText,
    required IconData icon,
    required Color cardColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: cardColor.withValues(alpha: 0.08),
        highlightColor: cardColor.withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: cardColor.withValues(alpha: 0.12),
                ),
                child: Icon(icon, color: cardColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E2522),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: cardColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: cardColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.grey.shade400,
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'شیئرنگ و رابطہ',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: MaktabatApp.primaryEmerald,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'علمی صدقہ جاریہ میں حصہ دار بنیں اور ایپ کو دوسروں تک پہنچائیں',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.black.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: Icons.share_rounded,
                label: 'شیئر کریں',
                color: MaktabatApp.primaryEmerald,
                onTap: _shareApp,
              ),
              _buildActionButton(
                icon: Icons.email_rounded,
                label: 'رابطہ و تجاویز',
                color: const Color(0xFFC5A059),
                onTap: _showContactDialog,
              ),
              _buildActionButton(
                icon: Icons.star_rate_rounded,
                label: 'دعائے خیر',
                color: const Color(0xFFB8860B),
                onTap: _showDuaDialog,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyScreen(),
                  ),
                ),
            icon: const Icon(Icons.privacy_tip_outlined),
            label: const Text('رازداری کی پالیسی'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E2522),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareApp() async {
    const message =
        'مکتبہ شیخ عبدالسلام رستمی\nشیخ عبدالسلام رستمی کی کتب اور آڈیو بیانات اس ایپ میں پڑھیں اور سنیں:';
    final opened = await AppLauncherHelper.shareApp(message);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('شیئرنگ اس ڈیوائس پر دستیاب نہیں ہے')),
      );
    }
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder:
          (context) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.contact_mail_rounded,
                    color: MaktabatApp.accentGold,
                  ),
                  SizedBox(width: 8),
                  Text('رابطہ و تجاویز'),
                ],
              ),
              content: const Text(
                'اگر آپ کو کسی کتاب میں غلطی نظر آئے یا کوئی مفید تجویز دینا چاہیں تو ہم سے رابطہ فرما سکتے ہیں۔\n\nرابطہ ای میل:\nMuhammadImran100@gmail.com',
                style: TextStyle(height: 1.6),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'ٹھیک ہے',
                    style: TextStyle(color: MaktabatApp.primaryEmerald),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showDuaDialog() {
    showDialog(
      context: context,
      builder:
          (context) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Row(
                children: [
                  Icon(Icons.favorite, color: Colors.amber),
                  SizedBox(width: 8),
                  Text('دعائے مغفرت'),
                ],
              ),
              content: const Text(
                'رَبِّ اغْفِرْ لَهُ وَارْحَمْهُ وَأَدْخِلْهُ فِي عِبَادِكَ الصَّالِحِينَ\n\nاے اللہ! شیخ محترم کو جنت الفردوس میں اعلیٰ مقام عطا فرما اور ان کی تصانیف کو امت کے لیے باعث ہدایت بنا۔ آمین',
                style: TextStyle(height: 1.8, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'آمین',
                    style: TextStyle(
                      color: MaktabatApp.primaryEmerald,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
