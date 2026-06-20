import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../data/local_storage.dart';

class AudioManager {
  static final AudioPlayer _bgPlayer = AudioPlayer();
  static AudioPool? _clickPool;
  static Future<void>? _initialization;
  static _AudioLifecycleObserver? _lifecycleObserver;

  static final AudioContext _backgroundContext = AudioContext(
    android: const AudioContextAndroid(
      stayAwake: true,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.gain,
    ),
  );

  // Short game sounds must not take focus away from the background player.
  static final AudioContext _soundEffectContext = AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none,
    ),
  );

  static bool _isMuted = false;
  static bool _isPlayingBackground = false;

  static Future<void> init() {
    return _initialization ??= _initialize();
  }

  static Future<void> _initialize() async {
    _lifecycleObserver ??= _AudioLifecycleObserver();
    WidgetsBinding.instance.addObserver(_lifecycleObserver!);

    try {
      await _bgPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await _bgPlayer.setAudioContext(_backgroundContext);
      await _bgPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgPlayer.setVolume(0.5);

      _clickPool = await AudioPool.create(
        source: AssetSource('audio/click.wav'),
        minPlayers: 2,
        maxPlayers: 4,
        playerMode: PlayerMode.mediaPlayer,
        audioContext: _soundEffectContext,
      );
    } catch (e) {
      // Audio plugins are unavailable in widget tests and unsupported targets.
      debugPrint('Audio initialization skipped: $e');
    }
  }

  static void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      _bgPlayer.pause();
    } else {
      if (_isPlayingBackground) _bgPlayer.resume();
    }
  }

  static bool get _vibrationEnabled =>
      LocalStorage.settingsBox.get('main')?.vibrationEnabled ?? true;

  static void selectionHaptic() {
    if (_vibrationEnabled) HapticFeedback.selectionClick();
  }

  static void lightHaptic() {
    if (_vibrationEnabled) HapticFeedback.lightImpact();
  }

  static void heavyHaptic() {
    if (_vibrationEnabled) HapticFeedback.heavyImpact();
  }

  static Future<void> playBackground() async {
    final settings = LocalStorage.settingsBox.get('main');
    if (settings != null && !settings.musicEnabled) {
      stopBackground();
      return;
    }
    if (_isMuted) return;
    if (_isPlayingBackground) return; // Prevent restarting if already playing

    try {
      _isPlayingBackground = true;
      await init();
      await _bgPlayer.play(AssetSource('audio/bg.wav'));
    } catch (e) {
      debugPrint('Error playing game music: $e');
      _isPlayingBackground = false;
    }
  }

  static Future<void> playHomeMusic() async {
    // Alias to playBackground so we just use the same track everywhere
    await playBackground();
  }

  static Future<void> stopBackground() async {
    if (_isPlayingBackground) {
      await _bgPlayer.stop();
      _isPlayingBackground = false;
    }
  }

  static Future<void> _pauseForLifecycle() async {
    if (!_isPlayingBackground) return;
    await _bgPlayer.pause();
  }

  static Future<void> _resumeFromLifecycle() async {
    final settings = LocalStorage.settingsBox.get('main');
    if (!_isPlayingBackground ||
        _isMuted ||
        (settings != null && !settings.musicEnabled)) {
      return;
    }
    await _bgPlayer.resume();
  }

  static Future<void> playClick() async {
    final settings = LocalStorage.settingsBox.get('main');
    selectionHaptic();
    if (settings != null && !settings.soundEnabled) return;
    if (_isMuted) return;
    try {
      await init();
      final pool = _clickPool;
      if (pool != null) {
        await pool.start();
        return;
      }

      final player = AudioPlayer();
      await player.setAudioContext(_soundEffectContext);
      await player.play(AssetSource('audio/click.wav'));
      player.onPlayerComplete.listen((_) {
        player.dispose();
      });
    } catch (e) {
      debugPrint('Error playing click: $e');
    }
  }

  static Future<void> playInstrument(int index) async {
    final settings = LocalStorage.settingsBox.get('main');
    lightHaptic();
    if (settings != null && !settings.soundEnabled) return;
    if (_isMuted) return;
    try {
      final player = AudioPlayer();
      final baseIndex = index % 4;
      final pitchShiftMultiplier =
          1.0 + ((index ~/ 4) * 0.3); // Pitch up for new instruments.

      await player.setAudioContext(_soundEffectContext);
      await player.setPlaybackRate(pitchShiftMultiplier);
      await player.play(AssetSource('audio/pad_$baseIndex.wav'), volume: 1.0);
      player.onPlayerComplete.listen((_) {
        player.dispose();
      });
    } catch (e) {
      debugPrint('Error playing instrument $index: $e');
    }
  }
}

class _AudioLifecycleObserver with WidgetsBindingObserver {
  bool _pausedByLifecycle = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_pausedByLifecycle) {
          _pausedByLifecycle = false;
          AudioManager._resumeFromLifecycle();
        }
        return;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        if (!_pausedByLifecycle) {
          _pausedByLifecycle = true;
          AudioManager._pauseForLifecycle();
        }
        return;
    }
  }
}
