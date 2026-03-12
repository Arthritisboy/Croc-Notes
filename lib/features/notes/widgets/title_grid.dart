// lib/features/notes/widgets/title_grid.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tab.dart';
import '../models/note.dart';
import '../viewmodels/notes_viewmodel.dart';
import 'custom_checkbox.dart';
import 'dialogs/checklist_item_dialog.dart'; // Create this file

class TitleGrid extends StatelessWidget {
  final ContentTab tab;
  final Color categoryColor;

  const TitleGrid({super.key, required this.tab, required this.categoryColor});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<NotesViewModel>(context, listen: false);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          bottomLeft: Radius.circular(8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with add button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.05),
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                const Text(
                  'Checklist',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: () {
                    _showAddItemDialog(context, viewModel);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Add checklist item',
                ),
              ],
            ),
          ),

          // Checklist items
          Expanded(
            child: tab.checklistItems.isEmpty
                ? const Center(
                    child: Text(
                      'No items',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: tab.checklistItems.length,
                    itemBuilder: (context, index) {
                      final item = tab.checklistItems[index];
                      return Container(
                        key: ValueKey(item.id),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ListTile(
                          dense: true,
                          leading: CustomCheckbox(
                            state: item.checkboxState,
                            onChanged: () {
                              viewModel.toggleChecklistItem(tab.id, item.id);
                            },
                          ),
                          title: Text(
                            item.title,
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              _showDeleteConfirmation(
                                context,
                                viewModel,
                                tab.id,
                                item,
                              );
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          onLongPress: () {
                            _showEditItemDialog(
                              context,
                              viewModel,
                              tab.id,
                              item,
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, NotesViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => ChecklistItemDialog(
        title: 'Add Checklist Item',
        onSave: (itemTitle) {
          if (itemTitle.isNotEmpty) {
            viewModel.addChecklistItem(tab.id, itemTitle);
          }
        },
      ),
    );
  }

  void _showEditItemDialog(
    BuildContext context,
    NotesViewModel viewModel,
    String tabId,
    Note item,
  ) {
    showDialog(
      context: context,
      builder: (context) => ChecklistItemDialog(
        title: 'Edit Checklist Item',
        initialValue: item.title,
        onSave: (newTitle) {
          if (newTitle.isNotEmpty && newTitle != item.title) {
            viewModel.updateChecklistItemTitle(tabId, item.id, newTitle);
          }
        },
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    NotesViewModel viewModel,
    String tabId,
    Note item,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              viewModel.deleteChecklistItem(tabId, item.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
