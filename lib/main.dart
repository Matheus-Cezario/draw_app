import 'package:flutter/material.dart';

import 'app.dart';
import 'core/audio/music_service.dart';
import 'core/storage/project_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MusicService.instance.start();
  runApp(ColorFunApp(repository: ProjectRepository()));
}
