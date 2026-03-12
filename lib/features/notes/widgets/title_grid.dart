import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:modular_journal/features/notes/widgets/dialogs/delete_checklist_dialog.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/tab.dart';
import '../models/note.dart';
import '../viewmodels/notes_viewmodel.dart';
import 'custom_checkbox.dart';
import 'dialogs/checklist_item_dialog.dart';
import 'dialogs/timer_setup_dialog.dart';

class TitleGrid extends StatefulWidget {
  final ContentTab tab;
  final Color categoryColor;

  const TitleGrid({super.key, required this.tab, required this.categoryColor});

  @override
  State<TitleGrid> createState() => _TitleGridState();
}

class _TitleGridState extends State<TitleGrid> {
  final Map<String, Timer> _timers = {};
  final Map<String, Timer> _uiUpdateTimers = {}; // For UI updates
  final Map<String, AudioPlayer> _audioPlayers = {};
  Timer? _globalUiTimer; // Global timer to update all active timers

  @override
  void initState() {
    super.initState();
    // Start a global UI update timer that runs every second
    _globalUiTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // This will rebuild the UI every second to update countdowns
        });
      }
    });
  }

  @override
  void dispose() {
    _globalUiTimer?.cancel();
    for (final timer in _timers.values) {
      timer.cancel();
    }
    for (final timer in _uiUpdateTimers.values) {
      timer.cancel();
    }
    for (final player in _audioPlayers.values) {
      player.dispose();
    }
    super.dispose();
  }

  void _showAddItemDialog(BuildContext context, NotesViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => ChecklistItemDialog(
        title: 'Add Checklist Item',
        onSave: (itemTitle) {
          if (itemTitle.isNotEmpty) {
            viewModel.addChecklistItem(widget.tab.id, itemTitle);
          }
        },
      ),
    );
  }

  void _showAddTimerDialog(BuildContext context, NotesViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => TimerSetupDialog(
        onSave: (duration, soundPath, loopSound, title) {
          // Create a timer item with custom name
          final timerId = DateTime.now().millisecondsSinceEpoch.toString();
          final timerItem = Note(
            id: timerId,
            title: title.isEmpty
                ? 'Timer'
                : title, // Use custom name or default
            timerDuration: duration,
            alarmSoundPath: soundPath,
            isLoopingAlarm: loopSound,
            timerState: TimerState.idle,
          );

          // Add to checklist
          viewModel.addChecklistItemWithTimer(widget.tab.id, timerItem);
        },
      ),
    );
  }

  void _handleCheckboxToggle(NotesViewModel viewModel, Note item) {
    final nextState = item.getNextCheckboxState();

    // Handle timer logic based on state
    switch (nextState) {
      case CheckboxState.checked:
        // Start timer
        if (item.timerDuration != null) {
          _startTimer(viewModel, item);
        }
        break;
      case CheckboxState.crossed:
        // Pause timer
        if (item.timerState == TimerState.running) {
          _pauseTimer(viewModel, item);
        }
        break;
      case CheckboxState.unchecked:
        // Reset timer
        _resetTimer(viewModel, item);
        break;
    }

    viewModel.toggleChecklistItem(widget.tab.id, item.id);
  }

  void _startTimer(NotesViewModel viewModel, Note item) {
    // Cancel existing timers
    _timers[item.id]?.cancel();
    _uiUpdateTimers[item.id]?.cancel();

    // Create background timer for completion
    final timer = Timer(item.timerDuration!, () {
      _onTimerComplete(viewModel, item);
      _uiUpdateTimers[item.id]?.cancel();
      _uiUpdateTimers.remove(item.id);
    });
    _timers[item.id] = timer;

    // Update item state
    item.startTimer();
    viewModel.updateNote(item);

    // Trigger UI update immediately
    setState(() {});
  }

  void _pauseTimer(NotesViewModel viewModel, Note item) {
    _timers[item.id]?.cancel();
    _uiUpdateTimers[item.id]?.cancel();
    item.pauseTimer();
    viewModel.updateNote(item);
    setState(() {});
  }

  void _resetTimer(NotesViewModel viewModel, Note item) {
    _timers[item.id]?.cancel();
    _uiUpdateTimers[item.id]?.cancel();
    _stopAlarm(item.id);
    item.resetTimer();
    viewModel.updateNote(item);
    setState(() {});
  }

  void _onTimerComplete(NotesViewModel viewModel, Note item) {
    _timers.remove(item.id);
    _uiUpdateTimers.remove(item.id);

    // Play alarm
    if (item.alarmSoundPath != null) {
      _playAlarm(item);
    }

    // Update item state
    item.completeTimer();
    viewModel.updateNote(item);

    // Show dialog
    _showTimerCompleteDialog(item);

    // Trigger UI update
    setState(() {});
  }

  Future<void> _playAlarm(Note item) async {
    final player = AudioPlayer();
    _audioPlayers[item.id] = player;

    if (item.isLoopingAlarm) {
      await player.setReleaseMode(ReleaseMode.loop);
    }

    if (item.alarmSoundPath != null) {
      await player.play(DeviceFileSource(item.alarmSoundPath!));
    }
  }

  void _stopAlarm(String itemId) {
    _audioPlayers[itemId]?.stop();
    _audioPlayers.remove(itemId);
  }

  void _showTimerCompleteDialog(Note item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('⏰ Timer Complete'),
        content: Text('The timer for "${item.title}" has finished!'),
        actions: [
          TextButton(
            onPressed: () {
              _stopAlarm(item.id);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<NotesViewModel>(context, listen: false);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          bottomLeft: Radius.circular(8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with add buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: widget.categoryColor.withOpacity(0.05),
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                const Text(
                  'Checklist',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.timer, size: 18),
                  onPressed: () {
                    _showAddTimerDialog(context, viewModel);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Add timer item',
                  color: Colors.orange,
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: () {
                    _showAddItemDialog(context, viewModel);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Add checklist item',
                ),
              ],
            ),
          ),

          // Checklist items
          Expanded(
            child: widget.tab.checklistItems.isEmpty
                ? const Center(
                    child: Text(
                      'No items',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: widget.tab.checklistItems.length,
                    itemBuilder: (context, index) {
                      final item = widget.tab.checklistItems[index];
                      final hasTimer =
                          item.timerDuration !=
                          null; // This will be true for timer items
                      final remainingTime = item.getRemainingTime();

                      return Container(
                        key: ValueKey(item.id),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                hasTimer &&
                                    item.timerState == TimerState.running
                                ? Colors.orange
                                : hasTimer // Any timer item gets a subtle border
                                ? Colors.orange.withOpacity(0.3)
                                : Colors.grey.shade200,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          color:
                              hasTimer // Timer items get a subtle background immediately
                              ? Colors.orange.withOpacity(0.05)
                              : null,
                        ),
                        child: ListTile(
                          dense: true,
                          leading: CustomCheckbox(
                            state: item.checkboxState,
                            onChanged: () {
                              _handleCheckboxToggle(viewModel, item);
                            },
                          ),
                          title: Row(
                            children: [
                              // Timer icon for all timer items
                              if (hasTimer) ...[
                                Icon(
                                  item.timerState == TimerState.running
                                      ? Icons.timer
                                      : item.timerState == TimerState.paused
                                      ? Icons.pause_circle_outline
                                      : Icons.timer_outlined,
                                  size: 14,
                                  color: item.timerState == TimerState.running
                                      ? Colors.orange
                                      : item.timerState == TimerState.paused
                                      ? Colors.grey
                                      : Colors.orange.shade300,
                                ),
                                const SizedBox(width: 4),
                              ],
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        hasTimer &&
                                            item.timerState ==
                                                TimerState.completed
                                        ? Colors.green
                                        : null,
                                  ),
                                ),
                              ),
                              if (hasTimer && remainingTime != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: item.timerState == TimerState.running
                                        ? Colors.orange.withOpacity(0.2)
                                        : item.timerState == TimerState.paused
                                        ? Colors.grey.withOpacity(0.2)
                                        : Colors.orange.withOpacity(
                                            0.1,
                                          ), // Show time even when idle
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    remainingTime,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          item.timerState == TimerState.running
                                          ? Colors.orange
                                          : item.timerState == TimerState.paused
                                          ? Colors.grey
                                          : Colors.orange.shade300,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasTimer &&
                                  item.timerState == TimerState.completed)
                                IconButton(
                                  icon: const Icon(
                                    Icons.alarm,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                  onPressed: () {
                                    _stopAlarm(item.id);
                                    _resetTimer(viewModel, item);
                                    viewModel.toggleChecklistItem(
                                      widget.tab.id,
                                      item.id,
                                    );
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  _showDeleteConfirmation(
                                    context,
                                    viewModel,
                                    widget.tab.id,
                                    item,
                                  );
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          onLongPress: () {
                            _showEditItemDialog(
                              context,
                              viewModel,
                              widget.tab.id,
                              item,
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showEditItemDialog(
    BuildContext context,
    NotesViewModel viewModel,
    String tabId,
    Note item,
  ) {
    showDialog(
      context: context,
      builder: (context) => ChecklistItemDialog(
        title: 'Edit Checklist Item',
        initialValue: item.title,
        onSave: (newTitle) {
          if (newTitle.isNotEmpty && newTitle != item.title) {
            viewModel.updateChecklistItemTitle(tabId, item.id, newTitle);
          }
        },
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    NotesViewModel viewModel,
    String tabId,
    Note item,
  ) {
    // Stop any active timer/alarm
    _timers[item.id]?.cancel();
    _uiUpdateTimers[item.id]?.cancel();
    _stopAlarm(item.id);

    showDialog(
      context: context,
      builder: (context) => DeleteChecklistItemDialog(item: item),
    ).then((confirmed) {
      if (confirmed == true) {
        viewModel.deleteChecklistItem(tabId, item.id);
      }
    });
  }
}
