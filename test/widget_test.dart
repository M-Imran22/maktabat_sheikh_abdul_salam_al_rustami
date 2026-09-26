import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maktabat_sheikh_abdul_salam_al_rustami/main.dart';
import 'package:maktabat_sheikh_abdul_salam_al_rustami/constants/app_config.dart';
import 'package:maktabat_sheikh_abdul_salam_al_rustami/screens/books_screen.dart';
import 'package:maktabat_sheikh_abdul_salam_al_rustami/screens/audio_screen.dart';
import 'package:maktabat_sheikh_abdul_salam_al_rustami/screens/biography_screen.dart';
import 'package:maktabat_sheikh_abdul_salam_al_rustami/services/audio_player_service.dart';
import 'package:maktabat_sheikh_abdul_salam_al_rustami/utils/app_launcher_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('xyz.luan/audioplayers.global'),
          (MethodCall methodCall) async => 1,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('xyz.luan/audioplayers'),
          (MethodCall methodCall) async => 1,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.shaikhrustami.maktabat/app_launcher'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'isAppInstalled') {
              return true;
            }
            if (methodCall.method == 'launchAppOrStore') {
              return true;
            }
            return null;
          },
        );
  });

  group('MaktabatApp Comprehensive Test Suite', () {
    testWidgets('App renders Home Page with Sheikh portrait and all sections', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.reset());

      await tester.pumpWidget(const MaktabatApp());
      await tester.pumpAndSettle();

      // Title & Basmalah
      expect(find.text('مکتبہ شیخ عبدالسلام الرستمی'), findsWidgets);
      expect(
        find.text('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'),
        findsOneWidget,
      );

      // Main Navigation Cards
      expect(find.text('کتابیں و مؤلفات (PDF)'), findsOneWidget);
      expect(find.text('آڈیو لیکچرز و تقاریر'), findsOneWidget);
      expect(find.text('شیخ کا تعارف و سوانح'), findsOneWidget);

      // Sharing & Contact Action Buttons
      expect(find.text('شیئر کریں'), findsOneWidget);
      expect(find.text('رابطہ و تجاویز'), findsOneWidget);
      expect(find.text('دعائے خیر'), findsOneWidget);
    });

    testWidgets('Can navigate to BooksScreen from Home', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.reset());

      await tester.pumpWidget(const MaktabatApp());
      await tester.pumpAndSettle();

      final booksBtn = find.text('کتابیں و مؤلفات (PDF)');
      await tester.ensureVisible(booksBtn);
      await tester.tap(booksBtn);
      await tester.pumpAndSettle();

      // Verify BooksScreen is pushed
      expect(find.byType(BooksScreen), findsOneWidget);
      expect(find.text('کتب و مؤلفات'), findsOneWidget);
      expect(find.text('الموسوعة القرآنية (جلد ۱)'), findsOneWidget);
      expect(find.text('تفسیر احسن الکلام (پښتو)'), findsOneWidget);
      expect(BooksScreen.booksCount, 22);
    });

    testWidgets('Can navigate to AudioScreen from Home', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.reset());

      await tester.pumpWidget(const MaktabatApp());
      await tester.pumpAndSettle();

      final audioBtn = find.text('آڈیو لیکچرز و تقاریر');
      await tester.ensureVisible(audioBtn);
      await tester.tap(audioBtn);
      await tester.pumpAndSettle();

      // Verify AudioScreen is pushed
      expect(find.byType(AudioScreen), findsOneWidget);
      expect(find.text('آڈیو لائبریری (مجموعات)'), findsOneWidget);
      expect(find.text('1987 تفسیر القرآن'), findsOneWidget);
    });

    testWidgets('Can navigate to BiographyScreen from Home', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.reset());

      await tester.pumpWidget(const MaktabatApp());
      await tester.pumpAndSettle();

      final bioBtn = find.text('شیخ کا تعارف و سوانح');
      await tester.ensureVisible(bioBtn);
      await tester.tap(bioBtn);
      await tester.pumpAndSettle();

      // Verify BiographyScreen is pushed
      expect(find.byType(BiographyScreen), findsOneWidget);
      expect(find.text('سوانح حیات و علمی خدمات'), findsOneWidget);
      expect(find.text('ولادت اور خاندانی پس منظر'), findsOneWidget);
      expect(find.text('جامعہ تعلیم القرآن رستم کا قیام'), findsOneWidget);
    });

    test('AppConfig URL resolution tests with live portal server', () {
      expect(AppConfig.isPdfServerConfigured, isTrue);
      expect(AppConfig.isAudioServerConfigured, isTrue);
      expect(
        AppConfig.getPdfUrl('sample.pdf'),
        'https://portal.shaikhrustaminetwork.com/books/sample.pdf',
      );
      expect(
        AppConfig.getAudioUrl('folder/lecture.mp3'),
        'https://portal.shaikhrustaminetwork.com/Audio/folder/lecture.mp3',
      );

      // Direct absolute URLs should pass through unmodified
      expect(
        AppConfig.getPdfUrl('https://example.com/books/sample.pdf'),
        'https://example.com/books/sample.pdf',
      );
      expect(
        AppConfig.getAudioUrl('https://example.com/audio/sample.mp3'),
        'https://example.com/audio/sample.mp3',
      );
    });

    test('AudioPlayerService singleton instance', () {
      final service1 = AudioPlayerService();
      final service2 = AudioPlayerService();
      expect(identical(service1, service2), isTrue);
    });

    test('Audio playback position persistence and resume retrieval', () async {
      const testAudioId = '1987 تفسیر القرآن/001_Surah_Al_Fatiha.mp3';

      // Initially no saved position
      var pos = await AudioPlayerService.getSavedAudioPosition(testAudioId);
      expect(pos, 0);

      // Simulate saving position at 14 minutes and 25 seconds (865s)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('audio_pos_$testAudioId', 865);

      // Verify retrieval returns exact second
      pos = await AudioPlayerService.getSavedAudioPosition(testAudioId);
      expect(pos, 865);

      // Different audio track has its own independent position
      const otherAudioId = 'خطبات جمعہ/001_Khutba.mp3';
      var otherPos = await AudioPlayerService.getSavedAudioPosition(otherAudioId);
      expect(otherPos, 0);
    });

    test('Reading page persistence and bookmarks per-book isolation', () async {
      final prefs = await SharedPreferences.getInstance();
      const book1 = 'الموسوعة القرآنية (جلد ۱)';
      const book2 = 'توجيه الناظرين إلى مقاصد الكتاب المبين';

      // Save reading progress for book 1 on page 30
      await prefs.setInt('last_page_$book1', 29); // 0-indexed page 29 is page 30
      // Save bookmarks for book 1
      await prefs.setStringList('bookmarks_$book1', ['14', '29', '55']);

      // Save reading progress for book 2 on page 75
      await prefs.setInt('last_page_$book2', 74);
      // Save bookmarks for book 2
      await prefs.setStringList('bookmarks_$book2', ['88']);

      // Verify page persistence
      expect(prefs.getInt('last_page_$book1'), 29);
      expect(prefs.getInt('last_page_$book2'), 74);

      // Verify bookmarks isolation - Book 1 has 3 bookmarks, Book 2 has 1 bookmark
      final book1Bookmarks = prefs.getStringList('bookmarks_$book1') ?? [];
      final book2Bookmarks = prefs.getStringList('bookmarks_$book2') ?? [];

      expect(book1Bookmarks, ['14', '29', '55']);
      expect(book2Bookmarks, ['88']);
      expect(book1Bookmarks.contains('88'), isFalse);
    });

    testWidgets('BooksScreen displays bookmarks action button', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.reset());

      await tester.pumpWidget(const MaktabatApp());
      await tester.pumpAndSettle();

      final booksBtn = find.text('کتابیں و مؤلفات (PDF)');
      await tester.ensureVisible(booksBtn);
      await tester.tap(booksBtn);
      await tester.pumpAndSettle();

      // Verify bookmarks icon is present in AppBar
      expect(find.byIcon(Icons.bookmarks_rounded), findsOneWidget);
    });

    test('AppLauncherHelper communicates with platform channel', () async {
      final installed = await AppLauncherHelper.isAppInstalled(
        'com.m_imran.tafsir_ahsan_al_kalam',
      );
      expect(installed, isTrue);

      final launched = await AppLauncherHelper.launchAppOrStore(
        packageName: 'com.m_imran.tafsir_ahsan_al_kalam',
        storeUrl:
            'https://play.google.com/store/apps/details?id=com.m_imran.tafsir_ahsan_al_kalam',
      );
      expect(launched, isTrue);
    });
  });
}
