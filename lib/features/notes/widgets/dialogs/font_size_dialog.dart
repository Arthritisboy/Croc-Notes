// lib/shared/widgets/font_size_dialog.dart
import 'package:flutter/material.dart';

class FontSizeDialog extends StatefulWidget {
  final double initialSize;
  final ValueChanged<int> onSelected;

  const FontSizeDialog({
    super.key,
    required this.initialSize,
    required this.onSelected,
  });

  @override
  State<FontSizeDialog> createState() => _FontSizeDialogState();
}

class _FontSizeDialogState extends State<FontSizeDialog> {
  late TextEditingController _controller;
  late int _selectedSize;
  final List<int> _commonSizes = [
    8,
    9,
    10,
    11,
    12,
    14,
    16,
    18,
    20,
    22,
    24,
    26,
    28,
    36,
    48,
    72,
  ];

  @override
  void initState() {
    super.initState();
    _selectedSize = widget.initialSize.round();
    _controller = TextEditingController(text: _selectedSize.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Font Size'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Number input field
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Enter font size',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixText: 'px',
            ),
            onChanged: (value) {
              final parsed = int.tryParse(value);
              if (parsed != null && parsed > 0) {
                setState(() {
                  _selectedSize = parsed;
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // Common sizes grid
          const Text('Common sizes:'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _commonSizes.map((size) {
              final isSelected = _selectedSize == size;
              return FilterChip(
                label: Text('$size'),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedSize = size;
                    _controller.text = size.toString();
                  });
                },
                backgroundColor: Colors.grey.shade100,
                selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                checkmarkColor: Theme.of(context).primaryColor,
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final parsed = int.tryParse(_controller.text);
            if (parsed != null && parsed > 0) {
              widget.onSelected(parsed);
              Navigator.pop(context);
            }
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
