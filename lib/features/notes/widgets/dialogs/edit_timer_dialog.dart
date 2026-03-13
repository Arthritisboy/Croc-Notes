// lib/features/notes/widgets/dialogs/edit_timer_dialog.dart
import 'package:flutter/material.dart';
import 'package:modular_journal/features/notes/models/note.dart';
import 'timer_setup_dialog.dart';

class EditTimerDialog extends StatelessWidget {
  final Note timerItem;
  final Function(Note) onSave;

  const EditTimerDialog({
    super.key,
    required this.timerItem,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return TimerSetupDialog(
      existingTimer: timerItem,
      onSave: (duration, soundPath, loop, title) {
        final updatedTimer = Note(
          id: timerItem.id,
          title: title.isEmpty ? timerItem.title : title,
          timerDuration: duration,
          alarmSoundPath: soundPath,
          isLoopingAlarm: loop,
          timerState: TimerState.idle,
          checkboxState: CheckboxState.unchecked,
        );
        onSave(updatedTimer);
      },
    );
  }
}
