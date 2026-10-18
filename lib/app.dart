import 'package:flutter/material.dart';

import 'core/storage/project_repository.dart';
import 'features/gallery/gallery_page.dart';

class DrawApp extends StatelessWidget {
  const DrawApp({super.key, required this.repository});

  final ProjectRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Draw App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: GalleryPage(repository: repository),
    );
  }
}
