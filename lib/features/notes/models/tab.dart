import 'package:flutter/material.dart';
import 'note.dart';

class ContentTab {
  String id;
  String name;
  String categoryId;
  bool isPinned;
  Color color; // Add color for each tab
  String notepadContent; // Right grid - separate per tab
  String contentNotepad; // Bottom grid - separate per tab
  List<String> imagePaths;
  List<Note> checklistItems;

  ContentTab({
    required this.id,
    required this.name,
    required this.categoryId,
    this.color = Colors.grey,
    this.isPinned = false,
    this.notepadContent = '',
    this.contentNotepad = '',
    this.imagePaths = const [],
    this.checklistItems = const [],
  });

  // Get pinned tabs in this category
  List<ContentTab> get pinnedTabs => []; // Placeholder

  // Get unpinned tabs
  List<ContentTab> get unpinnedTabs => []; // Placeholder

  // Add a new checklist item
  void addChecklistItem(String title) {
    checklistItems.add(
      Note(id: DateTime.now().millisecondsSinceEpoch.toString(), title: title),
    );
  }

  // Toggle checkbox
  void toggleCheckbox(String noteId) {
    final index = checklistItems.indexWhere((item) => item.id == noteId);
    if (index != -1) {
      final currentItem = checklistItems[index];
      checklistItems[index] = currentItem.copyWith(
        checkboxState: currentItem.getNextCheckboxState(),
      );
    }
  }

  // Delete a checklist item
  void deleteChecklistItem(String noteId) {
    checklistItems.removeWhere((item) => item.id == noteId);
  }

  // Update checklist item title
  void updateChecklistItemTitle(String noteId, String newTitle) {
    final index = checklistItems.indexWhere((item) => item.id == noteId);
    if (index != -1) {
      checklistItems[index] = checklistItems[index].copyWith(title: newTitle);
    }
  }

  // Convert to JSON for database
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'categoryId': categoryId,
    'isPinned': isPinned ? 1 : 0,
    'colorValue': color.value,
    'notepadContent': notepadContent,
    'contentNotepad': contentNotepad,
  };

  // Create from JSON
  factory ContentTab.fromJson(Map<String, dynamic> json) => ContentTab(
    id: json['id'],
    name: json['name'],
    categoryId: json['categoryId'],
    isPinned: (json['isPinned'] as int?) == 1,
    color: Color(json['colorValue'] ?? Colors.grey.value),
    notepadContent: json['notepadContent'] as String? ?? '',
    contentNotepad: json['contentNotepad'] as String? ?? '',
  );
}
