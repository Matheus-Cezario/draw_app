import 'package:flutter/material.dart';

import 'app.dart';
import 'core/storage/project_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ColorFunApp(repository: ProjectRepository()));
}
