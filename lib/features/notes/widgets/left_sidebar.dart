import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/notes_viewmodel.dart';
import '../models/category.dart';
import '../models/tab.dart';
import 'dialogs/category_dialog.dart';
import 'dialogs/tab_dialog.dart';

class LeftSidebar extends StatelessWidget {
  const LeftSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotesViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          child: Column(
            children: [
              // TOP SECTION - Focused Category with its tabs
              _buildFocusedCategory(context, viewModel),

              const Divider(height: 1, thickness: 1),

              // BOTTOM SECTION - All categories with toggle
              Expanded(child: _buildBottomSection(context, viewModel)),
            ],
          ),
        );
      },
    );
  }

  // TOP SECTION: Shows the currently selected category and its tabs
  Widget _buildFocusedCategory(BuildContext context, NotesViewModel viewModel) {
    final selectedCategory = viewModel.selectedCategory;

    if (selectedCategory == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: selectedCategory.color.withOpacity(0.1),
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Category header with color picker and ellipsis
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                // Color circle - clickable for editing
                InkWell(
                  onTap: () async {
                    final result = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder: (context) => CategoryDialog.edit(
                        initialName: selectedCategory.name,
                        initialColor: selectedCategory.color,
                      ),
                    );
                    if (result != null) {
                      await viewModel.updateCategory(
                        selectedCategory.id,
                        result['name'],
                        result['color'],
                      );
                    }
                  },
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: selectedCategory.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedCategory.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  '${selectedCategory.tabs.length} tabs',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 4),
                // Ellipsis button for category options
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 16),
                  padding: EdgeInsets.zero,
                  onSelected: (value) async {
                    if (value == 'edit') {
                      final result = await showDialog<Map<String, dynamic>>(
                        context: context,
                        builder: (context) => CategoryDialog.edit(
                          initialName: selectedCategory.name,
                          initialColor: selectedCategory.color,
                        ),
                      );
                      if (result != null) {
                        await viewModel.updateCategory(
                          selectedCategory.id,
                          result['name'],
                          result['color'],
                        );
                      }
                    } else if (value == 'delete') {
                      await viewModel.deleteCategory(
                        context,
                        selectedCategory.id,
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Edit Category'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Delete Category',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tabs for focused category with ellipsis buttons
          ...selectedCategory.tabs
              .map(
                (tab) => Container(
                  margin: const EdgeInsets.only(left: 16),
                  child: InkWell(
                    onTap: () => viewModel.selectTab(tab.id),
                    child: Container(
                      decoration: BoxDecoration(
                        color: viewModel.selectedTab?.id == tab.id
                            ? selectedCategory.color.withOpacity(0.05)
                            : null,
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 24),
                          // Tab color indicator - clickable for color picker
                          InkWell(
                            onTap: () async {
                              final result =
                                  await showDialog<Map<String, dynamic>>(
                                    context: context,
                                    builder: (context) => TabDialog.edit(
                                      initialName: tab.name,
                                      initialColor: tab.color,
                                    ),
                                  );
                              if (result != null) {
                                await viewModel.updateTab(
                                  tab.id,
                                  result['name'],
                                  result['color'],
                                );
                              }
                            },
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: tab.color,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Text(
                                tab.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight:
                                      viewModel.selectedTab?.id == tab.id
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: viewModel.selectedTab?.id == tab.id
                                      ? selectedCategory.color
                                      : null,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          // Pin button
                          IconButton(
                            icon: Icon(
                              tab.isPinned
                                  ? Icons.push_pin
                                  : Icons.push_pin_outlined,
                              size: 14,
                              color: tab.isPinned ? Colors.amber : Colors.grey,
                            ),
                            onPressed: () => viewModel.toggleTabPinned(tab.id),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          // Ellipsis button for tab options
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 14),
                            padding: EdgeInsets.zero,
                            onSelected: (value) async {
                              if (value == 'edit') {
                                final result =
                                    await showDialog<Map<String, dynamic>>(
                                      context: context,
                                      builder: (context) => TabDialog.edit(
                                        initialName: tab.name,
                                        initialColor: tab.color,
                                      ),
                                    );
                                if (result != null) {
                                  await viewModel.updateTab(
                                    tab.id,
                                    result['name'],
                                    result['color'],
                                  );
                                }
                              } else if (value == 'delete') {
                                await viewModel.deleteTab(context, tab.id);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 14),
                                    SizedBox(width: 8),
                                    Text('Edit Tab'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      size: 14,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete Tab',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),

          // Add tab button in focused category
          Padding(
            padding: const EdgeInsets.only(left: 56, top: 4, bottom: 8),
            child: InkWell(
              onTap: () async {
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
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: selectedCategory.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 14, color: selectedCategory.color),
                    const SizedBox(width: 4),
                    Text(
                      'Add Tab',
                      style: TextStyle(
                        fontSize: 12,
                        color: selectedCategory.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context, NotesViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with pin toggle AND Add Category button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text(
                'Categories',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Spacer(),
              // Add Category button - now beside the pin icon
              IconButton(
                icon: const Icon(Icons.add, size: 18),
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
                tooltip: 'Add Category',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              // Pinned toggle button
              IconButton(
                icon: Icon(
                  viewModel.showPinnedOnly
                      ? Icons.push_pin
                      : Icons.push_pin_outlined,
                  color: viewModel.showPinnedOnly ? Colors.amber : Colors.grey,
                  size: 18,
                ),
                onPressed: viewModel.togglePinnedOnly,
                tooltip: viewModel.showPinnedOnly
                    ? 'Show all categories'
                    : 'Show only categories with pinned tabs',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),

        // Categories list - using ListView with custom drag handles
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: viewModel.showPinnedOnly
                ? viewModel.categoriesWithPinnedTabs.length
                : viewModel.categories.length,
            buildDefaultDragHandles: false,
            onReorder: (oldIndex, newIndex) {
              viewModel.reorderCategories(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final category = viewModel.showPinnedOnly
                  ? viewModel.categoriesWithPinnedTabs[index]
                  : viewModel.categories[index];
              return _buildCategoryItemWithCustomDragHandle(
                context,
                viewModel,
                category,
                index,
              );
            },
          ),
        ),

        // REMOVED the big Add Category button from bottom
        // No longer needed since it's now in the header
      ],
    );
  }

  // Build category item with custom drag handle
  Widget _buildCategoryItemWithCustomDragHandle(
    BuildContext context,
    NotesViewModel viewModel,
    Category category,
    int index,
  ) {
    final isSelected = viewModel.selectedCategory?.id == category.id;
    final tabsToShow = viewModel.showPinnedOnly
        ? category.pinnedTabs
        : category.tabs;

    return Container(
      key: ValueKey(category.id),
      margin: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Container(
            decoration: BoxDecoration(
              color: isSelected ? category.color.withOpacity(0.1) : null,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                // Drag handle
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.0),
                    child: Icon(
                      Icons.drag_handle,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),

                // Expand/collapse icon
                InkWell(
                  onTap: () => viewModel.toggleCategoryExpansion(category.id),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      category.isExpanded
                          ? Icons.arrow_drop_down
                          : Icons.arrow_right,
                      color: category.color,
                      size: 20,
                    ),
                  ),
                ),

                // Category color circle - clickable for color picker
                InkWell(
                  onTap: () async {
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
                  },
                  child: Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: category.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                  ),
                ),

                // Category name
                Expanded(
                  child: InkWell(
                    onTap: () => viewModel.selectCategory(category.id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        category.name,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected ? category.color : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),

                // Tab count
                Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Text(
                    '${tabsToShow.length}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),

                // Ellipsis button for category options
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 16),
                  padding: EdgeInsets.zero,
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
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 4),
              ],
            ),
          ),

          // Tabs (visible when expanded)
          if (category.isExpanded && tabsToShow.isNotEmpty)
            ...tabsToShow
                .map(
                  (tab) => _buildTabTileWithEllipsis(
                    context,
                    viewModel,
                    tab,
                    category.color,
                    isFocused: false,
                  ),
                )
                .toList(),

          // Add tab button when expanded
          if (category.isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 4, bottom: 4),
              child: InkWell(
                onTap: () async {
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
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 14, color: category.color),
                      const SizedBox(width: 4),
                      Text(
                        'Add Tab',
                        style: TextStyle(
                          fontSize: 12,
                          color: category.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Build a tab tile with ellipsis button
  Widget _buildTabTileWithEllipsis(
    BuildContext context,
    NotesViewModel viewModel,
    ContentTab tab,
    Color categoryColor, {
    required bool isFocused,
  }) {
    final isSelected = viewModel.selectedTab?.id == tab.id;

    return Container(
      margin: EdgeInsets.only(left: isFocused ? 16 : 48),
      child: InkWell(
        onTap: () => viewModel.selectTab(tab.id),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? categoryColor.withOpacity(0.05) : null,
          ),
          child: Row(
            children: [
              const SizedBox(width: 24),

              // Tab color indicator - clickable for color picker
              InkWell(
                onTap: () async {
                  final result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (context) => TabDialog.edit(
                      initialName: tab.name,
                      initialColor: tab.color,
                    ),
                  );
                  if (result != null) {
                    await viewModel.updateTab(
                      tab.id,
                      result['name'],
                      result['color'],
                    );
                  }
                },
                child: Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: tab.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    tab.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? categoryColor : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              // Pin button
              IconButton(
                icon: Icon(
                  tab.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  size: 14,
                  color: tab.isPinned ? Colors.amber : Colors.grey,
                ),
                onPressed: () => viewModel.toggleTabPinned(tab.id),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),

              // Ellipsis button for tab options
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 14),
                padding: EdgeInsets.zero,
                onSelected: (value) async {
                  if (value == 'edit') {
                    final result = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder: (context) => TabDialog.edit(
                        initialName: tab.name,
                        initialColor: tab.color,
                      ),
                    );
                    if (result != null) {
                      await viewModel.updateTab(
                        tab.id,
                        result['name'],
                        result['color'],
                      );
                    }
                  } else if (value == 'delete') {
                    await viewModel.deleteTab(context, tab.id);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 14),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 14, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  // Keep the old _buildTabTile for compatibility
  Widget _buildTabTile(
    BuildContext context,
    NotesViewModel viewModel,
    ContentTab tab,
    Color categoryColor, {
    required bool isFocused,
  }) {
    return _buildTabTileWithEllipsis(
      context,
      viewModel,
      tab,
      categoryColor,
      isFocused: isFocused,
    );
  }
}
