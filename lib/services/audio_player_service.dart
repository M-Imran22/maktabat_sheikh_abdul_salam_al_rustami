import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_config.dart';
import '../utils/audio_cache_manager.dart';

enum PlayerState { stopped, playing, paused, completed }

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;

  final AudioPlayer _player = AudioPlayer();

  Map<String, String>? _currentAudio;
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  int _lastSavedSecond = 0;

  final StreamController<PlayerState> _stateController =
      StreamController<PlayerState>.broadcast();
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();
  final StreamController<Map<String, String>?> _audioController =
      StreamController<Map<String, String>?>.broadcast();

  AudioPlayerService._internal() {
    _player.playerStateStream.listen((state) {
      PlayerState newState;
      if (state.processingState == ProcessingState.idle) {
        newState = PlayerState.stopped;
      } else if (state.processingState == ProcessingState.completed) {
        newState = PlayerState.completed;
      } else if (state.playing) {
        newState = PlayerState.playing;
      } else {
        newState = PlayerState.paused;
      }

      if (_playerState != newState) {
        _playerState = newState;
        _stateController.add(newState);
      }
    });

    _player.positionStream.listen((pos) {
      _position = pos;
      _positionController.add(pos);
      _savePositionThrottled(pos);
    });

    _player.durationStream.listen((dur) {
      if (dur != null) {
        _duration = dur;
        _durationController.add(dur);
      }
    });

    // When track finishes to the end, clear saved resume position
    _player.playbackEventStream.listen((event) async {
      if (_player.processingState == ProcessingState.completed) {
        final audioId = _getAudioId(_currentAudio);
        if (audioId.isNotEmpty) {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('audio_pos_$audioId');
          } catch (_) {}
        }
        _position = Duration.zero;
        _positionController.add(Duration.zero);
      }
    });
  }

  Map<String, String>? get currentAudio => _currentAudio;
  PlayerState get playerState => _playerState;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isPlaying => _playerState == PlayerState.playing;

  Stream<PlayerState> get stateStream => _stateController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration> get durationStream => _durationController.stream;
  Stream<Map<String, String>?> get currentAudioStream =>
      _audioController.stream;

  static String _getAudioId(Map<String, String>? audio) {
    if (audio == null) return '';
    return audio['relativePath'] ?? audio['fileName'] ?? audio['title'] ?? '';
  }

  /// Throttled persistence: saves position to SharedPreferences every 2-3 seconds
  void _savePositionThrottled(Duration pos) {
    final currentSec = pos.inSeconds;
    if ((currentSec - _lastSavedSecond).abs() >= 3 && _currentAudio != null) {
      _lastSavedSecond = currentSec;
      _saveCurrentAudioPosition(currentSec);
    }
  }

  Future<void> _saveCurrentAudioPosition(int seconds) async {
    final audioId = _getAudioId(_currentAudio);
    if (audioId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_duration.inSeconds > 10 && seconds >= _duration.inSeconds - 5) {
        await prefs.remove('audio_pos_$audioId');
      } else if (seconds > 2) {
        await prefs.setInt('audio_pos_$audioId', seconds);
        await prefs.setString('last_played_audio_id', audioId);
      }
    } catch (_) {}
  }

  /// Returns the saved playback position in seconds for a given audio ID.
  static Future<int> getSavedAudioPosition(String audioId) async {
    if (audioId.isEmpty) return 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('audio_pos_$audioId') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> playAudio(
    Map<String, String> audio, {
    bool resumeSaved = true,
  }) async {
    final relPath = audio['relativePath'] ?? audio['fileName'] ?? '';
    final audioId = _getAudioId(audio);
    final title = audio['title'] ?? 'بیان شیخ عبدالسلام';
    final category = audio['category'] ?? 'شیخ عبدالسلام الرستمی';

    // If same audio is paused, just resume
    if (_currentAudio?['relativePath'] == relPath &&
        _playerState == PlayerState.paused) {
      await _player.play();
      return;
    }

    _currentAudio = audio;
    _audioController.add(audio);
    _lastSavedSecond = 0;

    // Check for previously saved position
    int savedSec = 0;
    if (resumeSaved && audioId.isNotEmpty) {
      savedSec = await getSavedAudioPosition(audioId);
    }
    final initialPos =
        savedSec > 2 ? Duration(seconds: savedSec) : Duration.zero;

    final mediaItem = MediaItem(
      id: audioId.isNotEmpty ? audioId : 'audio_track',
      title: title,
      album: category,
      artist: 'شیخ عبدالسلام الرستمی رحمہ اللہ',
      artUri: Uri.parse('asset:///assets/images/banners/sheikh_portrait.png'),
    );

    // 1. Check if downloaded locally for offline playback
    if (relPath.isNotEmpty) {
      final cachedPath = await AudioCacheManager.getCachedAudioPath(relPath);
      if (cachedPath != null) {
        try {
          await _player.stop();
          final source = AudioSource.file(cachedPath, tag: mediaItem);
          await _player.setAudioSource(source, initialPosition: initialPos);
          await _player.play();
          return;
        } catch (_) {
          // If local read fails, fall back to remote
        }
      }
    }

    // 2. Stream remotely from server URL
    final url = AppConfig.getAudioUrl(relPath) ?? audio['url'];
    if (url != null && url.trim().isNotEmpty && url.startsWith('http')) {
      try {
        await _player.stop();
        final source = AudioSource.uri(Uri.parse(url), tag: mediaItem);
        await _player.setAudioSource(source, initialPosition: initialPos);
        await _player.play();
      } catch (e) {
        _playerState = PlayerState.stopped;
        _stateController.add(PlayerState.stopped);
      }
    } else {
      _playerState = PlayerState.paused;
      _stateController.add(PlayerState.paused);
    }
  }

  Future<void> pause() async {
    await _player.pause();
    if (_position.inSeconds > 2) {
      await _saveCurrentAudioPosition(_position.inSeconds);
    }
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> stop() async {
    if (_position.inSeconds > 2) {
      await _saveCurrentAudioPosition(_position.inSeconds);
    }
    await _player.stop();
    _currentAudio = null;
    _audioController.add(null);
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
    await _saveCurrentAudioPosition(position.inSeconds);
  }

  void dispose() {
    _player.dispose();
    _stateController.close();
    _positionController.close();
    _durationController.close();
    _audioController.close();
  }
}
