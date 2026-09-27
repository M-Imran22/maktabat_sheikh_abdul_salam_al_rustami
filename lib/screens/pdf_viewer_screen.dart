import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_theme.dart';

class PDFViewerScreen extends StatefulWidget {
  final String title;
  final String? localPath;
  final int? targetPage;

  const PDFViewerScreen({
    super.key,
    required this.title,
    required this.localPath,
    this.targetPage,
  });

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  String? localPath;
  bool isLoading = true;
  String? error;
  PDFViewController? controller;
  int currentPage = 0;
  int totalPages = 0;
  List<int> bookmarks = [];
  bool isNightMode = false;
  bool showScrubber = false;

  int initialPage = 0;
  bool isReaderReady = false;

  @override
  void initState() {
    super.initState();
    if (widget.localPath != null) {
      localPath = widget.localPath;
      _initReaderState();
    } else {
      error = 'پی ڈی ایف فائل دستیاب نہیں ہے';
      isLoading = false;
      isReaderReady = true;
    }
  }

  Future<void> _initReaderState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPage =
          widget.targetPage ?? prefs.getInt('last_page_${widget.title}') ?? 0;
      final bookmarkList =
          prefs.getStringList('bookmarks_${widget.title}') ?? [];
      if (mounted) {
        setState(() {
          initialPage = savedPage;
          currentPage = savedPage;
          bookmarks = bookmarkList.map((e) => int.parse(e)).toList();
          isLoading = false;
          isReaderReady = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          isLoading = false;
          isReaderReady = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _saveLastPage(currentPage);
    super.dispose();
  }

  Future<void> _saveLastPage(int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_page_${widget.title}', page);
    await prefs.setString('last_opened_book', widget.title);
  }

  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'bookmarks_${widget.title}',
      bookmarks.map((e) => e.toString()).toList(),
    );
  }

  void _toggleBookmark() {
    setState(() {
      if (bookmarks.contains(currentPage)) {
        bookmarks.remove(currentPage);
      } else {
        bookmarks.add(currentPage);
      }
    });
    _saveBookmarks();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          bookmarks.contains(currentPage)
              ? 'صفحہ ${currentPage + 1} بک مارک میں شامل کر دیا گیا'
              : 'بک مارک ختم کر دیا گیا',
          textAlign: TextAlign.right,
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showJumpToPageDialog() {
    final textController = TextEditingController(text: '${currentPage + 1}');
    showDialog(
      context: context,
      builder:
          (context) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              backgroundColor:
                  isNightMode ? const Color(0xFF242424) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.find_in_page_rounded,
                    color:
                        isNightMode
                            ? const Color(0xFFF7C844)
                            : AppTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'صفحہ پر جائیں',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isNightMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'صفحہ نمبر درج کریں (1 سے $totalPages):',
                    style: TextStyle(
                      color: isNightMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: textController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: isNightMode ? Colors.white : Colors.black87,
                    ),
                    autofocus: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      hintText: 'مثال: 45',
                      hintStyle: TextStyle(
                        color: isNightMode ? Colors.white38 : Colors.black38,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'منسوخ',
                    style: TextStyle(
                      color: isNightMode ? Colors.white60 : Colors.grey,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final input = int.tryParse(textController.text.trim());
                    if (input != null && input >= 1 && input <= totalPages) {
                      controller?.setPage(input - 1);
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'برائے مہربانی 1 سے $totalPages کے درمیان درست نمبر درج کریں',
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('جائیں'),
                ),
              ],
            ),
          ),
    );
  }

  void _showBookmarksModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: isNightMode ? const Color(0xFF242424) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'محفوظ شدہ صفحات (بک مارکس)',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isNightMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        '${bookmarks.length} نشان زدہ',
                        style: TextStyle(
                          color: isNightMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  Divider(color: isNightMode ? Colors.white24 : Colors.black12),
                  if (bookmarks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'ابھی تک کوئی صفحہ بک مارک نہیں کیا گیا',
                        style: TextStyle(
                          color: isNightMode ? Colors.white54 : Colors.grey,
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: bookmarks.length,
                        itemBuilder: (context, index) {
                          final page = bookmarks[index];
                          return ListTile(
                            leading: const Icon(
                              Icons.bookmark,
                              color: Color(0xFFC5A059),
                            ),
                            title: Text(
                              'صفحہ نمبر: ${page + 1}',
                              style: TextStyle(
                                color:
                                    isNightMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                setState(() {
                                  bookmarks.remove(page);
                                });
                                _saveBookmarks();
                                Navigator.pop(context);
                              },
                            ),
                            onTap: () {
                              controller?.setPage(page);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryEmerald = AppTheme.primary;
    const accentGold = AppTheme.accent;

    return Scaffold(
      backgroundColor: isNightMode ? Colors.black : const Color(0xFFE8E8E8),
      appBar: AppBar(
        backgroundColor: isNightMode ? const Color(0xFF181818) : Colors.white,
        foregroundColor: isNightMode ? Colors.white : Colors.black87,
        iconTheme: IconThemeData(
          color: isNightMode ? Colors.white : primaryEmerald,
        ),
        actionsIconTheme: IconThemeData(
          color: isNightMode ? Colors.white : primaryEmerald,
        ),
        elevation: 1,
        title: Text(
          widget.title,
          style: TextStyle(
            color: isNightMode ? Colors.white : const Color(0xFF1E2522),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          // Jump to page
          IconButton(
            icon: Icon(
              Icons.find_in_page_rounded,
              color: isNightMode ? Colors.white : primaryEmerald,
            ),
            tooltip: 'صفحہ تلاش کریں',
            onPressed: totalPages > 0 ? _showJumpToPageDialog : null,
          ),
          // Night mode toggle
          IconButton(
            icon: Icon(
              isNightMode ? Icons.light_mode_rounded : Icons.dark_mode_outlined,
              color: isNightMode ? const Color(0xFFF7C844) : primaryEmerald,
            ),
            tooltip: isNightMode ? 'ڈے موڈ' : 'نائٹ موڈ',
            onPressed: () {
              setState(() {
                initialPage = currentPage;
                controller = null;
                isNightMode = !isNightMode;
              });
            },
          ),
          // Bookmarks List
          IconButton(
            icon: Icon(
              Icons.bookmarks_outlined,
              color: isNightMode ? Colors.white : primaryEmerald,
            ),
            tooltip: 'بک مارکس لسٹ',
            onPressed: _showBookmarksModal,
          ),
          // Bookmark current page toggle
          IconButton(
            icon: Icon(
              bookmarks.contains(currentPage)
                  ? Icons.bookmark
                  : Icons.bookmark_border,
              color:
                  bookmarks.contains(currentPage)
                      ? const Color(0xFFF7C844)
                      : (isNightMode ? Colors.white : primaryEmerald),
            ),
            tooltip: 'صفحہ بک مارک کریں',
            onPressed: _toggleBookmark,
          ),
        ],
      ),
      body:
          (isLoading || !isReaderReady)
              ? const Center(
                child: CircularProgressIndicator(color: primaryEmerald),
              )
              : error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(error!, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryEmerald,
                      ),
                      child: const Text(
                        'واپس جائیں',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              )
              : Stack(
                children: [
                  // Native PDF pages need the viewer's own night mode.
                  PDFView(
                    key: ValueKey(isNightMode),
                    filePath: localPath!,
                    defaultPage: initialPage,
                    nightMode: isNightMode,
                    backgroundColor: isNightMode ? Colors.black : Colors.white,
                    enableSwipe: true,
                    swipeHorizontal: false,
                    autoSpacing: true,
                    pageFling: false,
                    fitEachPage: true,
                    fitPolicy: FitPolicy.WIDTH,
                    onViewCreated: (PDFViewController pdfViewController) {
                      controller = pdfViewController;
                    },
                    onPageChanged: (int? page, int? total) {
                      if (page != null) {
                        setState(() {
                          currentPage = page;
                          totalPages = total ?? totalPages;
                        });
                        _saveLastPage(page);
                      }
                    },
                  ),

                  // Scrubber Bar Drawer Toggle (bottom)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showScrubber && totalPages > 1)
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '1',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Expanded(
                                  child: Slider(
                                    value: currentPage.toDouble().clamp(
                                      0.0,
                                      (totalPages - 1).toDouble(),
                                    ),
                                    min: 0,
                                    max: (totalPages - 1).toDouble(),
                                    activeColor: accentGold,
                                    inactiveColor: Colors.white24,
                                    onChanged: (value) {
                                      controller?.setPage(value.round());
                                    },
                                  ),
                                ),
                                Text(
                                  '$totalPages',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Bottom Navigation Floating Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Quick Scrubber Slider Toggle
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  showScrubber = !showScrubber;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      showScrubber
                                          ? Icons.tune
                                          : Icons.linear_scale,
                                      color: accentGold,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      showScrubber
                                          ? 'سلائیڈر چھپائیں'
                                          : 'تیز رفتار صفحہ بندی',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Page Indicator (Tapping opens Jump Dialog)
                            GestureDetector(
                              onTap: _showJumpToPageDialog,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: accentGold.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Text(
                                  '${currentPage + 1} / $totalPages',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
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
    );
  }
}
