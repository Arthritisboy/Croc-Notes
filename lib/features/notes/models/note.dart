enum CheckboxState { unchecked, checked, crossed }

class Note {
  final String id;
  String title;
  bool isPinned;
  CheckboxState checkboxState;

  Note({
    required this.id,
    required this.title,
    this.isPinned = false,
    this.checkboxState = CheckboxState.unchecked,
  });

  // Add this method
  CheckboxState getNextCheckboxState() {
    switch (checkboxState) {
      case CheckboxState.unchecked:
        return CheckboxState.checked;
      case CheckboxState.checked:
        return CheckboxState.crossed;
      case CheckboxState.crossed:
        return CheckboxState.unchecked;
    }
  }

  // Copy with method for updating
  Note copyWith({String? title, bool? isPinned, CheckboxState? checkboxState}) {
    return Note(
      id: id,
      title: title ?? this.title,
      isPinned: isPinned ?? this.isPinned,
      checkboxState: checkboxState ?? this.checkboxState,
    );
  }
}
