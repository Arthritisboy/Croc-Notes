import 'package:modular_journal/features/notes/models/note.dart';

class ContentTab {
  final String id;
  String name;
  String categoryId;
  bool isPinned;
  String notepadContent;
  String contentNotepad;
  List<String> imagePaths;
  List<Note> checklistItems;

  ContentTab({
    required this.id,
    required this.name,
    required this.categoryId,
    this.isPinned = false,
    this.notepadContent = '',
    this.contentNotepad = '',
    this.imagePaths = const [],
    this.checklistItems = const [],
  });

  // Add a new checklist item
  void addChecklistItem(String title) {
    checklistItems.add(
      Note(id: DateTime.now().millisecondsSinceEpoch.toString(), title: title),
    );
  }

  // Toggle checkbox - uses the Note's method
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
}
