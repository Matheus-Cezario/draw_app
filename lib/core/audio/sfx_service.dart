import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../settings/app_settings.dart';
import 'audio_setup.dart';

/// Short interface sounds. Can be switched off in the settings, apart from the
/// music.
class SfxService {
  SfxService._();

  static final SfxService instance = SfxService._();

  static const _tap = 'audio/tap.wav';
  static const _voices = 4;

  // A few players take turns so quick taps can overlap. The sound is loaded
  // into each one once and only restarted afterwards: loading it again on
  // every tap makes Android stop playing after a handful of clicks.
  final List<AudioPlayer> _pool = [];
  Future<void>? _ready;
  int _next = 0;

  Future<void> _prepare() async {
    for (var i = 0; i < _voices; i++) {
      final player = AudioPlayer();
      await prepareMixingPlayer(player);
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(0.6);
      await player.setSource(AssetSource(_tap));
      _pool.add(player);
    }
  }

  void tap() {
    if (!AppSettings.instance.sfxOn) return;
    _play().catchError((_) {});
  }

  Future<void> _play() async {
    await (_ready ??= _prepare());
    final player = _pool[_next];
    _next = (_next + 1) % _pool.length;
    try {
      await player.seek(Duration.zero);
      await player.resume();
    } catch (_) {
      // The player got into a bad state: load the sound again.
      await player.play(AssetSource(_tap));
    }
  }
}

/// Wraps a tap handler so it also plays the click sound. A null handler stays
/// null, so disabled buttons stay silent.
VoidCallback? withTapSound(VoidCallback? onTap) {
  if (onTap == null) return null;
  return () {
    SfxService.instance.tap();
    onTap();
  };
}
