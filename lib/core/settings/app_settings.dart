import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// User settings that survive restarts. Sound is split in two switches:
/// the background music and the little click sounds of the buttons.
class AppSettings extends ChangeNotifier {
  AppSettings._();

  static final AppSettings instance = AppSettings._();

  bool _musicOn = true;
  bool _sfxOn = true;
  bool _loaded = false;

  bool get musicOn => _musicOn;
  bool get sfxOn => _sfxOn;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final file = await _file();
      if (file.existsSync()) {
        final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        _musicOn = json['musicOn'] as bool? ?? true;
        _sfxOn = json['sfxOn'] as bool? ?? true;
        notifyListeners();
      }
    } catch (_) {
      // Fall back to the defaults.
    }
  }

  Future<void> setMusicOn(bool value) async {
    if (value == _musicOn) return;
    _musicOn = value;
    notifyListeners();
    await _save();
  }

  Future<void> setSfxOn(bool value) async {
    if (value == _sfxOn) return;
    _sfxOn = value;
    notifyListeners();
    await _save();
  }

  Future<File> _file() async =>
      File('${(await getApplicationSupportDirectory()).path}/settings.json');

  Future<void> _save() async {
    try {
      await (await _file()).writeAsString(
        jsonEncode({'musicOn': _musicOn, 'sfxOn': _sfxOn}),
      );
    } catch (_) {}
  }
}
