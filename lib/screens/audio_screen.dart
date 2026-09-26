import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../services/audio_player_service.dart';
import '../services/download_service.dart';
import '../utils/audio_cache_manager.dart';
import '../constants/app_config.dart';
import '../constants/app_theme.dart';

class AudioScreen extends StatefulWidget {
  const AudioScreen({super.key});

  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen> {
  final AudioPlayerService _audioService = AudioPlayerService();
  final DownloadService _downloadService = DownloadService();

  List<Map<String, dynamic>> _allAudios = [];

  // Navigation state inside the audio directory structure
  String? _selectedCategory; // null = Root (collections)
  String? _selectedSubfolder; // null = Top of collection
  bool _showOnlyDownloaded = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final Map<String, StreamSubscription<double>> _progressSubscriptions = {};
  final Map<String, StreamSubscription<bool>> _statusSubscriptions = {};
  final Map<String, StreamSubscription<String>> _errorSubscriptions = {};
  final Map<String, double> _downloadProgress = {};
  final Map<String, bool> _isDownloading = {};
  int _rebuildKey = 0;

  @override
  void initState() {
    super.initState();
    _loadAudioCatalog();
  }

  Future<void> _loadAudioCatalog() async {
    // 1. Try loading previously synced dynamic catalog from device storage
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final cacheFile = File('${docDir.path}/cached_audio_catalog.json');
      if (await cacheFile.exists()) {
        final jsonString = await cacheFile.readAsString();
        final List<dynamic> decoded = json.decode(jsonString);
        if (mounted && decoded.isNotEmpty) {
          setState(() {
            _allAudios = decoded.cast<Map<String, dynamic>>();
          });
        }
      }
    } catch (_) {}

    // 2. If no cache yet, load the bundled asset
    if (_allAudios.isEmpty) {
      try {
        final jsonString = await rootBundle.loadString(
          'assets/data/audio_catalog.json',
        );
        final List<dynamic> decoded = json.decode(jsonString);
        if (mounted) {
          setState(() {
            _allAudios = decoded.cast<Map<String, dynamic>>();
          });
        }
      } catch (_) {}
    }

    // 3. Sync with server in background if audio server is configured
    _syncRemoteCatalog();
  }

  Future<void> _syncRemoteCatalog({bool notifyUser = false}) async {
    final catalogUrl = AppConfig.audioCatalogUrl;
    if (catalogUrl == null) return;

    try {
      final response = await http
          .get(Uri.parse(catalogUrl))
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final content = utf8.decode(response.bodyBytes);
        final List<dynamic> decoded = json.decode(content);
        final newAudios = decoded.cast<Map<String, dynamic>>();
        if (newAudios.isNotEmpty &&
            json.encode(newAudios) != json.encode(_allAudios)) {
          final docDir = await getApplicationDocumentsDirectory();
          final cacheFile = File('${docDir.path}/cached_audio_catalog.json');
          await cacheFile.writeAsString(content);

          if (mounted) {
            setState(() {
              _allAudios = newAudios;
            });
            if (notifyUser) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'آڈیو فہرست کامیابی سے اپ ڈیٹ ہو گئی! (کل آڈیوز: ${_allAudios.length})',
                    textAlign: TextAlign.right,
                  ),
                  backgroundColor: AppTheme.primary,
                ),
              );
            }
          }
        } else if (notifyUser && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'آپ کی آڈیو فہرست پہلے سے تازہ ترین ہے',
                textAlign: TextAlign.right,
              ),
              backgroundColor: AppTheme.primary,
            ),
          );
        }
      }
    } catch (_) {
      if (notifyUser && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'سرور سے فہرست حاصل نہیں ہو سکی۔ براہ کرم انٹرنیٹ چیک کریں۔',
              textAlign: TextAlign.right,
            ),
            backgroundColor: Color(0xFFC5A059),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (var sub in _progressSubscriptions.values) {
      sub.cancel();
    }
    for (var sub in _statusSubscriptions.values) {
      sub.cancel();
    }
    for (var sub in _errorSubscriptions.values) {
      sub.cancel();
    }
    super.dispose();
  }

  static const List<String> defaultCategories = [
    '1987 تفسیر القرآن',
    'شيخ عبد السلام تفسير 2003',
    'شیخ عبد السلام صاحب  آڈیو بیا نا ت',
    'لفظي ترجمة شيخ القرآن',
    'مختصر دورہ تفسیرالقرآن سعیدآباد پشاور',
    'مشكلات القرآن',
    'urdu',
  ];

  // Extract the 5 top-level categories
  List<String> get _categories {
    final set = <String>{};
    for (final a in _allAudios) {
      final c = a['category'] as String?;
      if (c != null && c.isNotEmpty) set.add(c);
    }
    if (set.isEmpty) return defaultCategories;
    return set.toList();
  }

  // Extract subfolders for the currently selected category
  List<String> get _subfoldersForSelectedCategory {
    if (_selectedCategory == null) return [];
    final set = <String>{};
    for (final a in _allAudios) {
      if (a['category'] == _selectedCategory) {
        final sub = a['subfolder'] as String? ?? '';
        if (sub.isNotEmpty) set.add(sub);
      }
    }
    return set.toList();
  }

  // Get active audio tracks based on category, subfolder, search, and downloaded filter
  List<Map<String, dynamic>> get _currentTracks {
    return _allAudios.where((a) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final title = (a['title'] ?? '').toString().toLowerCase();
        final cat = (a['category'] ?? '').toString().toLowerCase();
        final sub = (a['subfolder'] ?? '').toString().toLowerCase();
        return title.contains(q) || cat.contains(q) || sub.contains(q);
      }

      if (_selectedCategory != null && a['category'] != _selectedCategory) {
        return false;
      }

      if (_selectedSubfolder != null) {
        return a['subfolder'] == _selectedSubfolder;
      }

      // If category has no subfolders, show direct files
      final hasSubfolders = _subfoldersForSelectedCategory.isNotEmpty;
      if (hasSubfolders && _selectedSubfolder == null) {
        return false;
      }

      return true;
    }).toList();
  }

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
          leading:
              (_selectedCategory != null ||
                      _searchQuery.isNotEmpty ||
                      _showOnlyDownloaded)
                  ? IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_rounded,
                      color: primaryEmerald,
                    ),
                    onPressed: () {
                      setState(() {
                        if (_searchQuery.isNotEmpty) {
                          _searchQuery = '';
                          _searchController.clear();
                        } else if (_showOnlyDownloaded) {
                          _showOnlyDownloaded = false;
                        } else if (_selectedSubfolder != null) {
                          _selectedSubfolder = null;
                        } else {
                          _selectedCategory = null;
                        }
                      });
                    },
                  )
                  : null,
          title: Text(
            _getAppBarTitle(),
            style: const TextStyle(
              color: primaryEmerald,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          centerTitle: true,
          actions: [
            // Sync Catalog from Server Button
            if (AppConfig.isAudioServerConfigured)
              IconButton(
                icon: const Icon(Icons.sync_rounded, color: primaryEmerald),
                tooltip: 'فہرست تازہ کریں',
                onPressed: () => _syncRemoteCatalog(notifyUser: true),
              ),
            // Offline Filter Toggle
            IconButton(
              icon: Icon(
                _showOnlyDownloaded
                    ? Icons.offline_pin_rounded
                    : Icons.offline_pin_outlined,
                color: _showOnlyDownloaded ? accentGold : primaryEmerald,
              ),
              tooltip: 'ڈاؤن لوڈ شدہ آڈیوز',
              onPressed: () {
                setState(() {
                  _showOnlyDownloaded = !_showOnlyDownloaded;
                  _selectedCategory = null;
                  _selectedSubfolder = null;
                });
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Search Bar
            _buildSearchBar(),

            // Breadcrumb navigation indicator if inside a folder
            if (_selectedCategory != null &&
                !_showOnlyDownloaded &&
                _searchQuery.isEmpty)
              _buildBreadcrumb(),

            // Main Content Area
            Expanded(child: _buildCurrentView()),

            // Persistent Bottom Mini-Player Bar
            _buildMiniPlayer(),
          ],
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    if (_showOnlyDownloaded) return 'ڈاؤن لوڈ شدہ آڈیوز (آف لائن)';
    if (_searchQuery.isNotEmpty) return 'تلاش کے نتائج';
    if (_selectedSubfolder != null) return _selectedSubfolder!;
    if (_selectedCategory != null) return _selectedCategory!;
    return 'آڈیو لائبریری (مجموعات)';
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'آڈیو، سورت یا بیان تلاش کریں...',
          hintStyle: const TextStyle(fontSize: 13.5, color: Colors.black45),
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (val) {
          setState(() {
            _searchQuery = val.trim();
          });
        },
      ),
    );
  }

  Widget _buildBreadcrumb() {
    const primaryEmerald = AppTheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: primaryEmerald.withValues(alpha: 0.05),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = null;
                _selectedSubfolder = null;
              });
            },
            child: const Text(
              'تمام مجموعات',
              style: TextStyle(
                color: primaryEmerald,
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_left, size: 16, color: Colors.black45),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _selectedSubfolder != null
                  ? '$_selectedCategory > $_selectedSubfolder'
                  : _selectedCategory!,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView() {
    // 1. If searching, show search results list
    if (_searchQuery.isNotEmpty) {
      final tracks = _currentTracks;
      if (tracks.isEmpty) {
        return _buildEmptyState('کوئی آڈیو نہیں ملی');
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tracks.length,
        itemBuilder: (context, i) => _buildAudioCard(tracks[i]),
      );
    }

    // 2. If viewing downloaded only
    if (_showOnlyDownloaded) {
      return _buildDownloadedView();
    }

    // 3. Root View: 5 Collections
    if (_selectedCategory == null) {
      return _buildCategoriesList();
    }

    // 4. Subfolders View (if selected category has subfolders, like Surahs or Kitabs)
    final subfolders = _subfoldersForSelectedCategory;
    if (subfolders.isNotEmpty && _selectedSubfolder == null) {
      return _buildSubfoldersList(subfolders);
    }

    // 5. Track list view inside folder or subfolder
    final tracks = _currentTracks;
    if (tracks.isEmpty) {
      return _buildEmptyState('اس فولڈر میں کوئی فائل نہیں ہے');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tracks.length,
      itemBuilder: (context, i) => _buildAudioCard(tracks[i]),
    );
  }

  // --- Category Card List ---
  Widget _buildCategoriesList() {
    const primaryEmerald = AppTheme.primary;
    const accentGold = AppTheme.accent;

    final cats = _categories;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cats.length,
      itemBuilder: (context, index) {
        final catName = cats[index];
        final fileCount =
            _allAudios.where((a) => a['category'] == catName).length;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primaryEmerald.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.folder_rounded,
                  color: primaryEmerald,
                  size: 28,
                ),
              ),
              title: Text(
                catName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E2522),
                ),
              ),
              subtitle: Text(
                '$fileCount آڈیو دروس ریکارڈنگز',
                style: const TextStyle(fontSize: 12.5, color: Colors.black54),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: accentGold,
              ),
              onTap: () {
                setState(() {
                  _selectedCategory = catName;
                  _selectedSubfolder = null;
                });
              },
            ),
          ),
        );
      },
    );
  }

  // --- Subfolder List (Surahs or Kitabs) ---
  Widget _buildSubfoldersList(List<String> subfolders) {
    const primaryEmerald = AppTheme.primary;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: subfolders.length,
      itemBuilder: (context, index) {
        final subName = subfolders[index];
        final count =
            _allAudios
                .where(
                  (a) =>
                      a['category'] == _selectedCategory &&
                      a['subfolder'] == subName,
                )
                .length;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: ListTile(
              leading: const Icon(
                Icons.folder_open_rounded,
                color: Color(0xFFC5A059),
              ),
              title: Text(
                subName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primaryEmerald.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count آڈیوز',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: primaryEmerald,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              onTap: () {
                setState(() {
                  _selectedSubfolder = subName;
                });
              },
            ),
          ),
        );
      },
    );
  }

  // --- Downloaded Only View ---
  Widget _buildDownloadedView() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey('downloaded_view_$_rebuildKey'),
      future: _getDownloadedTracks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final downloaded = snapshot.data ?? [];
        if (downloaded.isEmpty) {
          return _buildEmptyState(
            'ابھی تک کوئی آڈیو ڈاؤن لوڈ نہیں کی گئی۔ انٹرنیٹ کے بغیر سننے کے لیے ڈاؤن لوڈ کا بٹن دبائیں۔',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: downloaded.length,
          itemBuilder: (context, i) => _buildAudioCard(downloaded[i]),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getDownloadedTracks() async {
    final results = <Map<String, dynamic>>[];
    for (final a in _allAudios) {
      final relPath = a['relativePath'] as String? ?? '';
      if (relPath.isNotEmpty && await AudioCacheManager.isDownloaded(relPath)) {
        results.add(a);
      }
    }
    return results;
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.headphones_outlined,
              size: 56,
              color: Colors.black.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(fontSize: 14.5, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --- Audio Card ---
  Widget _buildAudioCard(Map<String, dynamic> audio) {
    const primaryEmerald = AppTheme.primary;
    const accentGold = AppTheme.accent;

    final relPath = audio['relativePath'] as String? ?? '';
    final title = audio['title'] as String? ?? '';
    final durationStr = audio['durationStr'] as String? ?? '00:00';
    final sizeMB = audio['sizeMB']?.toString() ?? '';
    final isDownloading =
        _isDownloading[relPath] ?? _downloadService.isDownloading(relPath);

    return FutureBuilder<bool>(
      key: ValueKey('audio_card_${relPath}_$_rebuildKey'),
      future: AudioCacheManager.isDownloaded(relPath),
      builder: (context, snapshot) {
        final isDownloaded = snapshot.data ?? false;

        return StreamBuilder<Map<String, String>?>(
          stream: _audioService.currentAudioStream,
          initialData: _audioService.currentAudio,
          builder: (context, currentAudioSnap) {
            final current = currentAudioSnap.data;
            final isThisPlaying = current?['relativePath'] == relPath;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      isThisPlaying
                          ? accentGold
                          : Colors.black.withValues(alpha: 0.05),
                  width: isThisPlaying ? 1.6 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        isThisPlaying
                            ? accentGold.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  leading: StreamBuilder<PlayerState>(
                    stream: _audioService.stateStream,
                    initialData: _audioService.playerState,
                    builder: (context, stateSnap) {
                      final isPlaying =
                          isThisPlaying &&
                          stateSnap.data == PlayerState.playing;

                      return GestureDetector(
                        onTap: () => _handlePlay(audio),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color:
                                isThisPlaying
                                    ? primaryEmerald
                                    : primaryEmerald.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color:
                                isThisPlaying ? Colors.white : primaryEmerald,
                            size: 26,
                          ),
                        ),
                      );
                    },
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color:
                          isThisPlaying
                              ? primaryEmerald
                              : const Color(0xFF1E2522),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 13,
                              color: Colors.black45,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              durationStr,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        if (sizeMB.isNotEmpty)
                          Text(
                            '$sizeMB MB',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Colors.black45,
                            ),
                          ),
                        if (isDownloaded)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 14,
                                color: Colors.green,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'آف لائن دستیاب',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        // Saved resume position indicator
                        FutureBuilder<int>(
                          future: AudioPlayerService.getSavedAudioPosition(
                            relPath,
                          ),
                          builder: (context, posSnap) {
                            final posSec = posSnap.data ?? 0;
                            if (posSec > 2 && !isThisPlaying) {
                              final m = posSec ~/ 60;
                              final s = posSec % 60;
                              final posStr =
                                  '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: accentGold.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'جاری: $posStr',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF8C6D23),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isDownloading)
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            value:
                                _downloadProgress[relPath] ??
                                _downloadService.getProgress(relPath),
                            strokeWidth: 2.5,
                            color: accentGold,
                          ),
                        )
                      else if (!isDownloaded)
                        IconButton(
                          icon: const Icon(
                            Icons.cloud_download_outlined,
                            size: 22,
                            color: primaryEmerald,
                          ),
                          tooltip: 'ڈاؤن لوڈ کریں (آف لائن)',
                          onPressed: () => _downloadAudioTrack(relPath),
                        )
                      else
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: Colors.black45,
                          ),
                          tooltip: 'ڈاؤن لوڈ ختم کریں',
                          onPressed: () async {
                            await AudioCacheManager.deleteCachedAudio(relPath);
                            setState(() {
                              _rebuildKey++;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handlePlay(Map<String, dynamic> audio) {
    if (_audioService.currentAudio?['relativePath'] == audio['relativePath']) {
      if (_audioService.isPlaying) {
        _audioService.pause();
        return;
      }
      if (_audioService.playerState == PlayerState.paused) {
        _audioService.resume();
        return;
      }
    }
    final stringMap = audio.map(
      (key, value) => MapEntry(key, value.toString()),
    );
    _audioService.playAudio(stringMap);
  }

  void _downloadAudioTrack(String relPath) {
    final url = AppConfig.getAudioUrl(relPath);
    if (url == null || !AppConfig.isAudioServerConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'سرور کا آڈیو لنک ابھی مقرر نہیں ہے۔ لنک فعال ہوتے ہی ڈاؤن لوڈ دستیاب ہوگی۔',
            textAlign: TextAlign.right,
          ),
          backgroundColor: Color(0xFFC5A059),
        ),
      );
      return;
    }

    _progressSubscriptions[relPath]?.cancel();
    _progressSubscriptions[relPath] = _downloadService
        .getProgressStream(relPath)
        .listen((prog) {
          if (mounted) setState(() => _downloadProgress[relPath] = prog);
        });

    _statusSubscriptions[relPath]?.cancel();
    _statusSubscriptions[relPath] = _downloadService
        .getStatusStream(relPath)
        .listen((status) {
          if (mounted) {
            setState(() {
              _isDownloading[relPath] = status;
              if (!status) {
                _downloadProgress.remove(relPath);
                _rebuildKey++;
              }
            });
          }
        });

    _errorSubscriptions[relPath]?.cancel();
    _errorSubscriptions[relPath] = _downloadService
        .getErrorStream(relPath)
        .listen((err) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(err, textAlign: TextAlign.right),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        });

    _downloadService.downloadAudio(relPath, url);
  }

  // --- Bottom Mini Player ---
  Widget _buildMiniPlayer() {
    const primaryEmerald = AppTheme.primary;
    const accentGold = AppTheme.accent;

    return StreamBuilder<Map<String, String>?>(
      stream: _audioService.currentAudioStream,
      initialData: _audioService.currentAudio,
      builder: (context, snapshot) {
        final currentAudio = snapshot.data;
        if (currentAudio == null) return const SizedBox.shrink();

        return StreamBuilder<PlayerState>(
          stream: _audioService.stateStream,
          initialData: _audioService.playerState,
          builder: (context, stateSnap) {
            final isPlaying = stateSnap.data == PlayerState.playing;

            return Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: primaryEmerald.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.audiotrack,
                            color: primaryEmerald,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentAudio['title'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                currentAudio['category'] ??
                                    'شیخ عبدالسلام الرستمی',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isPlaying
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_fill_rounded,
                            size: 38,
                            color: primaryEmerald,
                          ),
                          onPressed: () {
                            if (isPlaying) {
                              _audioService.pause();
                            } else {
                              _audioService.resume();
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 22),
                          color: Colors.black45,
                          onPressed: () => _audioService.stop(),
                        ),
                      ],
                    ),
                    // Live Scrubber Progress
                    StreamBuilder<Duration>(
                      stream: _audioService.positionStream,
                      initialData: _audioService.position,
                      builder: (context, posSnap) {
                        final pos = posSnap.data ?? Duration.zero;
                        return StreamBuilder<Duration>(
                          stream: _audioService.durationStream,
                          initialData: _audioService.duration,
                          builder: (context, durSnap) {
                            final dur = durSnap.data ?? Duration.zero;
                            final maxSec =
                                dur.inSeconds > 0
                                    ? dur.inSeconds.toDouble()
                                    : 1.0;
                            final currentSec = pos.inSeconds.toDouble().clamp(
                              0.0,
                              maxSec,
                            );

                            return Column(
                              children: [
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 3,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 5,
                                    ),
                                    overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 10,
                                    ),
                                  ),
                                  child: Slider(
                                    value: currentSec,
                                    min: 0.0,
                                    max: maxSec,
                                    activeColor: accentGold,
                                    inactiveColor: Colors.black12,
                                    onChanged: (val) {
                                      _audioService.seek(
                                        Duration(seconds: val.round()),
                                      );
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(pos),
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      Text(
                                        _formatDuration(dur),
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? '${twoDigits(duration.inHours)}:$minutes:$seconds'
        : '$minutes:$seconds';
  }
}
