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
          // Category header with color circle and ellipsis
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                // Color circle - clickable for editing (keeping this as visual indicator)
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: selectedCategory.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 2),
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
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color.fromARGB(255, 240, 239, 239),
                  ),
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

          // Tabs for focused category with background colors and ellipsis buttons
          ...selectedCategory.tabs
              .map(
                (tab) => Container(
                  margin: const EdgeInsets.only(left: 16, right: 8),
                  decoration: BoxDecoration(
                    // Background color based on tab's own color with opacity
                    color: viewModel.selectedTab?.id == tab.id
                        ? tab.color.withOpacity(
                            0.15,
                          ) // Selected tab - more visible
                        : tab.color.withOpacity(
                            0.05,
                          ), // Unselected tab - subtle
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: InkWell(
                    onTap: () => viewModel.selectTab(tab.id),
                    child: Row(
                      children: [
                        const SizedBox(width: 24),
                        // REMOVED color indicator circle
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              tab.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: viewModel.selectedTab?.id == tab.id
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: viewModel.selectedTab?.id == tab.id
                                    ? selectedCategory.color
                                    : const Color.fromARGB(255, 236, 234, 234),
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
                        const SizedBox(width: 4),
                      ],
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
        // Header with search, pin toggle, and add category
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // First row: Categories title and action buttons
              Row(
                children: [
                  const Text(
                    'Categories',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const Spacer(),
                  // Search toggle button
                  IconButton(
                    icon: Icon(
                      viewModel.isSearching ? Icons.search_off : Icons.search,
                      size: 18,
                      color: viewModel.isSearching ? Colors.blue : Colors.grey,
                    ),
                    onPressed: () {
                      if (viewModel.isSearching) {
                        // If already searching, clear search and exit search mode
                        viewModel.clearSearch();
                      } else {
                        // Enable search mode with empty query
                        viewModel.updateSearchQuery(
                          '',
                        ); // This will set isSearching to true
                      }
                    },
                    tooltip: viewModel.isSearching ? 'Clear search' : 'Search',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  // Add Category button
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
                      color: viewModel.showPinnedOnly
                          ? Colors.amber
                          : Colors.grey,
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

              // Search bar (visible when searching)
              if (viewModel.isSearching) ...[
                const SizedBox(height: 12),
                TextField(
                  onChanged: (query) => viewModel.updateSearchQuery(query),
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search categories and tabs...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => viewModel.clearSearch(),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Categories list
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: viewModel.filteredCategories.length,
            buildDefaultDragHandles: false,
            onReorder: (oldIndex, newIndex) {
              viewModel.reorderCategories(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final category = viewModel.filteredCategories[index];
              return _buildCategoryItemWithCustomDragHandle(
                context,
                viewModel,
                category,
                index,
              );
            },
          ),
        ),
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

    // Check if search is active and this category matches
    final bool isSearchMatch =
        viewModel.isSearching &&
        category.name.toLowerCase().contains(
          viewModel.searchQuery.toLowerCase(),
        );

    return Container(
      key: ValueKey(category.id),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSearchMatch ? Colors.yellow.withOpacity(0) : null,
      ),
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

                // Category color circle
                Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: category.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                ),

                // Category name with highlight if search match
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
                          backgroundColor: isSearchMatch
                              ? Colors.yellow.withOpacity(0)
                              : null,
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

                // Ellipsis button
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
                    searchQuery: viewModel.searchQuery,
                    isSearching: viewModel.isSearching,
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
                    color: Colors.grey.shade800.withOpacity(0.3),
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
    String searchQuery = '',
    bool isSearching = false,
  }) {
    final isSelected = viewModel.selectedTab?.id == tab.id;

    // Check if this tab matches the search
    final bool isSearchMatch =
        isSearching &&
        tab.name.toLowerCase().contains(searchQuery.toLowerCase());

    return Container(
      margin: EdgeInsets.only(left: isFocused ? 16 : 48),
      decoration: BoxDecoration(
        color: isSelected
            ? tab.color.withOpacity(0.15)
            : tab.color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: InkWell(
        onTap: () => viewModel.selectTab(tab.id),
        child: Row(
          children: [
            const SizedBox(width: 24),

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
                    backgroundColor: isSearchMatch
                        ? Colors.yellow.withOpacity(0)
                        : null,
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

            // Ellipsis button
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
