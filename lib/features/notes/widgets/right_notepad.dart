import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tab.dart';
import '../viewmodels/notes_viewmodel.dart';

class RightNotepad extends StatelessWidget {
  final ContentTab tab;
  final Color categoryColor;

  const RightNotepad({
    super.key,
    required this.tab,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<NotesViewModel>(context, listen: false);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: const BorderRadius.only(topRight: Radius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.05),
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: const Text(
              'Notepad',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),

          // Single notepad for this specific tab
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TextFormField(
                key: ValueKey('right_notepad_${tab.id}'), // Unique key per tab
                initialValue: tab.notepadContent,
                decoration: const InputDecoration(
                  hintText: 'Write your notes here...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: null,
                style: const TextStyle(fontSize: 14),
                onChanged: (value) {
                  viewModel.updateNotepadContent(tab.id, value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
