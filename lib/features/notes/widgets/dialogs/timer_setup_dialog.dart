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
  late TextEditingController _hoursController;
  late TextEditingController _minutesController;
  late TextEditingController _secondsController;

  String? _selectedSoundPath;
  bool _loopSound = true;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _useDefaultSound = true;
  bool _showSoundSection = true;
  bool _isInitialized = false; // Add initialization flag

  // Default alarm sound path
  String? _defaultSoundPath;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _nameController = TextEditingController();
    _hoursController = TextEditingController(text: '00');
    _minutesController = TextEditingController(text: '00');
    _secondsController = TextEditingController(text: '00');

    // Start initialization
    _initializeDialog();
  }

  Future<void> _initializeDialog() async {
    // Load default sound first
    await _initDefaultSound();

    // Then validate existing sound if in edit mode
    if (widget.existingTimer != null) {
      await _validateSoundPathOnLoad(widget.existingTimer!.alarmSoundPath);

      // Parse duration
      if (widget.existingTimer!.timerDuration != null) {
        _hoursController.text = widget.existingTimer!.timerDuration!.inHours
            .toString()
            .padLeft(2, '0');
        _minutesController.text = widget.existingTimer!.timerDuration!.inMinutes
            .remainder(60)
            .toString()
            .padLeft(2, '0');
        _secondsController.text = widget.existingTimer!.timerDuration!.inSeconds
            .remainder(60)
            .toString()
            .padLeft(2, '0');
      }

      _nameController.text = widget.existingTimer!.title;
      _loopSound = widget.existingTimer!.isLoopingAlarm;

      // Set default sound based on whether custom sound exists and is valid
      _useDefaultSound = _selectedSoundPath == null;
    } else {
      // For new timer, default sound is selected if available
      _useDefaultSound = _defaultSoundPath != null;
    }

    // Add listeners after initialization
    _nameController.addListener(_onTextChanged);
    _hoursController.addListener(_onHoursChanged);
    _minutesController.addListener(_onMinutesChanged);
    _secondsController.addListener(_onSecondsChanged);

    // Mark as initialized and rebuild
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _onHoursChanged() {
    _validateTwoDigitInput(_hoursController, 0, 24);
    setState(() {});
  }

  void _onMinutesChanged() {
    _validateTwoDigitInput(_minutesController, 0, 59);
    setState(() {});
  }

  void _onSecondsChanged() {
    _validateTwoDigitInput(_secondsController, 0, 59);
    setState(() {});
  }

  void _validateTwoDigitInput(
    TextEditingController controller,
    int min,
    int max,
  ) {
    String text = controller.text;

    // Remove any non-digit characters
    text = text.replaceAll(RegExp(r'[^0-9]'), '');

    if (text.isEmpty) {
      controller.text = '00';
      return;
    }

    // Parse the number
    int value = int.parse(text);

    // Clamp to range
    if (value < min) value = min;
    if (value > max) value = max;

    // Format with 2 digits
    controller.text = value.toString().padLeft(2, '0');

    // Move cursor to end
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );
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

    if (_defaultSoundPath == null) {
      debugPrint('No default alarm sound found');
    }
  }

  Future<void> _validateSoundPathOnLoad(String? path) async {
    if (path == null || path.isEmpty) {
      _selectedSoundPath = null;
      return;
    }

    final file = File(path);
    if (await file.exists()) {
      _selectedSoundPath = path;
      debugPrint('✅ Custom sound file found: $path');
    } else {
      debugPrint('⚠️ Custom sound file not found on load: $path');
      _selectedSoundPath = null;
    }
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_onTextChanged);
    _nameController.dispose();
    _hoursController.removeListener(_onHoursChanged);
    _hoursController.dispose();
    _minutesController.removeListener(_onMinutesChanged);
    _minutesController.dispose();
    _secondsController.removeListener(_onSecondsChanged);
    _secondsController.dispose();
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
    if (value == false) {
      // User unchecking default - open file picker
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac'],
      );

      if (result != null) {
        setState(() {
          _useDefaultSound = false;
          _selectedSoundPath = result.files.single.path;
        });
        await _playPreview();
      } else {
        // User canceled - keep default selected
        setState(() {
          _useDefaultSound = true;
          _selectedSoundPath = null; // IMPORTANT: Clear custom path
        });
      }
    } else {
      // User checking default
      setState(() {
        _useDefaultSound = true;
        _selectedSoundPath = null; // IMPORTANT: Clear custom path
      });

      if (_defaultSoundPath != null) {
        await _playPreview();
      }
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

  int _getIntFromController(TextEditingController controller) {
    return int.tryParse(controller.text) ?? 0;
  }

  Duration _getDuration() {
    return Duration(
      hours: _getIntFromController(_hoursController),
      minutes: _getIntFromController(_minutesController),
      seconds: _getIntFromController(_secondsController),
    );
  }

  bool get _hasValidInput {
    return _nameController.text.isNotEmpty ||
        (_getIntFromController(_hoursController) > 0 ||
            _getIntFromController(_minutesController) > 0 ||
            _getIntFromController(_secondsController) > 0);
  }

  void _toggleSoundSection() {
    setState(() {
      _showSoundSection = !_showSoundSection;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while initializing
    if (!_isInitialized) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 200,
          height: 200,
          padding: const EdgeInsets.all(24),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.orange),
              SizedBox(height: 16),
              Text('Loading...'),
            ],
          ),
        ),
      );
    }

    final isEditing = widget.existingTimer != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
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

              // Time pickers with individual dropdowns
              const Text(
                'Duration',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _buildTimePickerWithDropdown(
                      label: 'Hours',
                      controller: _hoursController,
                      max: 24,
                      items: List.generate(
                        25,
                        (i) => i.toString().padLeft(2, '0'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTimePickerWithDropdown(
                      label: 'Minutes',
                      controller: _minutesController,
                      max: 59,
                      items: List.generate(
                        60,
                        (i) => i.toString().padLeft(2, '0'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTimePickerWithDropdown(
                      label: 'Seconds',
                      controller: _secondsController,
                      max: 59,
                      items: List.generate(
                        60,
                        (i) => i.toString().padLeft(2, '0'),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Sound Section Toggle
              InkWell(
                onTap: _toggleSoundSection,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        _showSoundSection
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Alarm Settings',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange,
                        ),
                      ),
                      const Spacer(),
                      // Show current selection status
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _useDefaultSound ? 'Default' : 'Custom',
                          style: TextStyle(
                            fontSize: 10,
                            color: _useDefaultSound
                                ? Colors.green.shade300
                                : Colors.blue.shade300,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Sound Section (conditionally visible)
              if (_showSoundSection) ...[
                const SizedBox(height: 8),

                // Default sound option
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _useDefaultSound,
                        onChanged: _useDefaultSoundToggle,
                        activeColor: Colors.orange,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Use default alarm sound',
                              style: TextStyle(fontSize: 14),
                            ),
                            if (_defaultSoundPath == null)
                              Text(
                                '(Default sound not available)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange.shade300,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Custom sound picker
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () async {
                      if (_useDefaultSound) {
                        // If default is selected, uncheck it and open picker
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.audio,
                          allowedExtensions: ['mp3', 'wav', 'm4a', 'aac'],
                        );

                        if (result != null) {
                          setState(() {
                            _useDefaultSound = false;
                            _selectedSoundPath = result.files.single.path;
                          });
                          await _playPreview();
                        }
                      } else {
                        // Already in custom mode, just open picker
                        await _pickSound();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _useDefaultSound
                              ? Colors.grey.shade800
                              : Colors.grey.shade700,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: _useDefaultSound
                            ? Colors.grey.shade900.withOpacity(0.5)
                            : Colors.grey.shade900,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selectedSoundPath == null
                                ? Icons.music_note
                                : Icons.audio_file,
                            color: _useDefaultSound
                                ? Colors.grey
                                : Colors.orange,
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
                                    color: _useDefaultSound
                                        ? Colors.grey.shade600
                                        : _selectedSoundPath == null
                                        ? Colors.grey.shade400
                                        : Colors.white,
                                  ),
                                ),
                                if (_selectedSoundPath != null &&
                                    !_useDefaultSound) ...[
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
                          Icon(
                            Icons.folder_open,
                            color: _useDefaultSound
                                ? Colors.grey.shade700
                                : Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

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
              ],

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
                      onPressed: _hasValidInput
                          ? () {
                              widget.onSave(
                                _getDuration(),
                                _useDefaultSound
                                    ? null
                                    : _selectedSoundPath, // null for default
                                _loopSound,
                                _nameController.text.trim(),
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

  Widget _buildTimePickerWithDropdown({
    required String label,
    required TextEditingController controller,
    required int max,
    required List<String> items,
  }) {
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
              // Decrement button
              IconButton(
                icon: const Icon(Icons.remove, size: 16),
                onPressed: () {
                  int current = _getIntFromController(controller);
                  if (current > 0) {
                    controller.text = (current - 1).toString().padLeft(2, '0');
                  }
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              // Editable text field with dropdown
              Expanded(
                child: InkWell(
                  onTap: () => _showDropdownMenu(context, controller, items),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      controller.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              // Increment button
              IconButton(
                icon: const Icon(Icons.add, size: 16),
                onPressed: () {
                  int current = _getIntFromController(controller);
                  if (current < max) {
                    controller.text = (current + 1).toString().padLeft(2, '0');
                  }
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showDropdownMenu(
    BuildContext context,
    TextEditingController controller,
    List<String> items,
  ) async {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final String? result = await showMenu(
      context: context,
      position: position,
      items: items.map((item) {
        return PopupMenuItem(
          value: item,
          child: Center(child: Text(item)),
        );
      }).toList(),
    );

    if (result != null) {
      controller.text = result;
    }
  }
}
