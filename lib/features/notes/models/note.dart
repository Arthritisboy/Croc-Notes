// lib/features/notes/models/note.dart
enum CheckboxState { unchecked, checked, crossed }

enum TimerState { idle, running, paused, completed }

class Note {
  final String id;
  String title;
  bool isPinned;
  CheckboxState checkboxState;

  // Timer properties
  TimerState timerState;
  DateTime? timerEndTime;
  Duration? timerDuration;
  String? alarmSoundPath; // Path to MP3 file
  bool isLoopingAlarm;
  DateTime? timerStartTime;
  Duration? elapsedTime; // For paused state

  Note({
    required this.id,
    required this.title,
    this.isPinned = false,
    this.checkboxState = CheckboxState.unchecked,
    this.timerState = TimerState.idle,
    this.timerEndTime,
    this.timerDuration,
    this.alarmSoundPath,
    this.isLoopingAlarm = false,
    this.timerStartTime,
    this.elapsedTime,
  });

  // Toggle checkbox with timer logic
  CheckboxState getNextCheckboxState() {
    switch (checkboxState) {
      case CheckboxState.unchecked:
        return CheckboxState.checked;
      case CheckboxState.checked:
        return CheckboxState.crossed;
      case CheckboxState.crossed:
        return CheckboxState.unchecked;
    }
  }

  // Timer control methods
  void startTimer() {
    timerState = TimerState.running;
    timerStartTime = DateTime.now();
    if (timerDuration != null) {
      timerEndTime = DateTime.now().add(timerDuration!);
    }
  }

  void pauseTimer() {
    if (timerState == TimerState.running && timerStartTime != null) {
      elapsedTime = DateTime.now().difference(timerStartTime!);
      timerState = TimerState.paused;
    }
  }

  void resumeTimer() {
    if (timerState == TimerState.paused &&
        elapsedTime != null &&
        timerDuration != null) {
      final remainingTime = timerDuration! - elapsedTime!;
      timerStartTime = DateTime.now();
      timerEndTime = DateTime.now().add(remainingTime);
      timerState = TimerState.running;
    }
  }

  void resetTimer() {
    timerState = TimerState.idle;
    timerEndTime = null;
    timerStartTime = null;
    elapsedTime = null;
  }

  void completeTimer() {
    timerState = TimerState.completed;
    timerEndTime = null;
    timerStartTime = null;
  }

  // Get remaining time as formatted string
  String? getRemainingTime() {
    // For timer items, always show the duration if available
    if (timerDuration == null) return null;

    // If timer is idle, just show the full duration
    if (timerState == TimerState.idle) {
      final hours = timerDuration!.inHours;
      final minutes = timerDuration!.inMinutes.remainder(60);
      final seconds = timerDuration!.inSeconds.remainder(60);

      if (hours > 0) {
        return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      } else {
        return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      }
    }

    // Calculate remaining time for running/paused states
    Duration remaining;
    if (timerState == TimerState.running && timerEndTime != null) {
      remaining = timerEndTime!.difference(DateTime.now());
      if (remaining.isNegative) return "00:00";
    } else if (timerState == TimerState.paused && elapsedTime != null) {
      remaining = timerDuration! - elapsedTime!;
      if (remaining.isNegative) return "00:00";
    } else {
      return null;
    }

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  // Check if timer has completed
  bool shouldNotify() {
    return timerState == TimerState.running &&
        timerEndTime != null &&
        DateTime.now().isAfter(timerEndTime!);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isPinned': isPinned,
    'checkboxState': checkboxState.index,
    'timerState': timerState.index,
    'timerEndTime': timerEndTime?.toIso8601String(),
    'timerDuration': timerDuration?.inMilliseconds,
    'alarmSoundPath': alarmSoundPath,
    'isLoopingAlarm': isLoopingAlarm,
    'timerStartTime': timerStartTime?.toIso8601String(),
    'elapsedTime': elapsedTime?.inMilliseconds,
  };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'],
    title: json['title'],
    isPinned: json['isPinned'] ?? false,
    checkboxState: CheckboxState.values[json['checkboxState'] ?? 0],
    timerState: TimerState.values[json['timerState'] ?? 0],
    timerEndTime: json['timerEndTime'] != null
        ? DateTime.parse(json['timerEndTime'])
        : null,
    timerDuration: json['timerDuration'] != null
        ? Duration(milliseconds: json['timerDuration'])
        : null,
    alarmSoundPath: json['alarmSoundPath'],
    isLoopingAlarm: json['isLoopingAlarm'] ?? false,
    timerStartTime: json['timerStartTime'] != null
        ? DateTime.parse(json['timerStartTime'])
        : null,
    elapsedTime: json['elapsedTime'] != null
        ? Duration(milliseconds: json['elapsedTime'])
        : null,
  );

  Note copyWith({
    String? title,
    bool? isPinned,
    CheckboxState? checkboxState,
    TimerState? timerState,
    DateTime? timerEndTime,
    Duration? timerDuration,
    String? alarmSoundPath,
    bool? isLoopingAlarm,
    DateTime? timerStartTime,
    Duration? elapsedTime,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      isPinned: isPinned ?? this.isPinned,
      checkboxState: checkboxState ?? this.checkboxState,
      timerState: timerState ?? this.timerState,
      timerEndTime: timerEndTime ?? this.timerEndTime,
      timerDuration: timerDuration ?? this.timerDuration,
      alarmSoundPath: alarmSoundPath ?? this.alarmSoundPath,
      isLoopingAlarm: isLoopingAlarm ?? this.isLoopingAlarm,
      timerStartTime: timerStartTime ?? this.timerStartTime,
      elapsedTime: elapsedTime ?? this.elapsedTime,
    );
  }

  Duration? getRemainingTimeWithElapsed(DateTime currentTime) {
    if (timerDuration == null) return null;

    switch (timerState) {
      case TimerState.running:
        if (timerStartTime != null) {
          // Calculate elapsed time including PC off period
          final elapsed = currentTime.difference(timerStartTime!);
          final remaining = timerDuration! - elapsed;
          return remaining.isNegative ? Duration.zero : remaining;
        }
        return timerDuration;

      case TimerState.paused:
        if (elapsedTime != null) {
          final remaining = timerDuration! - elapsedTime!;
          return remaining.isNegative ? Duration.zero : remaining;
        }
        return timerDuration;

      case TimerState.idle:
      case TimerState.completed:
        return null;
    }
  }

  // Check if timer should have completed during PC off
  bool shouldHaveCompleted(DateTime currentTime) {
    if (timerState != TimerState.running || timerStartTime == null)
      return false;

    final elapsed = currentTime.difference(timerStartTime!);
    return elapsed >= timerDuration!;
  }
}
