import 'package:flutter/material.dart';
import 'package:modular_journal/data/services/timer_service.dart';
import 'package:modular_journal/features/notes/widgets/dialogs/mobile/mobile_timer_complete_dialog.dart';
import 'package:modular_journal/features/notes/widgets/dialogs/mobile/mobile_timer_dialog.dart';
import 'package:provider/provider.dart';
import '../../models/tab.dart';
import '../../models/category.dart';
import '../../models/note.dart';
import '../../viewmodels/notes_viewmodel.dart';
import '../title_grid.dart';
import '../right_notepad.dart';
import '../bottom_notepad.dart';

class MobileTabDetailView extends StatefulWidget {
  final ContentTab tab;
  final Category category;

  const MobileTabDetailView({
    super.key,
    required this.tab,
    required this.category,
  });

  @override
  State<MobileTabDetailView> createState() => _MobileTabDetailViewState();
}

class _MobileTabDetailViewState extends State<MobileTabDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final timerService = TimerService(); // Get the global instance

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Set up timer completion callback for this view
    _setupTimerCallback();
  }

  void _setupTimerCallback() {
    // Store the original callback
    final originalCallback = timerService.onTimerComplete;

    // Override to show mobile dialog
    timerService.onTimerComplete = (String itemId, String itemTitle) {
      // Call original callback first
      originalCallback?.call(itemId, itemTitle);

      // Show mobile dialog
      if (mounted) {
        _showTimerCompleteDialog(itemId, itemTitle);
      }
    };
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddTimerDialog() {
    final viewModel = Provider.of<NotesViewModel>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => MobileTimerSetupDialog(
        onSave: (duration, soundPath, loop, title) {
          // Create timer item
          final timerId = DateTime.now().millisecondsSinceEpoch.toString();
          final timerItem = Note(
            id: timerId,
            title: title.isEmpty ? 'Timer' : title,
            timerDuration: duration,
            alarmSoundPath: soundPath,
            isLoopingAlarm: loop,
            timerState: TimerState.idle,
          );

          // Add to checklist
          viewModel.addChecklistItemWithTimer(widget.tab.id, timerItem);
        },
        existingTimer: null,
      ),
    );
  }

  void _showTimerCompleteDialog(String itemId, String itemTitle) {
    final viewModel = Provider.of<NotesViewModel>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MobileTimerCompleteDialog(
        itemTitle: itemTitle,
        onStopAlarm: () {
          timerService.stopAlarm(itemId);
        },
        onDismiss: () {
          viewModel.resetTimerItem(itemId);
          viewModel.updateTimerItemCheckbox(itemId, CheckboxState.unchecked);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.category.name, style: const TextStyle(fontSize: 14)),
            Text(
              widget.tab.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: widget.category.color.withOpacity(0.1),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Checklist'),
            Tab(text: 'Notes'),
          ],
        ),
        actions: [
          // Add Timer Button
          IconButton(
            icon: const Icon(Icons.timer, color: Colors.orange),
            onPressed: _showAddTimerDialog,
            tooltip: 'Add Timer',
          ),
          IconButton(
            icon: Icon(
              widget.tab.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: widget.tab.isPinned ? Colors.amber : Colors.grey,
            ),
            onPressed: () {
              final viewModel = Provider.of<NotesViewModel>(
                context,
                listen: false,
              );
              viewModel.toggleTabPinned(widget.tab.id);
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Checklist tab
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TitleGrid(
              tab: widget.tab,
              categoryColor: widget.category.color,
            ),
          ),

          // Notes tab with nested tabs for notepads
          DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Container(
                  color: Colors.grey.shade900,
                  child: const TabBar(
                    tabs: [
                      Tab(text: 'Quick Notes'),
                      Tab(text: 'Content Notes'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Right notepad (Quick Notes)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: RightNotepad(
                          tab: widget.tab,
                          categoryColor: widget.category.color,
                        ),
                      ),
                      // Bottom notepad (Content Notes with images)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: BottomNotepad(
                          tab: widget.tab,
                          categoryColor: widget.category.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
