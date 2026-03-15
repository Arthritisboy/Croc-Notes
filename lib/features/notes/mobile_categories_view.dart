// lib/features/notes/widgets/mobile/mobile_categories_view.dart
import 'package:flutter/material.dart';
import 'package:modular_journal/features/notes/models/category.dart';
import 'package:modular_journal/features/notes/models/tab.dart';
import 'package:modular_journal/features/notes/viewmodels/notes_viewmodel.dart';
import 'package:modular_journal/features/notes/widgets/dialogs/category_dialog.dart';
import 'package:modular_journal/features/notes/widgets/dialogs/tab_dialog.dart';
import 'package:modular_journal/features/notes/widgets/mobile/mobile_tab_detail_view.dart';
import 'package:provider/provider.dart';

class MobileCategoriesView extends StatelessWidget {
  const MobileCategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotesViewModel>(
      builder: (context, viewModel, child) {
        return Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: (query) => viewModel.updateSearchQuery(query),
                decoration: InputDecoration(
                  hintText: 'Search categories...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade900,
                ),
              ),
            ),

            // Pinned tabs section
            if (viewModel.allPinnedTabs.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Icon(Icons.push_pin, size: 16, color: Colors.amber),
                    const SizedBox(width: 8),
                    const Text(
                      'Pinned Tabs',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: viewModel.allPinnedTabs.length,
                  itemBuilder: (context, index) {
                    final tab = viewModel.allPinnedTabs[index];
                    final category = viewModel.categories.firstWhere(
                      (c) => c.id == tab.categoryId,
                    );
                    return _buildPinnedTabCard(
                      context,
                      viewModel,
                      tab,
                      category,
                    );
                  },
                ),
              ),
              const Divider(height: 24),
            ],

            // Categories list
            Expanded(
              child: viewModel.filteredCategories.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 48,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No categories found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            viewModel.isSearching
                                ? 'Try a different search term'
                                : 'Tap + to create your first category',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: viewModel.filteredCategories.length,
                      itemBuilder: (context, index) {
                        final category = viewModel.filteredCategories[index];
                        return _buildCategoryCard(context, viewModel, category);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPinnedTabCard(
    BuildContext context,
    NotesViewModel viewModel,
    ContentTab tab,
    Category category,
  ) {
    return GestureDetector(
      onTap: () {
        viewModel.selectTab(tab.id);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                MobileTabDetailView(tab: tab, category: category),
          ),
        );
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: category.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: category.color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: category.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              tab.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Icon(Icons.push_pin, size: 12, color: Colors.amber),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    NotesViewModel viewModel,
    Category category,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          ListTile(
            leading: CircleAvatar(backgroundColor: category.color, radius: 12),
            title: Text(
              category.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${category.tabs.length} tabs'),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                if (value == 'edit') {
                  final result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (context) => CategoryDialog.edit(
                      initialName: category.name,
                      initialColor: category.color,
                    ),
                  );
                  if (result != null) {
                    await viewModel.updateCategory(
                      category.id,
                      result['name'],
                      result['color'],
                    );
                  }
                } else if (value == 'delete') {
                  await viewModel.deleteCategory(context, category.id);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tabs
          ...category.tabs.map(
            (tab) => ListTile(
              leading: Icon(Icons.circle, size: 8, color: tab.color),
              title: Text(tab.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (tab.isPinned)
                    const Icon(Icons.push_pin, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () {
                viewModel.selectTab(tab.id);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MobileTabDetailView(tab: tab, category: category),
                  ),
                );
              },
            ),
          ),

          // Add tab button
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () async {
                final result = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (context) => const TabDialog.create(),
                );
                if (result != null) {
                  await viewModel.createTab(
                    category.id,
                    result['name'],
                    result['color'],
                  );
                }
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Tab'),
              style: OutlinedButton.styleFrom(
                foregroundColor: category.color,
                side: BorderSide(color: category.color.withOpacity(0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
