import 'package:flutter/material.dart';
import 'app_colors.dart';
import '../audio/sfx_service.dart';


TextStyle kidText(double size, {double weight = 600, Color color = AppColors.ink}) =>
    TextStyle(
      fontFamily: 'Fredoka',
      fontSize: size,
      color: color,
      fontVariations: [FontVariation('wght', weight)],
    );

/// A sticker-style option button, used instead of sliders and switches.
class StickerChoice extends StatelessWidget {
  const StickerChoice({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = AppColors.appBar,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: withTapSound(onTap),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.ink, width: selected ? 3.5 : 2.5),
          boxShadow: [
            BoxShadow(color: AppColors.ink, offset: Offset(0, selected ? 4 : 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 22, color: AppColors.ink),
              const SizedBox(width: 6),
            ],
            Text(label, style: kidText(17, weight: 600)),
          ],
        ),
      ),
    );
  }
}

/// Round sticker button with an icon (back, close, ...).
class RoundSticker extends StatelessWidget {
  const RoundSticker({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
    this.tooltip,
    this.size = 40,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: withTapSound(onTap),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: enabled ? color : AppColors.disabled,
            border: Border.all(color: AppColors.ink, width: 3),
            boxShadow: enabled
                ? const [BoxShadow(color: AppColors.ink, offset: Offset(0, 3))]
                : null,
          ),
          child: Icon(icon, size: size * 0.56, color: Colors.white),
        ),
      ),
    );
  }
}
