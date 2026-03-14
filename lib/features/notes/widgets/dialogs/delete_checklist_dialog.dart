import 'package:flutter/material.dart';
import 'package:modular_journal/features/notes/models/note.dart';

class DeleteChecklistItemDialog extends StatefulWidget {
  final Note item;

  const DeleteChecklistItemDialog({super.key, required this.item});

  @override
  State<DeleteChecklistItemDialog> createState() =>
      _DeleteChecklistItemDialogState();
}

class _DeleteChecklistItemDialogState extends State<DeleteChecklistItemDialog> {
  late TextEditingController _confirmController;
  late FocusNode _focusNode;
  bool _isConfirmed = false;

  @override
  void initState() {
    super.initState();
    _confirmController = TextEditingController();
    _focusNode = FocusNode();
    _confirmController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      _isConfirmed = _confirmController.text.trim() == widget.item.title;
    });
  }

  @override
  void dispose() {
    _confirmController.removeListener(_onTextChanged);
    _confirmController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with warning icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delete Item',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'This action cannot be undone',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Warning message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'You are about to delete:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Checkbox state indicator
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _getCheckboxColor(widget.item.checkboxState),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: _getCheckboxIcon(widget.item.checkboxState),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.item.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.item.timerDuration != null) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.timer,
                            size: 14,
                            color: Colors.orange.shade300,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Timer: ${_formatDuration(widget.item.timerDuration!)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Confirmation field
              const Text(
                'Type the item name to confirm:',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: _confirmController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: widget.item.title,
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  prefixIcon: Icon(
                    Icons.keyboard,
                    color: _isConfirmed ? Colors.green : Colors.grey.shade400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _isConfirmed
                          ? Colors.green.withOpacity(0.5)
                          : Colors.grey.shade700,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _isConfirmed ? Colors.green : Colors.red,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade900,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                autofocus: true,
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(color: Colors.grey.shade700),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isConfirmed
                          ? () => Navigator.pop(context, true)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Delete Permanently'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCheckboxColor(CheckboxState state) {
    switch (state) {
      case CheckboxState.checked:
        return Colors.green.withOpacity(0.2);
      case CheckboxState.crossed:
        return Colors.red.withOpacity(0.2);
      case CheckboxState.unchecked:
        return Colors.transparent;
    }
  }

  Widget? _getCheckboxIcon(CheckboxState state) {
    switch (state) {
      case CheckboxState.checked:
        return const Icon(Icons.check, size: 14, color: Colors.green);
      case CheckboxState.crossed:
        return const Icon(Icons.close, size: 14, color: Colors.red);
      case CheckboxState.unchecked:
        return null;
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
