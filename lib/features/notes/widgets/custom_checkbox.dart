import 'package:flutter/material.dart';
import '../models/note.dart';

class CustomCheckbox extends StatelessWidget {
  final CheckboxState state;
  final VoidCallback onChanged;

  const CustomCheckbox({
    super.key,
    required this.state,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border.all(color: _getBorderColor(), width: 2),
          borderRadius: BorderRadius.circular(4),
          color: _getBackgroundColor(),
        ),
        child: Center(child: _getIcon()),
      ),
    );
  }

  Color _getBorderColor() {
    switch (state) {
      case CheckboxState.unchecked:
        return Colors.grey;
      case CheckboxState.checked:
        return Colors.green;
      case CheckboxState.crossed:
        return Colors.red;
    }
  }

  Color? _getBackgroundColor() {
    switch (state) {
      case CheckboxState.unchecked:
        return null;
      case CheckboxState.checked:
        return Colors.green.withOpacity(0.1);
      case CheckboxState.crossed:
        return Colors.red.withOpacity(0.1);
    }
  }

  Widget? _getIcon() {
    switch (state) {
      case CheckboxState.unchecked:
        return null;
      case CheckboxState.checked:
        return const Icon(Icons.check, size: 16, color: Colors.green);
      case CheckboxState.crossed:
        return const Icon(Icons.close, size: 16, color: Colors.red);
    }
  }
}
