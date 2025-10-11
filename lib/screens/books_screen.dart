import 'package:flutter/material.dart';
import 'pdf_viewer_screen.dart';
import '../utils/pdf_cache_manager.dart';
import '../widgets/search_delegate.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  final Map<String, double> _downloadProgress = {};
  final Map<String, bool> _isDownloading = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'کتابیں',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: BookSearchDelegate(_sampleBooks),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sampleBooks.length,
        itemBuilder: (context, index) {
          final book = _sampleBooks[index];
          return _buildBookCard(book, context);
        },
      ),
    );
  }

  Widget _buildBookCard(Map<String, String> book, BuildContext context) {
    return FutureBuilder<bool>(
      future: PDFCacheManager.isDownloaded(book['title']!),
      builder: (context, snapshot) {
        final isDownloaded = snapshot.data ?? false;
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Stack(
              children: [
                Container(
                  width: 50,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.picture_as_pdf,
                    color: Colors.green[700],
                    size: 30,
                  ),
                ),
                if (isDownloaded)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isDownloaded)
                  const Icon(Icons.offline_pin, color: Colors.green, size: 16),
                Expanded(
                  child: Text(
                    book['title']!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            subtitle: Text(
              book['description']!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
              textAlign: TextAlign.right,
            ),
            trailing: _buildTrailingWidget(book, isDownloaded),
            onTap: () {
              if (isDownloaded) {
                _openPDF(context, book);
              } else {
                _downloadBook(book);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildTrailingWidget(Map<String, String> book, bool isDownloaded) {
    final bookId = book['title']!;
    final isDownloading = _isDownloading[bookId] ?? false;
    final progress = _downloadProgress[bookId] ?? 0.0;

    if (isDownloading) {
      return Container(
        width: 40,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 2,
                color: Colors.green,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      );
    }

    return Icon(
      isDownloaded ? Icons.menu_book : Icons.download,
      color: isDownloaded ? Colors.green : Colors.grey,
      size: 20,
    );
  }

  Future<void> _downloadBook(Map<String, String> book) async {
    final bookId = book['title']!;
    print('DEBUG: Starting download for $bookId');
    
    setState(() {
      _isDownloading[bookId] = true;
      _downloadProgress[bookId] = 0.0;
    });

    try {
      final response = await http.get(Uri.parse(book['url']!));
      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response length: ${response.bodyBytes.length} bytes');
      
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$bookId.pdf');
      print('DEBUG: Saving to: ${file.path}');
      
      // Simulate progress for user feedback
      for (int i = 0; i <= 100; i += 10) {
        setState(() {
          _downloadProgress[bookId] = i / 100;
        });
        await Future.delayed(const Duration(milliseconds: 50));
      }
      
      await file.writeAsBytes(response.bodyBytes);
      await PDFCacheManager.markAsDownloaded(bookId);
      print('DEBUG: Download completed successfully');
      
      setState(() {
        _isDownloading[bookId] = false;
        _downloadProgress[bookId] = 1.0;
      });
      
    } catch (e) {
      print('DEBUG: Download error: $e');
      setState(() {
        _isDownloading[bookId] = false;
        _downloadProgress[bookId] = 0.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
  }

  void _openPDF(BuildContext context, Map<String, String> book) async {
    final cachedPath = await PDFCacheManager.getCachedPDF(book['title']!);
    if (cachedPath != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFViewerScreen(
            title: book['title']!,
            localPath: cachedPath,
          ),
        ),
      );
    }
  }

  static final List<Map<String, String>> _sampleBooks = [
    {
      'title': 'کتاب دوم',
      'description': 'شیخ عبدالسلام الرستمی کی تصنیفات',
      'url': 'https://drive.google.com/uc?export=download&id=1OK56PathWtWQJGW3lS2ZP4-3WIg8N9NI',
    },
    {
      'title': 'کتاب سوم',
      'description': 'شیخ عبدالسلام الرستمی کی تصنیفات',
      'url': 'https://drive.google.com/uc?export=download&id=1cM0ituZPeDR1W0Va9tXIKhuPMZ6eMsYa',
    },
    {
      'title': 'کتاب چہارم',
      'description': 'شیخ عبدالسلام الرستمی کی تصنیفات',
      'url': 'https://drive.google.com/uc?export=download&id=18H_nv-aHFZVVr9p80i19ejizV88W1nLe',
    },
    {
      'title': 'کتاب پنجم',
      'description': 'شیخ عبدالسلام الرستمی کی تصنیفات',
      'url': 'https://drive.google.com/uc?export=download&id=10VWDKlZ4HAXJrE10AYPNYbzrPwdHXM6G',
    },
    {
      'title': 'کتاب ششم',
      'description': 'شیخ عبدالسلام الرستمی کی تصنیفات',
      'url': 'https://drive.google.com/uc?export=download&id=1Tg0IdqntgMUOomKhyaUHt3xSb8l6ldaV',
    },
    {
      'title': 'کتاب ہفتم',
      'description': 'شیخ عبدالسلام الرستمی کی تصنیفات',
      'url': 'https://drive.google.com/uc?export=download&id=1__DSl6MzOYUYhfDE4rr1AIRRT5Z0HJE2',
    },
    {
      'title': 'کتاب ہشتم',
      'description': 'شیخ عبدالسلام الرستمی کی تصنیفات',
      'url': 'https://drive.google.com/uc?export=download&id=12yl9BqL8aBh-eNKvOfWmQ1X5XbAS0exF',
    },
    {
      'title': 'کتاب نہم',
      'description': 'شیخ عبدالسلام الرستمی کی تصنیفات',
      'url': 'https://drive.google.com/uc?export=download&id=1QbEBOMC0MXrQ6hHgI7wkQn_O3TKS2lF7',
    },
  ];
}