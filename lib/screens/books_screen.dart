import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'pdf_viewer_screen.dart';
import '../utils/pdf_cache_manager.dart';
import '../widgets/search_delegate.dart';
import '../services/download_service.dart';
import '../constants/app_config.dart';
import '../constants/app_theme.dart';
import '../utils/app_launcher_helper.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  static int get booksCount => _BooksScreenState._sampleBooks.length;

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  final DownloadService _downloadService = DownloadService();
  final Map<String, StreamSubscription> _progressSubscriptions = {};
  final Map<String, StreamSubscription> _statusSubscriptions = {};
  final Map<String, StreamSubscription> _errorSubscriptions = {};
  final Map<String, double> _downloadProgress = {};
  final Map<String, bool> _isDownloading = {};
  int _rebuildKey = 0;

  bool _isGridView = false;
  String _selectedCategory = 'سب';

  final List<String> _categories = [
    'سب',
    'تفسیر قرآن',
    'توحید وعقیدہ',
    'فقہ واحکام',
    'خطبات ومقالات',
    'سیرت وتاریخ',
  ];

  @override
  void initState() {
    super.initState();
    _syncActiveDownloads();
  }

  void _syncActiveDownloads() {
    for (final book in _sampleBooks) {
      if (book['isApp'] == 'true') continue;
      final bookId = book['title']!;
      if (_downloadService.isDownloading(bookId)) {
        _isDownloading[bookId] = true;
        _downloadProgress[bookId] = _downloadService.getProgress(bookId);

        _progressSubscriptions[bookId] = _downloadService
            .getProgressStream(bookId)
            .listen((progress) {
              if (mounted) {
                setState(() {
                  _downloadProgress[bookId] = progress;
                });
              }
            });

        _statusSubscriptions[bookId] = _downloadService
            .getStatusStream(bookId)
            .listen((isDownloading) async {
              if (mounted) {
                setState(() {
                  _isDownloading[bookId] = isDownloading;
                  if (!isDownloading) {
                    _downloadProgress.remove(bookId);
                    _rebuildKey++;
                  }
                });
                if (!isDownloading) {
                  final isDownloaded = await PDFCacheManager.isDownloaded(bookId);
                  if (isDownloaded && mounted) {
                    _openPDF(book);
                  }
                }
              }
            });
      }
    }
  }

  @override
  void dispose() {
    for (var subscription in _progressSubscriptions.values) {
      subscription.cancel();
    }
    for (var subscription in _statusSubscriptions.values) {
      subscription.cancel();
    }
    for (var subscription in _errorSubscriptions.values) {
      subscription.cancel();
    }
    super.dispose();
  }

  List<Map<String, String>> get _filteredBooks {
    if (_selectedCategory == 'سب') return _sampleBooks;
    return _sampleBooks
        .where((b) => (b['category'] ?? '').contains(_selectedCategory))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    const primaryEmerald = AppTheme.primary;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'کتب و مؤلفات',
            style: TextStyle(
              color: primaryEmerald,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: primaryEmerald),
          actions: [
            // All Bookmarks Viewer
            IconButton(
              icon: const Icon(Icons.bookmarks_rounded, color: primaryEmerald),
              tooltip: 'محفوظ شدہ بک مارکس',
              onPressed: _showAllBookmarksModal,
            ),
            // View Switcher (List vs Grid)
            IconButton(
              icon: Icon(
                _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                color: primaryEmerald,
              ),
              tooltip: _isGridView ? 'لسٹ ویو' : 'گریڈ ویو',
              onPressed: () {
                setState(() {
                  _isGridView = !_isGridView;
                });
              },
            ),
            // Search Button
            IconButton(
              icon: const Icon(Icons.search_rounded, color: primaryEmerald),
              tooltip: 'تلاش کریں',
              onPressed: () async {
                final selectedTitle = await showSearch<String>(
                  context: context,
                  delegate: BookSearchDelegate(_sampleBooks),
                );
                if (selectedTitle != null && selectedTitle.isNotEmpty) {
                  if (!mounted) return;
                  final selectedBook = _sampleBooks.firstWhere(
                    (b) => b['title'] == selectedTitle,
                    orElse: () => {},
                  );
                  if (selectedBook.isNotEmpty) {
                    if (selectedBook['isApp'] == 'true') {
                      AppLauncherHelper.launchAppOrStore(
                        packageName:
                            selectedBook['package'] ??
                            'com.m_imran.tafsir_ahsan_al_kalam',
                        storeUrl:
                            selectedBook['storeUrl'] ??
                            'https://play.google.com/store/apps/details?id=com.m_imran.tafsir_ahsan_al_kalam',
                      );
                    } else {
                      final isDownloaded = await PDFCacheManager.isDownloaded(
                        selectedTitle,
                      );
                      if (!mounted) return;
                      if (isDownloaded) {
                        _openPDF(selectedBook);
                      } else {
                        _downloadBook(selectedBook);
                      }
                    }
                  }
                }
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Disclaimer Banner
            Container(
              width: double.infinity,
              color: primaryEmerald.withValues(alpha: 0.08),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.menu_book, color: primaryEmerald, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'کل کتب: ${_sampleBooks.length} | شیخ عبدالسلام رستمی رحمہ اللہ سے متعلق علمی مواد',
                    style: const TextStyle(
                      color: primaryEmerald,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            // Category Filter Chips
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: primaryEmerald,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? primaryEmerald : Colors.grey.shade300,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      }
                    },
                  );
                },
              ),
            ),

            // Book List or Grid
            Expanded(
              child:
                  _filteredBooks.isEmpty
                      ? const Center(
                        child: Text(
                          'اس قسم میں فی الوقت کوئی کتاب نہیں ملی',
                          style: TextStyle(fontSize: 15, color: Colors.grey),
                        ),
                      )
                      : _isGridView
                      ? GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.62,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                            ),
                        itemCount: _filteredBooks.length,
                        itemBuilder: (context, index) {
                          final book = _filteredBooks[index];
                          return _buildGridCard(book, context, index);
                        },
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredBooks.length,
                        itemBuilder: (context, index) {
                          final book = _filteredBooks[index];
                          return _buildListCard(book, context, index);
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  // --- List View Card ---
  Widget _buildListCard(
    Map<String, String> book,
    BuildContext context,
    int index,
  ) {
    final bookId = book['title']!;
    final isApp = book['isApp'] == 'true';

    if (isApp) {
      final packageName =
          book['package'] ?? 'com.m_imran.tafsir_ahsan_al_kalam';
      final storeUrl =
          book['storeUrl'] ??
          'https://play.google.com/store/apps/details?id=$packageName';

      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            AppLauncherHelper.launchAppOrStore(
              packageName: packageName,
              storeUrl: storeUrl,
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _buildBookCover(book['coverImage'], width: 95, height: 135),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book['title']!,
                        style: const TextStyle(
                          color: Color(0xFF1E2522),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildDetailChip(book['category'] ?? 'تفسیر قرآن'),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.android_rounded,
                                  size: 13,
                                  color: AppTheme.primary,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'اینڈرائیڈ ایپ',
                                  style: TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'نوعیت: اینڈرائیڈ ایپ • زبان: ${book['language'] ?? 'پشتو'}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      FutureBuilder<bool>(
                        future: AppLauncherHelper.isAppInstalled(packageName),
                        builder: (context, snapshot) {
                          final isInstalled = snapshot.data ?? false;
                          return Row(
                            children: [
                              Icon(
                                isInstalled
                                    ? Icons.open_in_new_rounded
                                    : Icons.download_rounded,
                                color:
                                    isInstalled
                                        ? Colors.green
                                        : AppTheme.primary,
                                size: 16,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isInstalled
                                    ? 'انسٹال شدہ (ایپ کھولیں)'
                                    : 'پلے اسٹور سے انسٹال کریں',
                                style: TextStyle(
                                  color:
                                      isInstalled
                                          ? Colors.green
                                          : AppTheme.primary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        },
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

    final isDownloading =
        _isDownloading[bookId] ?? _downloadService.isDownloading(bookId);

    return FutureBuilder<bool>(
      key: ValueKey('list_${bookId}_$_rebuildKey'),
      future: PDFCacheManager.isDownloaded(bookId),
      builder: (context, snapshot) {
        final isDownloaded = snapshot.data ?? false;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              if (isDownloaded && !isDownloading) {
                _openPDF(book);
              } else if (!isDownloading) {
                _downloadBook(book);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Book Cover
                  _buildBookCover(book['coverImage'], width: 95, height: 135),
                  const SizedBox(width: 16),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book['title']!,
                          style: const TextStyle(
                            color: Color(0xFF1E2522),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        _buildDetailChip(book['category'] ?? 'اسلامی کتب'),
                        const SizedBox(height: 8),
                        Text(
                          'صفحات: ${book['pages']} • زبان: ${book['language'] ?? 'اردو'}',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Status indicator
                        _buildStatusRow(bookId, isDownloading, isDownloaded),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Grid View Card ---
  Widget _buildGridCard(
    Map<String, String> book,
    BuildContext context,
    int index,
  ) {
    final bookId = book['title']!;
    final isApp = book['isApp'] == 'true';

    if (isApp) {
      final packageName =
          book['package'] ?? 'com.m_imran.tafsir_ahsan_al_kalam';
      final storeUrl =
          book['storeUrl'] ??
          'https://play.google.com/store/apps/details?id=$packageName';

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            AppLauncherHelper.launchAppOrStore(
              packageName: packageName,
              storeUrl: storeUrl,
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: Image.asset(
                          book['coverImage'] ?? '',
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => Container(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                child: const Icon(
                                  Icons.book,
                                  size: 40,
                                  color: AppTheme.primary,
                                ),
                              ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.phone_android,
                              size: 10,
                              color: Colors.white,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'ایپ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book['title']!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    FutureBuilder<bool>(
                      future: AppLauncherHelper.isAppInstalled(packageName),
                      builder: (context, snapshot) {
                        final isInstalled = snapshot.data ?? false;
                        return Row(
                          children: [
                            Icon(
                              isInstalled
                                  ? Icons.open_in_new_rounded
                                  : Icons.download_rounded,
                              color:
                                  isInstalled
                                      ? Colors.green
                                      : AppTheme.primary,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                isInstalled ? 'ایپ کھولیں' : 'ڈاؤنلوڈ ایپ',
                                style: TextStyle(
                                  color:
                                      isInstalled
                                          ? Colors.green
                                          : AppTheme.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isDownloading =
        _isDownloading[bookId] ?? _downloadService.isDownloading(bookId);

    return FutureBuilder<bool>(
      key: ValueKey('grid_${bookId}_$_rebuildKey'),
      future: PDFCacheManager.isDownloaded(bookId),
      builder: (context, snapshot) {
        final isDownloaded = snapshot.data ?? false;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              if (isDownloaded && !isDownloading) {
                _openPDF(book);
              } else if (!isDownloading) {
                _downloadBook(book);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          child: Image.asset(
                            book['coverImage'] ?? '',
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => Container(
                                  color: AppTheme.primary.withValues(alpha: 0.1),
                                  child: const Icon(
                                    Icons.book,
                                    size: 40,
                                    color: AppTheme.primary,
                                  ),
                                ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${book['pages']} ص',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book['title']!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      _buildStatusRow(
                        bookId,
                        isDownloading,
                        isDownloaded,
                        isCompact: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookCover(
    String? path, {
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          path ?? '',
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) => Container(
                color: AppTheme.primary.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.book,
                  size: 36,
                  color: AppTheme.primary,
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFC5A059).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF8C6D23),
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStatusRow(
    String bookId,
    bool isDownloading,
    bool isDownloaded, {
    bool isCompact = false,
  }) {
    if (isDownloading) {
      final progress =
          _downloadProgress[bookId] ?? _downloadService.getProgress(bookId);
      return Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              value: progress > 0 ? progress : null,
              strokeWidth: 2,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              progress > 0 ? '${(progress * 100).toInt()}%' : 'رابطہ...',
              style: const TextStyle(color: Colors.blue, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else if (isDownloaded) {
      return FutureBuilder<Map<String, dynamic>>(
        key: ValueKey('status_${bookId}_$_rebuildKey'),
        future: SharedPreferences.getInstance().then((p) {
          final lastPage = p.getInt('last_page_$bookId') ?? 0;
          final bookmarks = p.getStringList('bookmarks_$bookId') ?? [];
          return {'lastPage': lastPage, 'bookmarkCount': bookmarks.length};
        }),
        builder: (context, snap) {
          final lastPage = (snap.data?['lastPage'] as int?) ?? 0;
          final bookmarkCount = (snap.data?['bookmarkCount'] as int?) ?? 0;

          if (lastPage > 0) {
            return Row(
              children: [
                const Icon(
                  Icons.bookmark_added_rounded,
                  color: Color(0xFFC99B3B),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    isCompact
                        ? 'ص ${lastPage + 1}${bookmarkCount > 0 ? " ($bookmarkCount 🔖)" : ""}'
                        : 'مطالعہ جاری رکھیں (صفحہ ${lastPage + 1})${bookmarkCount > 0 ? " • $bookmarkCount نشانات" : ""}',
                    style: const TextStyle(
                      color: Color(0xFF8C6D23),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          }
          if (bookmarkCount > 0) {
            return Row(
              children: [
                const Icon(
                  Icons.bookmarks_rounded,
                  color: Color(0xFFC99B3B),
                  size: 15,
                ),
                const SizedBox(width: 4),
                Text(
                  '$bookmarkCount محفوظ شدہ صفحات',
                  style: const TextStyle(
                    color: Color(0xFF8C6D23),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          }
          return Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                isCompact ? 'دستیاب' : 'ڈاؤن لوڈ مکمل (مطالعہ کریں)',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        },
      );
    } else {
      return Row(
        children: [
          const Icon(
            Icons.cloud_download_outlined,
            color: Colors.black45,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            isCompact ? 'ڈاؤن لوڈ' : 'ڈاؤن لوڈ کے لیے ٹیپ کریں',
            style: const TextStyle(color: Colors.black45, fontSize: 12),
          ),
        ],
      );
    }
  }

  Future<void> _showAllBookmarksModal() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    // Collect bookmarks per book
    final List<Map<String, dynamic>> booksWithBookmarks = [];
    for (final book in _sampleBooks) {
      if (book['isApp'] == 'true') continue;
      final title = book['title']!;
      final list = prefs.getStringList('bookmarks_$title') ?? [];
      if (list.isNotEmpty) {
        final pages = list.map((e) => int.parse(e)).toList()..sort();
        booksWithBookmarks.add({
          'book': book,
          'pages': pages,
        });
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Header
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFEEEEEE)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.bookmarks_rounded,
                              color: Color(0xFF8C6D23),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'تمام محفوظ شدہ نشانات (بک مارکس)',
                                  style: TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                Text(
                                  booksWithBookmarks.isEmpty
                                      ? 'کوئی بک مارک موجود نہیں'
                                      : '${booksWithBookmarks.length} کتب میں محفوظ شدہ صفحات',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(modalContext),
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Expanded(
                      child: booksWithBookmarks.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.bookmark_outline_rounded,
                                      size: 56,
                                      color: Colors.black.withValues(alpha: 0.25),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'ابھی تک کسی کتاب میں کوئی بک مارک شامل نہیں کیا گیا',
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'مطالعہ کے دوران اوپر بک مارک کے نشان پر کلک کر کے کسی بھی صفحہ کو محفوظ کریں۔',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: Colors.black45,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: booksWithBookmarks.length,
                              itemBuilder: (context, index) {
                                final item = booksWithBookmarks[index];
                                final book = item['book'] as Map<String, String>;
                                final pages = item['pages'] as List<int>;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFAFAFA),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.black.withValues(alpha: 0.06),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Book Title Header
                                        Row(
                                          children: [
                                            _buildBookCover(
                                              book['coverImage'],
                                              width: 38,
                                              height: 52,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    book['title']!,
                                                    style: const TextStyle(
                                                      fontSize: 14.5,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppTheme.primary,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${pages.length} محفوظ شدہ صفحات',
                                                    style: const TextStyle(
                                                      fontSize: 11.5,
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        const Divider(height: 1),
                                        const SizedBox(height: 10),
                                        // Bookmark Pills
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: pages.map((page) {
                                            return InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              onTap: () async {
                                                final isDownloaded =
                                                    await PDFCacheManager
                                                        .isDownloaded(
                                                          book['title']!,
                                                        );
                                                if (!modalContext.mounted) return;
                                                if (isDownloaded) {
                                                  Navigator.pop(modalContext);
                                                  _openPDF(
                                                    book,
                                                    targetPage: page,
                                                  );
                                                } else {
                                                  ScaffoldMessenger.of(
                                                    modalContext,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'صفحہ کھولنے کے لیے پہلے کتاب ڈاؤن لوڈ کریں',
                                                        textAlign:
                                                            TextAlign.right,
                                                      ),
                                                      backgroundColor:
                                                          Color(0xFFC99B3B),
                                                    ),
                                                  );
                                                }
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 5,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: AppTheme.accent
                                                        .withValues(alpha: 0.4),
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                            alpha: 0.03,
                                                          ),
                                                      blurRadius: 4,
                                                      offset:
                                                          const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.bookmark_rounded,
                                                      size: 14,
                                                      color: Color(0xFFC99B3B),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'صفحہ ${page + 1}',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Color(0xFF1E2522),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    GestureDetector(
                                                      onTap: () async {
                                                        pages.remove(page);
                                                        final p =
                                                            await SharedPreferences
                                                                .getInstance();
                                                        await p.setStringList(
                                                          'bookmarks_${book['title']}',
                                                          pages
                                                              .map(
                                                                (e) =>
                                                                    e.toString(),
                                                              )
                                                              .toList(),
                                                        );
                                                        if (pages.isEmpty) {
                                                          booksWithBookmarks
                                                              .removeAt(index);
                                                        }
                                                        setModalState(() {});
                                                        setState(() {
                                                          _rebuildKey++;
                                                        });
                                                      },
                                                      child: const Icon(
                                                        Icons.close_rounded,
                                                        size: 14,
                                                        color: Colors.black45,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _downloadBook(Map<String, String> book) {
    final bookId = book['title']!;
    final fileName = book['fileName'] ?? '$bookId.pdf';
    final fullUrl = AppConfig.getPdfUrl(fileName);

    if (fullUrl == null || !AppConfig.isPdfServerConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'سرور کا لنک ابھی مقرر نہیں ہے۔ جیسے ہی سرور ایڈریس شامل ہوگا ڈاؤن لوڈ دستیاب ہوگی۔',
            textAlign: TextAlign.right,
          ),
          backgroundColor: Color(0xFFC5A059),
        ),
      );
      return;
    }

    _progressSubscriptions[bookId]?.cancel();
    _progressSubscriptions[bookId] = _downloadService
        .getProgressStream(bookId)
        .listen((progress) {
          if (mounted) {
            setState(() {
              _downloadProgress[bookId] = progress;
            });
          }
        });

    _statusSubscriptions[bookId]?.cancel();
    _statusSubscriptions[bookId] = _downloadService
        .getStatusStream(bookId)
        .listen((isDownloading) async {
          if (mounted) {
            setState(() {
              _isDownloading[bookId] = isDownloading;
              if (!isDownloading) {
                _downloadProgress.remove(bookId);
                _rebuildKey++;
              }
            });

            if (!isDownloading) {
              final isDownloaded = await PDFCacheManager.isDownloaded(bookId);
              if (isDownloaded && mounted) {
                _openPDF(book);
              }
            }
          }
        });

    _errorSubscriptions[bookId]?.cancel();
    _errorSubscriptions[bookId] = _downloadService
        .getErrorStream(bookId)
        .listen((errorMsg) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMsg, textAlign: TextAlign.right),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        });

    _downloadService.downloadBook(bookId, fullUrl);
  }

  void _openPDF(Map<String, String> book, {int? targetPage}) async {
    final cachedPath = await PDFCacheManager.getCachedPDF(book['title']!);
    if (!mounted || cachedPath == null) return;

    // Save as last read book
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_opened_book', book['title']!);

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                PDFViewerScreen(
                  title: book['title']!,
                  localPath: cachedPath,
                  targetPage: targetPage,
                ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _rebuildKey++;
        });
      }
    });
  }

  // Exact Catalog of Sheikh Abdul Salam Al-Rustami's Works with Authentic Covers
  static final List<Map<String, String>> _sampleBooks = [
    {
      'title': 'الموسوعة القرآنية (جلد ۱)',
      'category': 'تفسیر قرآن',
      'pages': '464',
      'fileName': 'الموسوعة 1.pdf',
      'coverImage': 'assets/images/books/الموسوعة 1.png',
      'description': 'الموسوعة القرآنية والفرائد الربانية - الجزء الأول',
      'language': 'عربی',
    },
    {
      'title': 'الموسوعة القرآنية (جلد ۲)',
      'category': 'تفسیر قرآن',
      'pages': '464',
      'fileName': 'الموسوعة 2.pdf',
      'coverImage': 'assets/images/books/الموسوعة 2.png',
      'description': 'الموسوعة القرآنية والفرائد الربانية - الجزء الثاني',
      'language': 'عربی',
    },
    {
      'title': 'الموسوعة القرآنية (جلد ۳)',
      'category': 'تفسیر قرآن',
      'pages': '483',
      'fileName': 'الموسوعة 3.pdf',
      'coverImage': 'assets/images/books/الموسوعة 3.png',
      'description': 'الموسوعة القرآنية والفرائد الربانية - الجزء الثالث',
      'language': 'عربی',
    },
    {
      'title': 'تفسیر احسن الکلام (پښتو)',
      'category': 'تفسیر قرآن',
      'pages': 'موبائل ایپ',
      'fileName': '',
      'coverImage': 'assets/images/books/تفسیر احسن الکلام.jpg',
      'description': 'تفسیر احسن الکلام پښتو موبائل ایپلی کیشن (شیخ عبدالسلام الرستمی رحمہ اللہ)',
      'language': 'پشتو',
      'isApp': 'true',
      'package': 'com.m_imran.tafsir_ahsan_al_kalam',
      'storeUrl': 'https://play.google.com/store/apps/details?id=com.m_imran.tafsir_ahsan_al_kalam',
    },
    {
      'title': 'انکارِ حدیث سے انکارِ قرآن تک',
      'category': 'توحید وعقیدہ',
      'pages': '449',
      'fileName': 'انکار حدیث سے انکار قرآن تک.pdf',
      'coverImage': 'assets/images/books/انکارحدیث سے انکار قرآن تک.jpg',
      'description': 'انکار حدیث کے فتنے کا علمی اور تحقیقی رد از دار السلام',
      'language': 'اردو',
    },
    {
      'title': 'ترتيب الجهاد بمقابلة أهل الإلحاد',
      'category': 'خطبات ومقالات',
      'pages': '223',
      'fileName': 'ترتيب الجهاد.pdf',
      'coverImage': 'assets/images/books/ترتيب الجهاد.jpg',
      'description': 'جهاد اور دفاع اسلام پر مستند پښتو تصنیف',
      'language': 'پشتو',
    },
    {
      'title': 'توجيه الناظرين إلى مقاصد الكتاب المبين',
      'category': 'تفسیر قرآن',
      'pages': '409',
      'fileName': 'توجيه الناظرين.pdf',
      'coverImage': 'assets/images/books/توجيه الناظرين.jpg',
      'description': 'قرآن مجید کے مقاصد اور مضامین کا جامع خلاصہ',
      'language': 'عربی',
    },
    {
      'title': 'جهود الشيخ في الدعوة الى الله',
      'category': 'خطبات ومقالات',
      'pages': '195',
      'fileName': 'جهود الشيخ في الدعوة الى الله.pdf',
      'coverImage': 'assets/images/books/جهود الشيخ في الدعوة الى الله.png',
      'description': 'شیخ عبدالسلام الرستمی کی تبلیغی و دعوتی خدمات',
      'language': 'عربی',
    },
    {
      'title': 'سهام الصياد',
      'category': 'توحید وعقیدہ',
      'pages': '126',
      'fileName': 'سهام الصياد.pdf',
      'coverImage': 'assets/images/books/سهام الصياد.png',
      'description': 'بدعات و منکرات کی تردید اور توحید و سنت کا بیان',
      'language': 'اردو',
    },
    {
      'title': 'غيث السحابة على أمة الإجابة',
      'category': 'توحید وعقیدہ',
      'pages': '205',
      'fileName': 'غيث السحابة على أمة الإجابة.pdf',
      'coverImage': 'assets/images/books/غيث السحابة على أمة الإجابة.jpg',
      'description': 'فضائل صحابہ کرام رضوان اللہ علیہم اجمعین کی مستند تحقیق',
      'language': 'عربی',
    },
    {
      'title': 'مونږ په رڼا د احادیثو کښې',
      'category': 'فقہ واحکام',
      'pages': '257',
      'fileName': 'مونز پہ رنڑا د احادیثو کی.pdf',
      'coverImage': 'assets/images/books/مونز پہ رنڑا د احادیثو کی.jpg',
      'description': 'کتاب الصلوة النبوية في ضوء النصوص الشرعية (پشتو)',
      'language': 'پشتو',
    },
    {
      'title': 'أحسن الندي لرد المودودي',
      'category': 'توحید وعقیدہ',
      'pages': '106',
      'fileName': 'أحسن الندي لرد المودودي.pdf',
      'coverImage': 'assets/images/books/أحسن الندي لرد المودودي.png',
      'description': 'مولانا مودودی کے بعض نظریات پر علمی و تحقیقی رد',
      'language': 'اردو',
    },
    {
      'title': 'الدر المفتون في أحوال المسجون',
      'category': 'خطبات ومقالات',
      'pages': '43',
      'fileName': 'الدور المفتون في أحوال المسجون.pdf',
      'coverImage': 'assets/images/books/الدور المفتون في أحوال المسجون.png',
      'description': 'قید وبند کی صعوبتوں اور ایمانی احوال پر اثر انگیز تالیف',
      'language': 'پشتو',
    },
    {
      'title': 'المنهاج المستقيم',
      'category': 'توحید وعقیدہ',
      'pages': '160',
      'fileName': 'منهاج المستقيم.pdf',
      'coverImage': 'assets/images/books/المنہاج المستقیم.jpg',
      'description': 'رد عیسائیت اور اثبات تحریف کتب مقدسہ پر علمی کتاب',
      'language': 'عربی',
    },
    {
      'title': 'بدرة الصلات في رد الشبهات',
      'category': 'توحید وعقیدہ',
      'pages': '459',
      'fileName': 'بدرة الصلاة.pdf',
      'coverImage': 'assets/images/books/بدرۃ الصلات.jpeg',
      'description': 'دفاع سنت نبویہ اور منکرین و معاندین کے شبہات کا ازالہ',
      'language': 'عربی',
    },
    {
      'title': 'سيرة الأزم (پشتو)',
      'category': 'سیرت وتاریخ',
      'pages': '100',
      'fileName': 'سيرة الآزم بشتو.pdf',
      'coverImage': 'assets/images/books/سيرة الآزم بشتو.png',
      'description': 'سیرت النبی ﷺ اور اسلامی تاریخ پر مستند پښتو کتاب',
      'language': 'پشتو',
    },
    {
      'title': 'سيرة الأزم (اردو)',
      'category': 'سیرت وتاریخ',
      'pages': '111',
      'fileName': 'سيرة الأزم اردو.pdf',
      'coverImage': 'assets/images/books/سيرة الأزم اردو.jpeg',
      'description': 'سیرت خاتم النبیین ﷺ پر مفصل و جامع اردو تالیف',
      'language': 'اردو',
    },
    {
      'title': 'سیرت امام بخاری رحمہ اللہ',
      'category': 'سیرت وتاریخ',
      'pages': '50',
      'fileName': 'سيرة الإمام البخاري.pdf',
      'coverImage': 'assets/images/books/سیرت امام بخاری.jpg',
      'description': 'امیر المؤمنین فی الحدیث امام بخاری کی سوانح و خدمات حدیث',
      'language': 'عربی',
    },
    {
      'title': 'لطائف القرآن الكريم',
      'category': 'تفسیر قرآن',
      'pages': '147',
      'fileName': 'لطائف القرآن.pdf',
      'coverImage': 'assets/images/books/لطائف القرآن.jpg',
      'description': 'قرآن مجید کے علمی و ایمانی نکات، اسرار اور لطائف تفسیریہ',
      'language': 'عربی',
    },
    {
      'title': 'الدرر المنظومات في ربط السور والآيات',
      'category': 'تفسیر قرآن',
      'pages': '281',
      'fileName': 'الدرر المنظومات في ربط السور والايات.pdf',
      'coverImage': 'assets/images/books/الدرر المنظومات في ربط السور والايات.jpg',
      'description': 'د قرآن د سورتونو او آيتونو ترمنځ د ربط په اړه پښتو رساله',
      'language': 'پشتو',
    },
    {
      'title': 'لمونځ: ترجمہ او تشریح',
      'category': 'فقہ واحکام',
      'pages': '48',
      'fileName': 'مونز ترجمة او تشريح.pdf',
      'coverImage': 'assets/images/books/مونز ترجمة او تشريح.png',
      'description': 'د لمونځ سنت طریقہ، ترجمہ او تفصیلی تشریح (پښتو)',
      'language': 'پشتو',
    },
    {
      'title': 'منهج الشيخ الرستمي في التفسير',
      'category': 'تفسیر قرآن',
      'pages': '232',
      'fileName': 'منهج الشيخ الرستمي في التفسير (محمد طارق).pdf',
      'coverImage': 'assets/images/books/منهج الشيخ الرستمي في التفسير.jpg',
      'description': 'رسالة ماجستير - الجامعة الإسلامية العالمية بإسلام آباد (إعداد: محمد طارق، إشراف: أ.د. تاج أفسر)',
      'language': 'عربی',
    },
    {
      'title': 'پشتو ختم النبوت',
      'category': 'توحید وعقیدہ',
      'pages': '140',
      'fileName': 'پشتو ختم النبوت.pdf',
      'coverImage': 'assets/images/books/پشتو ختم النبوت.jpeg',
      'description': 'مسئلہ د ختم نبوت د قرآن او د سنت پہ رنڑا کښی (پښتو)',
      'language': 'پشتو',
    },
  ];
}
