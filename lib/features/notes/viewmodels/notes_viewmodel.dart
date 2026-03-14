import 'dart:io';

import 'package:flutter/material.dart';
import 'package:modular_journal/core/database/database_service.dart';
import 'package:modular_journal/features/notes/widgets/dialogs/delete_category_dialog.dart';
import 'package:modular_journal/features/notes/widgets/dialogs/delete_tab_dialog.dart';
import 'package:modular_journal/features/notes/widgets/title_grid.dart';
import '../models/note.dart';
import '../models/category.dart';
import '../models/tab.dart';

class NotesViewModel extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  // Data stores
  List<Category> _categories = [];

  // Selection state
  Category? _selectedCategory;
  ContentTab? _selectedTab;

  // UI State
  bool _showPinnedOnly = false;
  bool _isLoading = true;
  String? _error;

  bool _isSearching = false;
  String _searchQuery = '';

  // Getters
  List<Category> get categories => _categories;
  Category? get selectedCategory => _selectedCategory;
  ContentTab? get selectedTab => _selectedTab;
  bool get showPinnedOnly => _showPinnedOnly;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;

  List<String> getSystemFonts() {
    return [
      'Arial',
      'Courier New',
      'Georgia',
      'Times New Roman',
      'Verdana',
      'Roboto',
      'Helvetica',
      'Calibri',
      'Cambria',
      'Garamond',
    ];
  }

  List<Category> get filteredCategories {
    if (_searchQuery.isEmpty || !_isSearching) {
      return _showPinnedOnly ? categoriesWithPinnedTabs : _categories;
    }

    final query = _searchQuery.toLowerCase();

    // Filter categories that match OR have tabs that match
    return _categories.where((category) {
      // Check if category name matches
      if (category.name.toLowerCase().contains(query)) {
        return true;
      }

      // Check if any tab in this category matches
      return category.tabs.any((tab) => tab.name.toLowerCase().contains(query));
    }).toList();
  }

  // Get all pinned tabs across all categories
  List<ContentTab> get allPinnedTabs {
    List<ContentTab> pinned = [];
    for (var category in _categories) {
      pinned.addAll(category.pinnedTabs);
    }
    return pinned;
  }

  // Get categories that have pinned tabs
  List<Category> get categoriesWithPinnedTabs {
    return _categories
        .where((category) => category.tabs.any((tab) => tab.isPinned))
        .toList();
  }

  NotesViewModel() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await loadData();
    } catch (e) {
      print('Error in _init: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add method to update search
  void updateSearchQuery(String query) {
    _searchQuery = query;
    _isSearching = true;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _isSearching = false;
    notifyListeners();
  }

  void resetTimerItem(String itemId) {
    for (var category in _categories) {
      for (var tab in category.tabs) {
        for (var item in tab.checklistItems) {
          if (item.id == itemId) {
            item.resetTimer();
            updateNote(item);
            debugPrint('Reset timer item: $itemId');
            return;
          }
        }
      }
    }
    debugPrint('Timer item not found: $itemId');
  }

  Future<void> _setupActiveTimers() async {
    final now = DateTime.now();

    for (var category in _categories) {
      for (var tab in category.tabs) {
        for (var item in tab.checklistItems) {
          // Check if this is a timer item that should be running
          if (item.timerDuration != null &&
              item.timerState == TimerState.running &&
              item.timerStartTime != null) {
            // Calculate elapsed time
            final elapsed = now.difference(item.timerStartTime!);
            final totalDuration = item.timerDuration!;

            if (elapsed < totalDuration) {
              // Timer is still running - calculate remaining time
              final remaining = totalDuration - elapsed;

              debugPrint(
                '⏰ Restarting active timer: ${item.title}, remaining: ${remaining.inSeconds}s',
              );

              // Register with timer service
              timerService.startTimer(
                itemId: item.id,
                itemTitle: item.title,
                duration: remaining,
                soundPath:
                    item.alarmSoundPath, // This will be null for default sound
                loopSound: item.isLoopingAlarm,
                onComplete: () {
                  debugPrint('Timer completed: ${item.title}');
                  item.completeTimer();
                  item.checkboxState = CheckboxState.unchecked;
                  updateNote(item);
                  notifyListeners();
                },
              );
            }
          }
        }
      }
    }
  }

  void updateTimerItemCheckbox(String itemId, CheckboxState state) {
    for (var category in _categories) {
      for (var tab in category.tabs) {
        for (var item in tab.checklistItems) {
          if (item.id == itemId) {
            item.checkboxState = state;
            updateNote(item);
            notifyListeners();
            return;
          }
        }
      }
    }
  }

  Future<void> _validateAlarmSoundPaths() async {
    debugPrint('🔍 Validating alarm sound paths...');
    int updatedCount = 0;

    for (var category in _categories) {
      for (var tab in category.tabs) {
        for (var item in tab.checklistItems) {
          if (item.alarmSoundPath != null && item.alarmSoundPath!.isNotEmpty) {
            // Check if the sound file exists
            final file = File(item.alarmSoundPath!);
            final exists = await file.exists();

            if (!exists) {
              debugPrint(
                '⚠️ Sound file not found: ${item.alarmSoundPath} for item: ${item.title}',
              );

              // Reset to default sound (null means use default)
              item.alarmSoundPath = null;

              // Update in database
              final db = await _db.database;
              await db.update(
                'checklist_items',
                {'alarmSoundPath': null},
                where: 'id = ?',
                whereArgs: [item.id],
              );

              updatedCount++;
            }
          }
        }
      }
    }

    if (updatedCount > 0) {
      debugPrint(
        '✅ Updated $updatedCount timer items to use default alarm sound',
      );
      notifyListeners();
    }
  }

  // LOAD DATA FROM DATABASE
  Future<void> loadData() async {
    try {
      final db = await _db.database;

      // Clear existing data
      _categories.clear();

      // Load categories
      final categoryMaps = await db.query(
        'categories',
        orderBy: 'sortOrder ASC',
      );
      print('Loaded ${categoryMaps.length} categories');

      for (var categoryMap in categoryMaps) {
        final category = Category(
          id: categoryMap['id'] as String,
          name: categoryMap['name'] as String,
          color: Color(categoryMap['colorValue'] as int),
          isExpanded: (categoryMap['isExpanded'] as int?) == 1,
          tabs: [],
        );

        // Load tabs for this category
        final tabMaps = await db.query(
          'tabs',
          where: 'categoryId = ?',
          whereArgs: [category.id],
          orderBy: 'sortOrder ASC',
        );

        print('Loaded ${tabMaps.length} tabs for category ${category.name}');

        for (var tabMap in tabMaps) {
          final tab = ContentTab(
            id: tabMap['id'] as String,
            name: tabMap['name'] as String,
            categoryId: tabMap['categoryId'] as String,
            isPinned: (tabMap['isPinned'] as int?) == 1,
            color: Color(tabMap['colorValue'] as int? ?? Colors.grey.value),
            notepadContent: tabMap['notepadContent'] as String? ?? '',
            contentNotepad: tabMap['contentNotepad'] as String? ?? '',
            imagePaths: [],
            checklistItems: [],
          );

          // Load checklist items
          final itemMaps = await db.query(
            'checklist_items',
            where: 'tabId = ?',
            whereArgs: [tab.id],
            orderBy: 'sortOrder ASC',
          );

          final now = DateTime.now();

          for (var itemMap in itemMaps) {
            // Extract timer fields from database
            int timerStateIndex = itemMap['timerState'] as int? ?? 0;
            int? timerDurationMs = itemMap['timerDuration'] as int?;
            String? alarmSoundPath = itemMap['alarmSoundPath'] as String?;
            int isLooping = itemMap['isLoopingAlarm'] as int? ?? 0;
            String? timerEndTimeStr = itemMap['timerEndTime'] as String?;
            String? timerStartTimeStr = itemMap['timerStartTime'] as String?;
            int? elapsedTimeMs = itemMap['elapsedTime'] as int?;

            // Parse dates if they exist
            DateTime? timerEndTime;
            if (timerEndTimeStr != null && timerEndTimeStr.isNotEmpty) {
              try {
                timerEndTime = DateTime.parse(timerEndTimeStr);
              } catch (e) {
                print('Error parsing timerEndTime: $e');
              }
            }

            DateTime? timerStartTime;
            if (timerStartTimeStr != null && timerStartTimeStr.isNotEmpty) {
              try {
                timerStartTime = DateTime.parse(timerStartTimeStr);
              } catch (e) {
                print('Error parsing timerStartTime: $e');
              }
            }

            // Determine if this is a timer item (has timer duration)
            bool isTimerItem = timerDurationMs != null && timerDurationMs > 0;

            // Get the original checkbox state from DB
            int dbCheckboxState = itemMap['checkboxState'] as int;

            // Parse timer state
            TimerState timerState = TimerState.values[timerStateIndex];

            // If timer was running, calculate if it should have completed during PC off
            if (isTimerItem &&
                timerState == TimerState.running &&
                timerStartTime != null) {
              final elapsed = now.difference(timerStartTime);
              final totalDuration = Duration(milliseconds: timerDurationMs!);

              if (elapsed >= totalDuration) {
                // Timer completed while PC was off
                debugPrint(
                  '⏰ Timer completed while PC was off: ${itemMap['title']}',
                );
                timerState = TimerState.completed;
                timerEndTime = null;
                timerStartTime = null;
              } else {
                // Timer still running
                debugPrint(
                  '⏰ Timer still running after PC off: ${itemMap['title']}, elapsed: ${elapsed.inSeconds}s',
                );
              }
            }

            // Determine checkbox state based on timer state
            CheckboxState checkboxState;
            if (isTimerItem) {
              switch (timerState) {
                case TimerState.running:
                  checkboxState = CheckboxState.checked;
                  break;
                case TimerState.paused:
                  checkboxState = CheckboxState.crossed;
                  break;
                case TimerState.completed:
                  checkboxState = CheckboxState.unchecked;
                  break;
                case TimerState.idle:
                default:
                  checkboxState = CheckboxState.unchecked;
                  break;
              }
            } else {
              checkboxState = CheckboxState.values[dbCheckboxState];
            }

            print(
              'Loading item: ${itemMap['title']}, isTimer: $isTimerItem, '
              'timerState: ${timerState.index}, checkboxState: ${checkboxState.index}',
            );

            // Create Note with ALL properties
            tab.checklistItems.add(
              Note(
                id: itemMap['id'] as String,
                title: itemMap['title'] as String,
                checkboxState: checkboxState,
                timerState: timerState,
                timerDuration: timerDurationMs != null
                    ? Duration(milliseconds: timerDurationMs)
                    : null,
                alarmSoundPath: alarmSoundPath,
                isLoopingAlarm: isLooping == 1,
                timerEndTime: timerEndTime,
                timerStartTime: timerStartTime,
                elapsedTime: elapsedTimeMs != null
                    ? Duration(milliseconds: elapsedTimeMs)
                    : null,
              ),
            );
          }

          // Load images
          final imageMaps = await db.query(
            'images',
            where: 'tabId = ?',
            whereArgs: [tab.id],
            orderBy: 'sortOrder ASC',
          );

          for (var imageMap in imageMaps) {
            tab.imagePaths.add(imageMap['fileName'] as String);
          }

          category.tabs = [...category.tabs, tab];
        }

        _categories.add(category);
      }

      // Select first category and first tab if available
      if (_categories.isNotEmpty) {
        _selectedCategory = _categories.first;
        if (_selectedCategory!.tabs.isNotEmpty) {
          _selectedTab = _selectedCategory!.tabs.first;
        }
      }

      print('Data loaded successfully');

      // IMPORTANT: Check for completed timers FIRST
      await _checkForCompletedTimers();

      // Then set up active timers (running/paused)
      await _setupActiveTimers();

      // Finally validate sound paths (this won't affect completed timers)
      await _validateAlarmSoundPaths();

      notifyListeners();
    } catch (e) {
      print('Error loading data: $e');
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> _checkForCompletedTimers() async {
    final completedTimers = <Note>[];

    for (var category in _categories) {
      for (var tab in category.tabs) {
        for (var item in tab.checklistItems) {
          if (item.timerDuration != null &&
              item.timerState == TimerState.completed) {
            completedTimers.add(item);
          }
        }
      }
    }

    if (completedTimers.isNotEmpty) {
      debugPrint(
        'Found ${completedTimers.length} timers that completed while PC was off',
      );

      // Trigger timer service for each completed timer
      for (var item in completedTimers) {
        // Get valid sound path first
        final validPath = await timerService.getValidSoundPath(
          item.alarmSoundPath,
        );

        // Trigger completion with validated path
        timerService.triggerTimerCompletion(
          item.id,
          item.title,
          soundPath: validPath,
          loopSound: item.isLoopingAlarm,
        );
      }
    }
  }

  // ========== CATEGORY CRUD OPERATIONS ==========

  // Create new category
  Future<void> createCategory(String name, Color color) async {
    final db = await _db.database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    final newCategory = Category(
      id: id,
      name: name,
      color: color,
      tabs: [],
      isExpanded: true,
    );

    await db.insert('categories', {
      'id': id,
      'name': name,
      'colorValue': color.value,
      'isExpanded': 1,
      'sortOrder': _categories.length,
    });

    _categories.add(newCategory);

    // Auto-select the new category
    _selectedCategory = newCategory;
    _selectedTab = null;

    notifyListeners();
  }

  // Update category
  Future<void> updateCategory(String id, String newName, Color newColor) async {
    final db = await _db.database;

    final index = _categories.indexWhere((c) => c.id == id);
    if (index != -1) {
      // Update in-memory
      _categories[index].name = newName;
      _categories[index].color = newColor;

      // Update database
      await db.update(
        'categories',
        {
          'name': newName,
          'colorValue': newColor.value, // Make sure this is being saved
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      notifyListeners();
    }
  }

  // Delete category with confirmation
  Future<bool> deleteCategory(BuildContext context, String id) async {
    final category = _categories.firstWhere((c) => c.id == id);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteCategoryDialog(category: category),
    );

    if (confirmed == true) {
      final db = await _db.database;

      // Delete from database (cascade will delete tabs and items)
      await db.delete('categories', where: 'id = ?', whereArgs: [id]);

      // Remove from list
      _categories.removeWhere((c) => c.id == id);

      // Update selection
      if (_selectedCategory?.id == id) {
        _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
        _selectedTab = _selectedCategory?.tabs.isNotEmpty == true
            ? _selectedCategory!.tabs.first
            : null;
      }

      notifyListeners();
      return true;
    }
    return false;
  }

  // ========== TAB CRUD OPERATIONS ==========

  // Create new tab
  Future<void> createTab(String categoryId, String name, Color color) async {
    final db = await _db.database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    final category = _categories.firstWhere((c) => c.id == categoryId);
    final newTab = ContentTab(
      id: id,
      name: name,
      categoryId: categoryId,
      color: color,
      isPinned: false,
      notepadContent: '',
      contentNotepad: '',
      imagePaths: [],
      checklistItems: [],
    );

    await db.insert('tabs', {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'isPinned': 0,
      'colorValue': color.value,
      'notepadContent': '',
      'contentNotepad': '',
      'sortOrder': category.tabs.length,
    });

    category.tabs = [...category.tabs, newTab];

    // Auto-select the new tab
    _selectedTab = newTab;

    notifyListeners();
  }

  // Update tab
  Future<void> updateTab(String id, String newName, Color newColor) async {
    final db = await _db.database;

    for (var category in _categories) {
      for (var tab in category.tabs) {
        if (tab.id == id) {
          // Update in-memory
          tab.name = newName;
          tab.color = newColor;

          // Update database
          await db.update(
            'tabs',
            {
              'name': newName,
              'colorValue': newColor.value, // Make sure this is being saved
            },
            where: 'id = ?',
            whereArgs: [id],
          );

          notifyListeners();
          return;
        }
      }
    }
  }

  // Delete tab with confirmation
  Future<bool> deleteTab(BuildContext context, String id) async {
    // Find the tab
    ContentTab? tabToDelete;
    Category? parentCategory;

    for (var category in _categories) {
      for (var tab in category.tabs) {
        if (tab.id == id) {
          tabToDelete = tab;
          parentCategory = category;
          break;
        }
      }
    }

    if (tabToDelete == null) return false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteTabDialog(tab: tabToDelete!),
    );

    if (confirmed == true) {
      final db = await _db.database;

      // Delete from database
      await db.delete('tabs', where: 'id = ?', whereArgs: [id]);

      // Remove from list
      if (parentCategory != null) {
        parentCategory.tabs = parentCategory.tabs
            .where((t) => t.id != id)
            .toList();
      }

      // Update selection
      if (_selectedTab?.id == id) {
        _selectedTab = parentCategory?.tabs.isNotEmpty == true
            ? parentCategory!.tabs.first
            : null;
      }

      notifyListeners();
      return true;
    }
    return false;
  }

  // ========== EXISTING METHODS (with database integration) ==========

  void togglePinnedOnly() {
    _showPinnedOnly = !_showPinnedOnly;
    notifyListeners();
  }

  Future<void> reorderCategories(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final category = _categories.removeAt(oldIndex);
    _categories.insert(newIndex, category);

    final db = await _db.database;
    for (int i = 0; i < _categories.length; i++) {
      await db.update(
        'categories',
        {'sortOrder': i},
        where: 'id = ?',
        whereArgs: [_categories[i].id],
      );
    }

    notifyListeners();
  }

  Future<void> toggleCategoryExpansion(String categoryId) async {
    final category = _categories.firstWhere((c) => c.id == categoryId);
    category.isExpanded = !category.isExpanded;

    final db = await _db.database;
    await db.update(
      'categories',
      {'isExpanded': category.isExpanded ? 1 : 0},
      where: 'id = ?',
      whereArgs: [categoryId],
    );

    notifyListeners();
  }

  Future<void> selectCategory(String categoryId) async {
    _selectedCategory = _categories.firstWhere((c) => c.id == categoryId);
    if (_selectedCategory!.tabs.isNotEmpty) {
      _selectedTab = _selectedCategory!.tabs.first;
    }
    notifyListeners();
  }

  Future<void> selectTab(String tabId) async {
    for (var category in _categories) {
      for (var tab in category.tabs) {
        if (tab.id == tabId) {
          _selectedCategory = category;
          _selectedTab = tab;
          notifyListeners();
          return;
        }
      }
    }
  }

  Future<void> toggleTabPinned(String tabId) async {
    for (var category in _categories) {
      for (var tab in category.tabs) {
        if (tab.id == tabId) {
          tab.isPinned = !tab.isPinned;

          final db = await _db.database;
          await db.update(
            'tabs',
            {'isPinned': tab.isPinned ? 1 : 0},
            where: 'id = ?',
            whereArgs: [tabId],
          );

          notifyListeners();
          return;
        }
      }
    }
  }

  Future<void> toggleChecklistItem(String tabId, String itemId) async {
    for (var category in _categories) {
      for (var tab in category.tabs) {
        if (tab.id == tabId) {
          tab.toggleCheckbox(itemId);

          final item = tab.checklistItems.firstWhere((i) => i.id == itemId);
          final db = await _db.database;
          await db.update(
            'checklist_items',
            {'checkboxState': item.checkboxState.index},
            where: 'id = ?',
            whereArgs: [itemId],
          );

          notifyListeners();
          return;
        }
      }
    }
  }

  Future<void> updateNotepadContent(String tabId, String content) async {
    for (var category in _categories) {
      for (var tab in category.tabs) {
        if (tab.id == tabId) {
          tab.notepadContent = content;

          final db = await _db.database;
          await db.update(
            'tabs',
            {'notepadContent': content},
            where: 'id = ?',
            whereArgs: [tabId],
          );

          notifyListeners();
          return;
        }
      }
    }
  }

  Future<void> updateContentNotepad(String tabId, String content) async {
    for (var category in _categories) {
      for (var tab in category.tabs) {
        if (tab.id == tabId) {
          tab.contentNotepad = content;

          final db = await _db.database;
          await db.update(
            'tabs',
            {'contentNotepad': content},
            where: 'id = ?',
            whereArgs: [tabId],
          );

          notifyListeners();
          return;
        }
      }
    }
  }

  Future<void> addImage(String tabId, String fileName) async {
    for (var category in _categories) {
      for (var tab in category.tabs) {
        if (tab.id == tabId) {
          tab.imagePaths = [...tab.imagePaths, fileName];

          final db = await _db.database;
          await db.insert('images', {
            'id': fileName,
            'tabId': tabId,
            'fileName': fileName,
            'fileSize': 0,
            'sortOrder': tab.imagePaths.length - 1,
          });

          notifyListeners();
          return;
        }
      }
    }
  }

  Future<void> removeImage(String tabId, int index) async {
    for (var category in _categories) {
      for (var tab in category.tabs) {
        if (tab.id == tabId) {
          final imagePath = tab.imagePaths[index];
          tab.imagePaths = List.from(tab.imagePaths)..removeAt(index);

          final db = await _db.database;
          await db.delete('images', where: 'id = ?', whereArgs: [imagePath]);

          notifyListeners();
          return;
        }
      }
    }
  }

  Future<void> addChecklistItem(String tabId, String title) async {
    for (var category in _categories) {
      for (var tab in category.tabs) {
        if (tab.id == tabId) {
          final newItem = Note(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title,
          );
          tab.checklistItems.add(newItem);

          final db = await _db.database;
          await db.insert('checklist_items', {
            'id': newItem.id,
            'tabId': tabId,
            'title': title,
            'checkboxState': 0,
            'timerState': 0,
            'timerDuration': null,
            'alarmSoundPath': null, // No sound for regular items
            'isLoopingAlarm': 0,
            'timerEndTime': null,
            'timerStartTime': null,
            'elapsedTime': null,
            'sortOrder': tab.checklistItems.length - 1,
          });

          notifyListeners();
          return;
        }
      }
    }
  }

  Future<void> deleteChecklistItem(String tabId, String itemId) async {
    for (var category in _categories) {
      for (var tab in category.tabs) {
        if (tab.id == tabId) {
          tab.checklistItems.removeWhere((item) => item.id == itemId);

          final db = await _db.database;
          await db.delete(
            'checklist_items',
            where: 'id = ?',
            whereArgs: [itemId],
          );

          notifyListeners();
          return;
        }
      }
    }
  }

  Future<void> updateChecklistItemTitle(
    String tabId,
    String itemId,
    String newTitle,
  ) async {
    for (var category in _categories) {
      for (var tab in category.tabs) {
        if (tab.id == tabId) {
          final index = tab.checklistItems.indexWhere(
            (item) => item.id == itemId,
          );
          if (index != -1) {
            tab.checklistItems[index] = tab.checklistItems[index].copyWith(
              title: newTitle,
            );

            final db = await _db.database;
            await db.update(
              'checklist_items',
              {'title': newTitle},
              where: 'id = ?',
              whereArgs: [itemId],
            );

            notifyListeners();
          }
          return;
        }
      }
    }
  }

  Future<void> addChecklistItemWithTimer(String tabId, Note timerItem) async {
    for (var category in _categories) {
      for (var tab in category.tabs) {
        if (tab.id == tabId) {
          // Add to in-memory list FIRST so UI updates immediately
          tab.checklistItems.add(timerItem);

          // Notify UI of the change right away
          notifyListeners();

          // Then save to database in the background
          final db = await _db.database;
          await db.insert('checklist_items', {
            'id': timerItem.id,
            'tabId': tabId,
            'title': timerItem.title,
            'checkboxState': timerItem.checkboxState.index,
            'timerState': timerItem.timerState.index,
            'timerDuration': timerItem.timerDuration?.inMilliseconds,
            'alarmSoundPath':
                timerItem.alarmSoundPath, // This can be null for default
            'isLoopingAlarm': timerItem.isLoopingAlarm ? 1 : 0,
            'timerEndTime': timerItem.timerEndTime?.toIso8601String(),
            'timerStartTime': timerItem.timerStartTime?.toIso8601String(),
            'elapsedTime': timerItem.elapsedTime?.inMilliseconds,
            'sortOrder': tab.checklistItems.length - 1,
          });

          return;
        }
      }
    }
  }

  Future<void> updateNote(Note updatedNote) async {
    for (var category in _categories) {
      for (var tab in category.tabs) {
        final index = tab.checklistItems.indexWhere(
          (item) => item.id == updatedNote.id,
        );
        if (index != -1) {
          tab.checklistItems[index] = updatedNote;

          final db = await _db.database;
          await db.update(
            'checklist_items',
            {
              'title': updatedNote.title,
              'checkboxState': updatedNote.checkboxState.index,
              'timerState': updatedNote.timerState.index,
              'timerDuration': updatedNote.timerDuration?.inMilliseconds,
              'alarmSoundPath': updatedNote.alarmSoundPath, // This can be null
              'isLoopingAlarm': updatedNote.isLoopingAlarm ? 1 : 0,
              'timerEndTime': updatedNote.timerEndTime?.toIso8601String(),
              'timerStartTime': updatedNote.timerStartTime?.toIso8601String(),
              'elapsedTime': updatedNote.elapsedTime?.inMilliseconds,
            },
            where: 'id = ?',
            whereArgs: [updatedNote.id],
          );

          notifyListeners();
          return;
        }
      }
    }
  }
}
