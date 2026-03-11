import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/notes_viewmodel.dart';
import '../widgets/left_sidebar.dart';
import '../widgets/three_grid_layout.dart';

class DesktopMainView extends StatelessWidget {
  const DesktopMainView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<NotesViewModel>(
        builder: (context, viewModel, child) {
          return const Row(
            children: [
              // Left Sidebar (fixed width)
              SizedBox(width: 280, child: LeftSidebar()),

              // Vertical divider between sidebar and content
              VerticalDivider(width: 1, thickness: 1),

              // Main content area (expands to fill remaining space)
              Expanded(child: ThreeGridLayout()),
            ],
          );
        },
      ),
    );
  }
}
