// lib/shared/widgets/exit_options_dialog.dart
import 'package:flutter/material.dart';
import 'package:modular_journal/data/services/timer_service.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';

class ExitOptionsDialog extends StatelessWidget {
  final TimerService timerService;

  const ExitOptionsDialog({super.key, required this.timerService});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).dialogBackgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.exit_to_app,
                color: Colors.deepPurple,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              'Exit Options',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              'What would you like to do?',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),

            // Minimize to tray option
            _buildOption(
              context: context,
              icon: Icons.arrow_downward,
              color: Colors.amber,
              title: 'Minimize to System Tray',
              description: 'Keep running in the background',
              onTap: () async {
                Navigator.pop(context);
                await windowManager.hide();
              },
            ),
            const SizedBox(height: 12),

            // Exit completely option
            _buildOption(
              context: context,
              icon: Icons.power_settings_new,
              color: Colors.red,
              title: 'Exit Completely',
              description: 'Close the application',
              onTap: () async {
                Navigator.pop(context);
                timerService.dispose();
                await trayManager.destroy();
                await windowManager.destroy();
              },
            ),
            const SizedBox(height: 12),

            // Cancel option
            _buildOption(
              context: context,
              icon: Icons.cancel,
              color: Colors.grey,
              title: 'Cancel',
              description: 'Return to the app',
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade800),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade900.withOpacity(0.3),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
