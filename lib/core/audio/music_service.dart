import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

import '../settings/app_settings.dart';
import 'audio_setup.dart';

/// Looping background music for the whole app. Follows the music switch in
/// the settings and pauses while the app is in the background.
///
/// Track: "Happy Clappy Loop" by OwlishMedia (CC0), opengameart.org.
class MusicService with WidgetsBindingObserver {
  MusicService._();

  static final MusicService instance = MusicService._();

  static const _asset = 'audio/happy_clappy_loop.wav';
  static const _volume = 0.35;

  /// How long the end of one lap overlaps the start of the next one.
  static const _crossfade = Duration(milliseconds: 1200);

  // Two players take turns: looping a single player always leaves a small
  // gap on iOS (it seeks back to the start), so the next lap is started on
  // the other player while the current one fades out.
  final List<AudioPlayer> _players = [AudioPlayer(), AudioPlayer()];
  final List<StreamSubscription<void>> _subscriptions = [];
  Duration? _length;
  int _current = 0;
  bool _handingOver = false;
  Timer? _fade;
  bool _started = false;

  bool get _muted => !AppSettings.instance.musicOn;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    await AppSettings.instance.load();
    AppSettings.instance.addListener(_onSettingsChanged);
    try {
      for (var i = 0; i < _players.length; i++) {
        final player = _players[i];
        await prepareMixingPlayer(player);
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setVolume(0);
        _subscriptions.addAll([
          player.onPositionChanged.listen((p) => _onPosition(i, p)),
          // Some devices only report the length once playback has started.
          player.onDurationChanged.listen((d) {
            if (d > _crossfade * 2) _length = d;
          }),
          // Safety net: if the lap ended before a handover could start (length
          // unknown), start the next lap right away instead of going silent.
          player.onPlayerComplete.listen((_) => _onComplete(i)),
        ]);
      }
      _wasMuted = _muted;
      if (!_muted) await _begin();
    } catch (_) {
      // Music is a nicety: never let an audio problem break the app.
    }
  }

  Future<void> _begin() async {
    _handingOver = false;
    final player = _players[_current];
    await player.setVolume(_volume);
    await player.play(AssetSource(_asset));
  }

  void _onComplete(int index) {
    if (_muted || index != _current || _handingOver) return;
    _handingOver = true;
    _handOver();
  }

  void _onPosition(int index, Duration position) {
    final length = _length;
    if (_muted || length == null || index != _current || _handingOver) return;
    if (position < length - _crossfade) return;
    _handingOver = true;
    _handOver();
  }

  Future<void> _handOver() async {
    final outgoing = _players[_current];
    _current = 1 - _current;
    final incoming = _players[_current];
    try {
      await incoming.setVolume(0);
      await incoming.play(AssetSource(_asset));
    } catch (_) {}
    const step = Duration(milliseconds: 40);
    final steps = _crossfade.inMilliseconds ~/ step.inMilliseconds;
    var n = 0;
    _fade?.cancel();
    _fade = Timer.periodic(step, (timer) {
      n++;
      final t = (n / steps).clamp(0.0, 1.0);
      // Equal-power curves keep the loudness steady through the overlap.
      incoming.setVolume(_volume * math.sin(t * math.pi / 2));
      outgoing.setVolume(_volume * math.cos(t * math.pi / 2));
      if (t >= 1) {
        timer.cancel();
        outgoing.stop();
        _handingOver = false;
      }
    });
  }

  bool _wasMuted = false;

  Future<void> _onSettingsChanged() async {
    if (_muted == _wasMuted) return;
    _wasMuted = _muted;
    try {
      _fade?.cancel();
      if (_muted) {
        for (final p in _players) {
          await p.pause();
        }
      } else if (_players[_current].state == PlayerState.paused) {
        await _players[_current].setVolume(_volume);
        await _players[_current].resume();
        _handingOver = false;
      } else {
        await _begin();
      }
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_muted) return;
    final player = _players[_current];
    if (state == AppLifecycleState.resumed) {
      player.setVolume(_volume);
      player.resume().catchError((_) {});
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _fade?.cancel();
      _handingOver = false;
      for (final p in _players) {
        p.pause().catchError((_) {});
      }
    }
  }
}
