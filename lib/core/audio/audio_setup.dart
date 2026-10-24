import 'package:audioplayers/audioplayers.dart';

/// Audio settings every player of the app uses: sounds mix with each other
/// (and with other apps) instead of taking the audio focus. With the default
/// focus handling Android pauses a player as soon as another one starts,
/// which stopped the music at every click and at every lap of the loop.
final AudioContext mixingAudioContext =
    AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build();

/// Applies [mixingAudioContext] to [player]. Call it before the first play.
Future<void> prepareMixingPlayer(AudioPlayer player) =>
    player.setAudioContext(mixingAudioContext);
