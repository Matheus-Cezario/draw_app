import 'package:flutter/material.dart';

import '../../core/storage/project_repository.dart';
import 'animal_magnet.dart';
import '../../core/ui/app_colors.dart';


/// A drawing shown as a sheet of paper held to the board by an animal magnet.
/// Every sheet has its own tilt and animal, picked from the project id.
class PaperCard extends StatelessWidget {
  const PaperCard({
    super.key,
    required this.project,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
  });

  final ProjectSummary project;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;

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
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
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
                            border: Border.all(color: AppColors.hairline),
                          ),
                          child: project.thumbnail == null
                              ? const SizedBox()
                              : Image.memory(
                                  project.thumbnail!,
                                  fit: BoxFit.contain,
                                  gaplessPlayback: true,
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
                          color: AppColors.ink,
                          fontVariations: [FontVariation('wght', 600)],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 30,
              right: 4,
              child: Tooltip(
                message: 'Delete',
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.ink, width: 2.5),
                    ),
                    child: const Icon(Icons.delete_rounded, size: 19, color: Colors.white),
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
