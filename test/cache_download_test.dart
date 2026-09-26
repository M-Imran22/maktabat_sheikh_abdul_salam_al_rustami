import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maktabat_sheikh_abdul_salam_al_rustami/services/download_service.dart';
import 'package:maktabat_sheikh_abdul_salam_al_rustami/utils/audio_cache_manager.dart';
import 'package:maktabat_sheikh_abdul_salam_al_rustami/utils/pdf_cache_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documents;
  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');

  setUp(() async {
    documents = await Directory.systemTemp.createTemp(
      'maktabat_download_test_',
    );
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, (call) async => documents.path);
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, null);
    await documents.delete(recursive: true);
  });

  test(
    'A stale PDF preference does not claim a missing file is downloaded',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('downloaded_missing-book', true);

      expect(await PDFCacheManager.isDownloaded('missing-book'), isFalse);
    },
  );

  test('A PDF is visible in the cache only after download completes', () async {
    final bytes = <int>[37, 80, 68, 70, ...List<int>.filled(2048, 65)];
    final chunks = StreamController<List<int>>();
    addTearDown(() async {
      if (!chunks.isClosed) await chunks.close();
    });
    final client = _TestClient(
      (request) async => http.StreamedResponse(
        chunks.stream,
        200,
        contentLength: bytes.length,
      ),
    );
    final firstProgress = DownloadService()
        .getProgressStream('test-book')
        .firstWhere((value) => value > 0);

    final download = DownloadService().downloadBook(
      'test-book',
      'https://example.invalid/test.pdf',
      clientFactory: () => client,
    );
    chunks.add(bytes.sublist(0, 700));
    await firstProgress.timeout(const Duration(seconds: 5));
    expect(await PDFCacheManager.isDownloaded('test-book'), isFalse);
    expect(await File('${documents.path}/test-book.pdf').exists(), isFalse);

    chunks.add(bytes.sublist(700));
    await chunks.close();
    await download;
    expect(await PDFCacheManager.isDownloaded('test-book'), isTrue);
    expect(
      await File('${documents.path}/test-book.pdf.part').exists(),
      isFalse,
    );
  });

  test('Invalid PDF responses are discarded', () async {
    final client = _TestClient(
      (request) async => http.StreamedResponse(
        Stream.value(List<int>.filled(2048, 65)),
        200,
        contentLength: 2048,
      ),
    );

    await DownloadService().downloadBook(
      'invalid-book',
      'https://example.invalid/invalid.pdf',
      clientFactory: () => client,
    );
    expect(await PDFCacheManager.isDownloaded('invalid-book'), isFalse);
    expect(
      await File('${documents.path}/invalid-book.pdf.part').exists(),
      isFalse,
    );
  });

  test('An audio download is published only after its final chunk', () async {
    final bytes = List<int>.filled(2048, 65);
    final chunks = StreamController<List<int>>();
    addTearDown(() async {
      if (!chunks.isClosed) await chunks.close();
    });
    final client = _TestClient(
      (request) async => http.StreamedResponse(
        chunks.stream,
        200,
        contentLength: bytes.length,
      ),
    );
    const relativePath = 'collection/downloaded-track.mp3';
    final firstProgress = DownloadService()
        .getProgressStream(relativePath)
        .firstWhere((value) => value > 0);

    final download = DownloadService().downloadAudio(
      relativePath,
      'https://example.invalid/track.mp3',
      clientFactory: () => client,
    );
    chunks.add(bytes.sublist(0, 700));
    await firstProgress.timeout(const Duration(seconds: 5));
    expect(await AudioCacheManager.isDownloaded(relativePath), isFalse);

    chunks.add(bytes.sublist(700));
    await chunks.close();
    await download;
    expect(await AudioCacheManager.isDownloaded(relativePath), isTrue);
    expect(
      await File('${documents.path}/app_audio/$relativePath.part').exists(),
      isFalse,
    );
  });

  test(
    'Audio cache lookup does not create folders or accept tiny files',
    () async {
      const relativePath = 'collection/track.mp3';
      expect(await AudioCacheManager.isDownloaded(relativePath), isFalse);
      expect(await Directory('${documents.path}/app_audio').exists(), isFalse);

      final file = await AudioCacheManager.getLocalFile(relativePath);
      await file.writeAsBytes([1, 2, 3]);
      expect(await AudioCacheManager.isDownloaded(relativePath), isFalse);

      await file.writeAsBytes(List<int>.filled(2048, 65));
      expect(await AudioCacheManager.isDownloaded(relativePath), isTrue);
    },
  );
}

class _TestClient extends http.BaseClient {
  _TestClient(this._send);

  final Future<http.StreamedResponse> Function(http.BaseRequest) _send;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _send(request);
}
