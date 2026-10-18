import 'package:flutter/material.dart';

import '../../core/storage/project_repository.dart';
import 'animal_magnet.dart';

const Color kInk = Color(0xFF2B2350);

/// A drawing shown as a sheet of paper held to the board by an animal magnet.
/// Every sheet has its own tilt and animal, picked from the project id.
class PaperCard extends StatelessWidget {
  const PaperCard({
    super.key,
    required this.project,
    required this.onTap,
    required this.onLongPress,
  });

  final ProjectSummary project;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: tiltFor(project.id),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Positioned.fill(
              top: 22,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFEF9),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 8,
                      offset: Offset(2, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 34, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0x1F000000)),
                          ),
                          child: project.thumbnail == null
                              ? const SizedBox()
                              : Image.file(
                                  project.thumbnail!,
                                  fit: BoxFit.contain,
                                  key: ValueKey(project.modified),
                                ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        project.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 17,
                          color: kInk,
                          fontVariations: [FontVariation('wght', 600)],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              child: AnimalMagnet(animal: animalFor(project.id), size: 60),
            ),
          ],
        ),
      ),
    );
  }
}
