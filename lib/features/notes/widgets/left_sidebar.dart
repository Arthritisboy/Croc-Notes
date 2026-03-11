import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/notes_viewmodel.dart';
import '../models/category.dart';
import '../models/tab.dart';

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
          // Category header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
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
                  selectedCategory.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  '${selectedCategory.tabs.length} tabs',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Tabs for focused category
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
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 6,
                                    color: tab.isPinned
                                        ? Colors.amber
                                        : selectedCategory.color.withOpacity(
                                            0.5,
                                          ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      tab.name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight:
                                            viewModel.selectedTab?.id == tab.id
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color:
                                            viewModel.selectedTab?.id == tab.id
                                            ? selectedCategory.color
                                            : null,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              tab.isPinned
                                  ? Icons.push_pin
                                  : Icons.push_pin_outlined,
                              size: 16,
                              color: tab.isPinned ? Colors.amber : Colors.grey,
                            ),
                            onPressed: () => viewModel.toggleTabPinned(tab.id),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context, NotesViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with pin toggle
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text(
                'Categories',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Spacer(),
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
            buildDefaultDragHandles: false, // DISABLE default handles
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
      ],
    );
  }

  // New method with custom drag handle on the LEFT
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
          Row(
            children: [
              // CUSTOM DRAG HANDLE - Now on the LEFT
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0),
                  child: Icon(Icons.drag_handle, size: 16, color: Colors.grey),
                ),
              ),

              // Expand/collapse icon
              Expanded(
                child: InkWell(
                  onTap: () => viewModel.toggleCategoryExpansion(category.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          category.isExpanded
                              ? Icons.arrow_drop_down
                              : Icons.arrow_right,
                          color: category.color,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: category.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            category.name,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected ? category.color : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${tabsToShow.length}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Pin button for category (optional)
                        Icon(
                          category.tabs.any((tab) => tab.isPinned)
                              ? Icons.push_pin
                              : Icons.push_pin_outlined,
                          size: 16,
                          color: category.tabs.any((tab) => tab.isPinned)
                              ? Colors.amber
                              : Colors.grey,
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Tabs (visible when expanded)
          if (category.isExpanded && tabsToShow.isNotEmpty)
            ...tabsToShow
                .map(
                  (tab) => _buildTabTile(
                    context,
                    viewModel,
                    tab,
                    category.color,
                    isFocused: false,
                  ),
                )
                .toList(),
        ],
      ),
    );
  }

  // Build a tab tile
  Widget _buildTabTile(
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
              const SizedBox(
                width: 40, // Increased to account for drag handle space
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 6,
                        color: tab.isPinned
                            ? Colors.amber
                            : categoryColor.withOpacity(0.5),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
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
                    ],
                  ),
                ),
              ),

              // Pin button
              IconButton(
                icon: Icon(
                  tab.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  size: 16,
                  color: tab.isPinned ? Colors.amber : Colors.grey,
                ),
                onPressed: () => viewModel.toggleTabPinned(tab.id),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),

              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
