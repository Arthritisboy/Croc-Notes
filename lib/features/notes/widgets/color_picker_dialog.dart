import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;

  const ColorPickerDialog({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
  });

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color _selectedColor;
  late TextEditingController _hexController;
  bool _isValidHex = true;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
    _hexController = TextEditingController(text: _colorToHex(_selectedColor));
    _hexController.addListener(_onHexChanged);
  }

  @override
  void dispose() {
    _hexController.removeListener(_onHexChanged);
    _hexController.dispose();
    super.dispose();
  }

  void _onHexChanged() {
    final hex = _hexController.text.trim();
    if (hex.startsWith('#') && hex.length == 7) {
      try {
        final color = Color(
          int.parse(hex.substring(1), radix: 16) + 0xFF000000,
        );
        setState(() {
          _selectedColor = color;
          _isValidHex = true;
        });
        widget.onColorChanged(color); // Real-time update
      } catch (e) {
        setState(() => _isValidHex = false);
      }
    } else {
      setState(() => _isValidHex = hex.isEmpty || hex == '#');
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose Color'),
      content: Container(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Color picker wheel - fixed parameters
            MaterialPicker(
              pickerColor: _selectedColor,
              onColorChanged: (color) {
                setState(() {
                  _selectedColor = color;
                  _hexController.text = _colorToHex(color);
                });
                widget.onColorChanged(color); // Real-time update
              },
              enableLabel: true, // This is correct
            ),
            const SizedBox(height: 16),

            // Hex input field with preview
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isValidHex ? Colors.grey.shade300 : Colors.red,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _hexController,
                      decoration: InputDecoration(
                        hintText: '#FF0000',
                        border: InputBorder.none,
                        errorText: _isValidHex ? null : 'Invalid hex',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                      ),
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isValidHex
              ? () => Navigator.pop(context, _selectedColor)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedColor,
            foregroundColor: _selectedColor.computeLuminance() > 0.5
                ? Colors.black
                : Colors.white,
          ),
          child: const Text('Select'),
        ),
      ],
    );
  }
}
