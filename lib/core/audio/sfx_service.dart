import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../settings/app_settings.dart';

/// Short interface sounds. Can be switched off in the settings, apart from the music.
class SfxService {
  SfxService._();

  static final SfxService instance = SfxService._();

  static const _tap = 'audio/tap.wav';

  // A few players take turns so quick taps can overlap.
  final List<AudioPlayer> _pool = [
    for (var i = 0; i < 4; i++) AudioPlayer()..setPlayerMode(PlayerMode.lowLatency),
  ];
  int _next = 0;

  void tap() {
    if (!AppSettings.instance.sfxOn) return;
    final player = _pool[_next];
    _next = (_next + 1) % _pool.length;
    player.play(AssetSource(_tap), volume: 0.6).catchError((_) {});
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
