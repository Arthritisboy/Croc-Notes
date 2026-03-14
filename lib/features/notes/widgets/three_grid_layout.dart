import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/notes_viewmodel.dart';
import 'title_grid.dart';
import 'right_notepad.dart';
import 'bottom_notepad.dart';

class ThreeGridLayout extends StatelessWidget {
  const ThreeGridLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotesViewModel>(
      builder: (context, viewModel, child) {
        final selectedTab = viewModel.selectedTab;

        if (selectedTab == null) {
          return const Center(child: Text('Select a tab to view'));
        }

        final category = viewModel.categories.firstWhere(
          (c) => c.id == selectedTab.categoryId,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tab header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: category.color.withOpacity(0.1),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: category.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${category.name} / ${selectedTab.name}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      selectedTab.isPinned
                          ? Icons.push_pin
                          : Icons.push_pin_outlined,
                      color: selectedTab.isPinned ? Colors.amber : Colors.grey,
                    ),
                    onPressed: () => viewModel.toggleTabPinned(selectedTab.id),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // CORRECT LAYOUT: Left | Right / Bottom full width
            Expanded(
              child: Column(
                children: [
                  // Top row: Left grid + Right grid (side by side)
                  Expanded(
                    flex: 1,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left grid - Checklist
                        Expanded(
                          flex: 1,
                          child: TitleGrid(
                            tab: selectedTab,
                            categoryColor: category.color,
                          ),
                        ),

                        // Right grid - Notepad with rich text
                        Expanded(
                          flex: 1,
                          child: RightNotepad(
                            tab: selectedTab,
                            categoryColor: category.color,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom row: Bottom notepad (full width)
                  Expanded(
                    flex: 1,
                    child: BottomNotepad(
                      tab: selectedTab,
                      categoryColor: category.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
