import 'package:flutter/material.dart';

import '../../core/settings/app_settings.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/kid_ui.dart';

/// Switches for the music and the button sounds, each on its own.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    return Scaffold(
      backgroundColor: AppColors.board,
      appBar: AppBar(
        backgroundColor: AppColors.appBar,
        surfaceTintColor: Colors.transparent,
        shape: const Border(bottom: BorderSide(color: AppColors.ink, width: 3)),
        leadingWidth: 60,
        leading: Center(
          child: RoundSticker(
            icon: Icons.arrow_back_rounded,
            color: AppColors.back,
            tooltip: 'Back',
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
        title: Text('Settings', style: kidText(22, weight: 700)),
      ),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SwitchRow(
              icon: Icons.music_note_rounded,
              iconColor: AppColors.chipLines,
              label: 'Music',
              on: settings.musicOn,
              onChanged: settings.setMusicOn,
            ),
            const SizedBox(height: 16),
            _SwitchRow(
              icon: Icons.touch_app_rounded,
              iconColor: AppColors.chipGaps,
              label: 'Button sounds',
              on: settings.sfxOn,
              onChanged: settings.setSfxOn,
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.on,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final bool on;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.ink, width: 3),
        boxShadow: const [BoxShadow(color: AppColors.ink, offset: Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconColor,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.ink, width: 3),
            ),
            child: Icon(on ? icon : Icons.volume_off_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: kidText(22, weight: 700))),
          StickerChoice(
            label: on ? 'On' : 'Off',
            selected: on,
            color: AppColors.go,
            onTap: () => onChanged(!on),
          ),
        ],
      ),
    );
  }
}
