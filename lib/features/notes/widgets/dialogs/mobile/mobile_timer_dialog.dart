import 'dart:io';
import 'package:flutter/material.dart';
import 'package:modular_journal/features/notes/models/note.dart';

class MobileTimerSetupDialog extends StatefulWidget {
  final Function(Duration duration, String? soundPath, bool loop, String title)
  onSave;
  final Note? existingTimer;

  const MobileTimerSetupDialog({
    super.key,
    required this.onSave,
    this.existingTimer,
  });

  @override
  State<MobileTimerSetupDialog> createState() => _MobileTimerSetupDialogState();
}

class _MobileTimerSetupDialogState extends State<MobileTimerSetupDialog> {
  late TextEditingController _nameController;
  int _hours = 0;
  int _minutes = 1; // Default to 1 minute
  int _seconds = 0;
  bool _loopSound = true;
  bool _useDefaultSound = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingTimer?.title ?? '',
    );

    if (widget.existingTimer?.timerDuration != null) {
      _hours = widget.existingTimer!.timerDuration!.inHours;
      _minutes = widget.existingTimer!.timerDuration!.inMinutes.remainder(60);
      _seconds = widget.existingTimer!.timerDuration!.inSeconds.remainder(60);
      _loopSound = widget.existingTimer!.isLoopingAlarm;
      _useDefaultSound = widget.existingTimer!.alarmSoundPath == null;
    }

    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingTimer != null;
    final hasValidInput =
        _nameController.text.isNotEmpty ||
        (_hours > 0 || _minutes > 0 || _seconds > 0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12), // Reduced padding
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit : Icons.timer,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Edit Timer' : 'New Timer',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isEditing ? 'Modify your timer' : 'Set a countdown',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable content with reduced padding
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12), // Reduced from 16
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name field - more compact
                    const Text('Timer Name', style: TextStyle(fontSize: 13)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'e.g., Laundry',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.label,
                          color: Colors.orange,
                          size: 18,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade700),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Colors.orange,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade900,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),

                    const SizedBox(height: 12),

                    // Duration section
                    const Text('Duration', style: TextStyle(fontSize: 13)),
                    const SizedBox(height: 6),

                    // Quick presets
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCompactPresetChip(
                            '30s',
                            () => _setDuration(0, 0, 30),
                          ),
                          _buildCompactPresetChip(
                            '1m',
                            () => _setDuration(0, 1, 0),
                          ),
                          _buildCompactPresetChip(
                            '5m',
                            () => _setDuration(0, 5, 0),
                          ),
                          _buildCompactPresetChip(
                            '10m',
                            () => _setDuration(0, 10, 0),
                          ),
                          _buildCompactPresetChip(
                            '15m',
                            () => _setDuration(0, 15, 0),
                          ),
                          _buildCompactPresetChip(
                            '30m',
                            () => _setDuration(0, 30, 0),
                          ),
                          _buildCompactPresetChip(
                            '1h',
                            () => _setDuration(1, 0, 0),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Compact time picker
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          _buildCompactTimeRow(
                            'Hrs',
                            _hours,
                            0,
                            24,
                            (v) => setState(() => _hours = v),
                          ),
                          const SizedBox(height: 4),
                          _buildCompactTimeRow(
                            'Min',
                            _minutes,
                            0,
                            59,
                            (v) => setState(() => _minutes = v),
                          ),
                          const SizedBox(height: 4),
                          _buildCompactTimeRow(
                            'Sec',
                            _seconds,
                            0,
                            59,
                            (v) => setState(() => _seconds = v),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Sound options - more compact
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text(
                              'Default Sound',
                              style: TextStyle(fontSize: 13),
                            ),
                            value: _useDefaultSound,
                            activeColor: Colors.orange,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            onChanged: (v) =>
                                setState(() => _useDefaultSound = v),
                          ),
                          const Divider(height: 1, color: Colors.grey),
                          SwitchListTile(
                            title: const Text(
                              'Loop Alarm',
                              style: TextStyle(fontSize: 13),
                            ),
                            value: _loopSound,
                            activeColor: Colors.orange,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            onChanged: (v) => setState(() => _loopSound = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action buttons - compact
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: hasValidInput
                          ? () {
                              widget.onSave(
                                Duration(
                                  hours: _hours,
                                  minutes: _minutes,
                                  seconds: _seconds,
                                ),
                                _useDefaultSound ? null : 'custom',
                                _loopSound,
                                _nameController.text.trim().isEmpty
                                    ? 'Timer'
                                    : _nameController.text.trim(),
                              );
                              Navigator.pop(context);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(isEditing ? 'Save' : 'Start'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add these helper methods
  Widget _buildCompactPresetChip(String label, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        onSelected: (_) => onTap(),
        backgroundColor: Colors.grey.shade800,
        selectedColor: Colors.orange.withOpacity(0.2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildCompactTimeRow(
    String label,
    int value,
    int min,
    int max,
    ValueChanged<int> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 18),
                onPressed: value > min ? () => onChanged(value - 1) : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    value.toString().padLeft(2, '0'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 18),
                onPressed: value < max ? () => onChanged(value + 1) : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        onSelected: (_) => onTap(),
        backgroundColor: Colors.grey.shade900,
        selectedColor: Colors.orange.withOpacity(0.2),
        checkmarkColor: Colors.orange,
      ),
    );
  }

  Widget _buildTimeRow(
    String label,
    int value,
    int min,
    int max,
    ValueChanged<int> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.orange,
                ),
                onPressed: value > min ? () => onChanged(value - 1) : null,
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    value.toString().padLeft(2, '0'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.orange,
                ),
                onPressed: value < max ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _setDuration(int hours, int minutes, int seconds) {
    setState(() {
      _hours = hours;
      _minutes = minutes;
      _seconds = seconds;
    });
  }
}
