// lib/features/notes/views/desktop_main_view.dart
import 'package:flutter/material.dart';
import 'package:modular_journal/features/notes/widgets/window_controls.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../viewmodels/notes_viewmodel.dart';
import '../widgets/left_sidebar.dart';
import '../widgets/three_grid_layout.dart';

class DesktopMainView extends StatelessWidget {
  const DesktopMainView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotesViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading your journal...'),
                ],
              ),
            ),
          );
        }

        if (viewModel.error != null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading data: ${viewModel.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      viewModel.loadData();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: Column(
            children: [
              // Custom title bar with window controls
              Container(
                height: 40,
                color: Colors.transparent,
                child: Row(
                  children: [
                    // Draggable area for window movement
                    Expanded(
                      child: GestureDetector(
                        onPanStart: (_) {
                          windowManager.startDragging();
                        },
                        behavior: HitTestBehavior.translucent,
                        child: Container(
                          color: Colors.transparent,
                          child: const Padding(
                            padding: EdgeInsets.only(left: 16.0),
                            child: Row(
                              children: [
                                Icon(Icons.note_alt, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Croc Notes',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Window controls
                    const Padding(
                      padding: EdgeInsets.only(right: 16.0),
                      child: WindowControls(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),
              // Main content
              Expanded(
                child: const Row(
                  children: [
                    SizedBox(width: 280, child: LeftSidebar()),
                    VerticalDivider(width: 1, thickness: 1),
                    Expanded(child: ThreeGridLayout()),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
