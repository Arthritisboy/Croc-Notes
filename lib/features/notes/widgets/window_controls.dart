// lib/shared/widgets/window_controls.dart
import 'package:flutter/material.dart';
import 'package:modular_journal/core/navigation.dart';
import 'package:modular_journal/features/notes/views/settings_view.dart';
import 'package:modular_journal/features/notes/widgets/dialogs/exit_options_dialog.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:modular_journal/main.dart' show timerService;

class WindowControls extends StatefulWidget {
  final Color color;
  final double iconSize;

  const WindowControls({
    super.key,
    this.color = Colors.grey,
    this.iconSize = 16,
  });

  @override
  State<WindowControls> createState() => _WindowControlsState();
}

class _WindowControlsState extends State<WindowControls> {
  bool _isMaximized = false;
  bool _isHoveringClose = false;
  bool _isHoveringMinimize = false;
  bool _isHoveringMaximize = false;
  bool _isHoveringSettings = false; // Add this

  @override
  void initState() {
    super.initState();
    _checkMaximized();

    // Listen for window events to update maximize state
    windowManager.addListener(_WindowStateListener(this));
  }

  Future<void> _checkMaximized() async {
    final maximized = await windowManager.isMaximized();
    if (mounted && _isMaximized != maximized) {
      setState(() {
        _isMaximized = maximized;
      });
    }
  }

  @override
  void dispose() {
    // Remove listener (would need to implement properly)
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Settings button - ADD THIS FIRST (next to title)
        _buildControlButton(
          icon: Icons.settings,
          color: Colors.blue,
          isHovering: _isHoveringSettings,
          onHover: (value) => setState(() => _isHoveringSettings = value),
          onPressed: () {
            debugPrint('Settings button clicked');
            navigatorKey.currentState?.push(
              MaterialPageRoute(builder: (context) => const SettingsView()),
            );
          },
          tooltip: 'Settings',
        ),
        const SizedBox(width: 8),

        // Minimize button
        _buildControlButton(
          icon: Icons.remove,
          color: Colors.amber,
          isHovering: _isHoveringMinimize,
          onHover: (value) => setState(() => _isHoveringMinimize = value),
          onPressed: () async {
            debugPrint('Minimize button clicked - hiding to tray');
            await windowManager.hide();
          },
          tooltip: 'Minimize to tray',
        ),
        const SizedBox(width: 8),

        // Maximize/Restore button
        _buildControlButton(
          icon: _isMaximized ? Icons.filter_none : Icons.crop_square,
          color: Colors.green,
          isHovering: _isHoveringMaximize,
          onHover: (value) => setState(() => _isHoveringMaximize = value),
          onPressed: () async {
            debugPrint('Maximize/Restore button clicked');
            if (await windowManager.isMaximized()) {
              await windowManager.unmaximize();
            } else {
              await windowManager.maximize();
            }
            await _checkMaximized();
          },
          tooltip: _isMaximized ? 'Restore' : 'Maximize',
        ),
        const SizedBox(width: 8),

        // Close button
        _buildControlButton(
          icon: Icons.close,
          color: Colors.red,
          isHovering: _isHoveringClose,
          onHover: (value) => setState(() => _isHoveringClose = value),
          onPressed: () async {
            debugPrint('Close button clicked - showing exit options dialog');
            _showExitOptionsDialog(context);
          },
          tooltip: 'Close options',
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required bool isHovering,
    required ValueChanged<bool> onHover,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isHovering ? color.withOpacity(0.2) : Colors.transparent,
              border: Border.all(
                color: isHovering ? color : color.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              size: widget.iconSize,
              color: isHovering ? color : color.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }

  void _showExitOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ExitOptionsDialog(timerService: timerService),
    );
  }

  void _quitApp() async {
    debugPrint('Quitting app from window controls');
    timerService.dispose();
    await trayManager.destroy();
    await windowManager.destroy();
  }
}

// Simple window state listener
class _WindowStateListener implements WindowListener {
  final _WindowControlsState state;

  _WindowStateListener(this.state);

  @override
  void onWindowMaximize() {
    state._checkMaximized();
  }

  @override
  void onWindowUnmaximize() {
    state._checkMaximized();
  }

  @override
  void onWindowRestore() {
    state._checkMaximized();
  }

  // Required overrides with empty implementations
  @override
  void onWindowClose() {}
  @override
  void onWindowFocus() {}
  @override
  void onWindowBlur() {}
  @override
  void onWindowMinimize() {}
  @override
  void onWindowResize() {}
  @override
  void onWindowResized() {}
  @override
  void onWindowMove() {}
  @override
  void onWindowMoved() {}
  @override
  void onWindowEnterFullScreen() {}
  @override
  void onWindowLeaveFullScreen() {}
  @override
  void onWindowDocked() {}
  @override
  void onWindowUndocked() {}
  @override
  void onWindowEvent(String eventName) {}
}
