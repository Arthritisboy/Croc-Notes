// lib/features/notes/widgets/dialogs/timer_setup_dialog.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:modular_journal/features/notes/models/note.dart';
import 'package:path_provider/path_provider.dart';

class TimerSetupDialog extends StatefulWidget {
  final Function(Duration duration, String? soundPath, bool loop, String title)
  onSave;
  final Note? existingTimer;

  const TimerSetupDialog({super.key, required this.onSave, this.existingTimer});

  @override
  State<TimerSetupDialog> createState() => _TimerSetupDialogState();
}

class _TimerSetupDialogState extends State<TimerSetupDialog> {
  late TextEditingController _nameController;
  int _hours = 0;
  int _minutes = 0;
  int _seconds = 0;
  String? _selectedSoundPath;
  bool _loopSound = true;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _useDefaultSound = true;

  // Default alarm sound path
  String? _defaultSoundPath;

  @override
  void initState() {
    super.initState();

    // Initialize with existing timer data if in edit mode
    if (widget.existingTimer != null) {
      _nameController = TextEditingController(
        text: widget.existingTimer!.title,
      );

      // Parse duration
      if (widget.existingTimer!.timerDuration != null) {
        _hours = widget.existingTimer!.timerDuration!.inHours;
        _minutes = widget.existingTimer!.timerDuration!.inMinutes.remainder(60);
        _seconds = widget.existingTimer!.timerDuration!.inSeconds.remainder(60);
      }

      _selectedSoundPath = widget.existingTimer!.alarmSoundPath;
      _loopSound = widget.existingTimer!.isLoopingAlarm;
      _useDefaultSound = _selectedSoundPath == null;
    } else {
      _nameController = TextEditingController();
    }

    _nameController.addListener(_onTextChanged);
    _initDefaultSound();
  }

  Future<void> _initDefaultSound() async {
    // Look for default alarm.mp3 in various locations
    final List<String> possiblePaths = [];

    // In release build
    if (Platform.isWindows) {
      final exeDir = Directory(Platform.resolvedExecutable).parent;
      possiblePaths.add(
        '${exeDir.path}\\data\\flutter_assets\\assets\\sounds\\alarm.mp3',
      );
      possiblePaths.add('${exeDir.path}\\assets\\sounds\\alarm.mp3');
      possiblePaths.add('${exeDir.path}\\alarm.mp3');
    }

    // In debug build
    possiblePaths.add('${Directory.current.path}\\assets\\sounds\\alarm.mp3');
    possiblePaths.add('assets/sounds/alarm.mp3');

    // In app support directory
    final appDir = await getApplicationSupportDirectory();
    possiblePaths.add('${appDir.path}\\alarm.mp3');

    for (final path in possiblePaths) {
      final file = File(path);
      if (await file.exists()) {
        _defaultSoundPath = path;
        debugPrint('Found default alarm at: $path');
        break;
      }
    }
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_onTextChanged);
    _nameController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _pickSound() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowedExtensions: ['mp3', 'wav', 'm4a', 'aac'],
    );

    if (result != null) {
      setState(() {
        _selectedSoundPath = result.files.single.path;
        _useDefaultSound = false;
      });
      await _playPreview();
    }
  }

  Future<void> _useDefaultSoundToggle(bool? value) async {
    setState(() {
      _useDefaultSound = value ?? false;
      if (_useDefaultSound) {
        _selectedSoundPath = null;
      }
    });

    if (_useDefaultSound && _defaultSoundPath != null) {
      await _playPreview();
    }
  }

  Future<void> _playPreview() async {
    final soundToPlay = _useDefaultSound
        ? _defaultSoundPath
        : _selectedSoundPath;
    if (soundToPlay != null) {
      await _audioPlayer.play(DeviceFileSource(soundToPlay));
    }
  }

  Future<void> _stopPreview() async {
    await _audioPlayer.stop();
  }

  Duration _getDuration() {
    return Duration(hours: _hours, minutes: _minutes, seconds: _seconds);
  }

  bool get _hasValidInput {
    return _nameController.text.isNotEmpty ||
        (_hours > 0 || _minutes > 0 || _seconds > 0);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingTimer != null;

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
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isEditing ? Icons.edit : Icons.timer,
                      color: Colors.orange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Edit Timer' : 'Set Timer',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isEditing
                              ? 'Modify timer settings'
                              : 'Name your timer and choose duration',
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

              // Timer Name field
              const Text(
                'Timer Name',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter timer name',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.label, color: Colors.orange),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.orange,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade900,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),

              const SizedBox(height: 20),

              // Time picker
              const Text(
                'Duration',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _buildTimePicker('Hours', _hours, 0, 23, (value) {
                      setState(() => _hours = value);
                    }),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTimePicker('Minutes', _minutes, 0, 59, (
                      value,
                    ) {
                      setState(() => _minutes = value);
                    }),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTimePicker('Seconds', _seconds, 0, 59, (
                      value,
                    ) {
                      setState(() => _seconds = value);
                    }),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Sound selection
              const Text(
                'Alarm Sound',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              const SizedBox(height: 8),

              // Default sound option
              if (_defaultSoundPath != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _useDefaultSound,
                        onChanged: _useDefaultSoundToggle,
                        activeColor: Colors.orange,
                      ),
                      const Expanded(
                        child: Text(
                          'Use default alarm sound',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

              // Custom sound picker
              if (!_useDefaultSound)
                InkWell(
                  onTap: _pickSound,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade700),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade900,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _selectedSoundPath == null
                              ? Icons.music_note
                              : Icons.audio_file,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedSoundPath == null
                                    ? 'Tap to select MP3 file'
                                    : _selectedSoundPath!.split('/').last,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _selectedSoundPath == null
                                      ? Colors.grey.shade400
                                      : Colors.white,
                                ),
                              ),
                              if (_selectedSoundPath != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    TextButton.icon(
                                      onPressed: _playPreview,
                                      icon: const Icon(
                                        Icons.play_arrow,
                                        size: 14,
                                      ),
                                      label: const Text('Preview'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.green,
                                        padding: EdgeInsets.zero,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      onPressed: _stopPreview,
                                      icon: const Icon(Icons.stop, size: 14),
                                      label: const Text('Stop'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        padding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Icon(Icons.folder_open, color: Colors.grey),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Loop option
              Row(
                children: [
                  Switch(
                    value: _loopSound,
                    onChanged: (value) => setState(() => _loopSound = value),
                    activeColor: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Loop alarm until dismissed',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
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
                      onPressed: _hours == 0 && _minutes == 0 && _seconds == 0
                          ? null
                          : () {
                              widget.onSave(
                                _getDuration(),
                                _useDefaultSound ? null : _selectedSoundPath,
                                _loopSound,
                                _nameController.text.trim(),
                              );
                              Navigator.pop(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(isEditing ? 'Save Changes' : 'Set Timer'),
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

  Widget _buildTimePicker(
    String label,
    int value,
    int min,
    int max,
    Function(int) onChanged,
  ) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade700),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 16),
                onPressed: value > min ? () => onChanged(value - 1) : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Expanded(
                child: Text(
                  value.toString().padLeft(2, '0'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 16),
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
}
