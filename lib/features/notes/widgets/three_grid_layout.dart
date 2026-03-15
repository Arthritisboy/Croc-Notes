import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/notes_viewmodel.dart';
import 'title_grid.dart';
import 'right_notepad.dart';
import 'bottom_notepad.dart';
import 'dialogs/category_dialog.dart';
import 'dialogs/tab_dialog.dart';

class ThreeGridLayout extends StatelessWidget {
  const ThreeGridLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotesViewModel>(
      builder: (context, viewModel, child) {
        // Store in local variable for type safety
        final selectedTab = viewModel.selectedTab;
        final categories = viewModel.categories;
        final selectedCategory = viewModel.selectedCategory;

        // EMPTY STATE - No categories at all
        if (categories.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Main illustration
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.deepPurple.withOpacity(0.2),
                            Colors.purple.withOpacity(0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.note_alt_outlined,
                            size: 80,
                            color: Colors.deepPurple,
                          ),
                          Positioned(
                            bottom: 30,
                            right: 40,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add,
                                size: 20,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Welcome message
                    Text(
                      'Welcome to Croc Notes! 🐊',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      'Your Thoughts, Organized.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Feature highlights
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade800),
                      ),
                      child: Column(
                        children: [
                          _buildFeatureRow(
                            icon: Icons.category,
                            color: Colors.blue,
                            title: 'Categories',
                            description: 'Organize your notes into groups',
                          ),
                          const SizedBox(height: 16),
                          _buildFeatureRow(
                            icon: Icons.tab,
                            color: Colors.orange,
                            title: 'Tabs',
                            description: 'Create multiple tabs per category',
                          ),
                          const SizedBox(height: 16),
                          _buildFeatureRow(
                            icon: Icons.check_box,
                            color: Colors.green,
                            title: 'Checklists',
                            description: 'Track tasks with checkboxes',
                          ),
                          const SizedBox(height: 16),
                          _buildFeatureRow(
                            icon: Icons.timer,
                            color: Colors.red,
                            title: 'Timers',
                            description: 'Set alarms and get notifications',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Prominent "Create Category" button
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await showDialog<Map<String, dynamic>>(
                          context: context,
                          builder: (context) => const CategoryDialog.create(),
                        );
                        if (result != null) {
                          await viewModel.createCategory(
                            result['name'],
                            result['color'],
                          );
                        }
                      },
                      icon: const Icon(Icons.add, size: 24),
                      label: const Text(
                        'Create Your First Category',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Helpful tip
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade800),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Colors.amber.shade300,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            '💡 Start by creating a category to organize your notes',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // EMPTY STATE - Categories exist but no tabs
        if (categories.isNotEmpty && selectedTab == null) {
          return Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Main illustration
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.orange.withOpacity(0.2),
                            Colors.amber.withOpacity(0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.tab_unselected,
                            size: 70,
                            color: Colors.orange,
                          ),
                          if (selectedCategory != null)
                            Positioned(
                              bottom: 25,
                              right: 35,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: selectedCategory.color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Message
                    Text(
                      'Ready for your first tab! 📝',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                    ),
                    const SizedBox(height: 8),

                    // Show which category we're in
                    if (selectedCategory != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selectedCategory.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: selectedCategory.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Selected: ${selectedCategory.name}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // What you can do with tabs
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade800),
                      ),
                      child: Column(
                        children: [
                          _buildTabFeatureRow(
                            icon: Icons.note,
                            color: Colors.blue,
                            title: 'Notes',
                            description:
                                'Write rich text notes with formatting',
                          ),
                          const SizedBox(height: 12),
                          _buildTabFeatureRow(
                            icon: Icons.checklist,
                            color: Colors.green,
                            title: 'Checklists',
                            description: 'Create todo lists with checkboxes',
                          ),
                          const SizedBox(height: 12),
                          _buildTabFeatureRow(
                            icon: Icons.timer,
                            color: Colors.red,
                            title: 'Timers',
                            description: 'Set alarms and track time',
                          ),
                          const SizedBox(height: 12),
                          _buildTabFeatureRow(
                            icon: Icons.image,
                            color: Colors.purple,
                            title: 'Images',
                            description: 'Paste or insert images',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Create tab button
                    if (selectedCategory != null)
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await showDialog<Map<String, dynamic>>(
                            context: context,
                            builder: (context) => const TabDialog.create(),
                          );
                          if (result != null) {
                            await viewModel.createTab(
                              selectedCategory.id,
                              result['name'],
                              result['color'],
                            );
                          }
                        },
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text(
                          'Create Your First Tab',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedCategory.color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Option to create another category
                    TextButton.icon(
                      onPressed: () async {
                        final result = await showDialog<Map<String, dynamic>>(
                          context: context,
                          builder: (context) => const CategoryDialog.create(),
                        );
                        if (result != null) {
                          await viewModel.createCategory(
                            result['name'],
                            result['color'],
                          );
                        }
                      },
                      icon: const Icon(Icons.folder_outlined, size: 18),
                      label: const Text('Or create another category'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // NORMAL STATE - We have a selected tab
        if (selectedTab == null) {
          return const SizedBox.shrink();
        }

        final category = categories.firstWhere(
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

            // Three-grid layout
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

  Widget _buildFeatureRow({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabFeatureRow({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              Text(
                description,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
