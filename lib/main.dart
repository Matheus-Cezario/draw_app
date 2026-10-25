import 'package:flutter/material.dart';

import 'app.dart';
import 'core/ads/ad_service.dart';
import 'core/audio/music_service.dart';
import 'core/billing/entitlement_service.dart';
import 'core/storage/project_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MusicService.instance.start();
  EntitlementService.instance.init();
  AdService.instance.init();
  runApp(ColorFunApp(repository: ProjectRepository()));
}
