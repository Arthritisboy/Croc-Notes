import 'package:flutter/material.dart';
import '../models/note.dart';
import '../models/category.dart';
import '../models/tab.dart';

class NotesViewModel extends ChangeNotifier {
  // Data stores
  List<Category> _categories = [];

  // Selection state
  Category? _selectedCategory;
  ContentTab? _selectedTab;

  // Getters
  List<Category> get categories => _categories;
  Category? get selectedCategory => _selectedCategory;
  ContentTab? get selectedTab => _selectedTab;
  bool _showPinnedOnly = false;

  // Add this getter
  bool get showPinnedOnly => _showPinnedOnly;

  // Get all pinned tabs across all categories (for pinned section)
  List<ContentTab> get allPinnedTabs {
    List<ContentTab> pinned = [];
    for (var category in _categories) {
      pinned.addAll(category.pinnedTabs);
    }
    return pinned;
  }

  List<Category> get categoriesWithPinnedTabs {
    return _categories
        .where((category) => category.tabs.any((tab) => tab.isPinned))
        .toList();
  }

  NotesViewModel() {
    _loadSampleData();
  }

  void togglePinnedOnly() {
    _showPinnedOnly = !_showPinnedOnly;
    notifyListeners();
  }

  void reorderCategories(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final category = _categories.removeAt(oldIndex);
    _categories.insert(newIndex, category);
    notifyListeners();
  }

  void _loadSampleData() {
    // Create categories with tabs
    _categories = [
      Category(
        id: 'work',
        name: 'Work',
        color: Colors.blue,
        tabs: [
          ContentTab(
            id: 'work_projects',
            name: 'Projects',
            categoryId: 'work',
            isPinned: true,
            notepadContent:
                'This is the main notepad for Work Projects.\n\nUse this space for general notes and descriptions about your projects.',
            contentNotepad:
                'This is the content area for Work Projects.\n\nYou can write longer notes here and attach images below.',
            imagePaths: [],
            checklistItems: [
              Note(id: '1', title: 'Complete Q1 report'),
              Note(id: '2', title: 'Schedule team meeting'),
              Note(id: '3', title: 'Review pull requests'),
              Note(id: '4', title: 'Update documentation'),
            ],
          ),
          ContentTab(
            id: 'work_meetings',
            name: 'Meetings',
            categoryId: 'work',
            isPinned: false,
            notepadContent: 'Meeting notes and agendas go here.',
            contentNotepad: 'Detailed meeting minutes with action items.',
            imagePaths: [],
            checklistItems: [
              Note(id: '5', title: 'Prepare presentation'),
              Note(id: '6', title: 'Send meeting invite'),
              Note(id: '7', title: 'Take minutes'),
            ],
          ),
          ContentTab(
            id: 'work_tasks',
            name: 'Tasks',
            categoryId: 'work',
            isPinned: true,
            notepadContent: 'Daily task management area.',
            contentNotepad: 'Task details and progress notes.',
            imagePaths: ['sample.jpg'],
            checklistItems: [
              Note(id: '8', title: 'Morning standup'),
              Note(id: '9', title: 'Code review'),
              Note(id: '10', title: 'Write tests'),
              Note(id: '11', title: 'Deploy to staging'),
            ],
          ),
        ],
      ),
      Category(
        id: 'personal',
        name: 'Personal',
        color: Colors.green,
        tabs: [
          ContentTab(
            id: 'personal_journal',
            name: 'Journal',
            categoryId: 'personal',
            isPinned: true,
            notepadContent: 'Daily journal entries and reflections.',
            contentNotepad: 'Personal thoughts, experiences, and memories.',
            imagePaths: [],
            checklistItems: [
              Note(id: '12', title: 'Write today\'s entry'),
              Note(id: '13', title: 'Add photos from weekend'),
            ],
          ),
          ContentTab(
            id: 'personal_goals',
            name: 'Goals',
            categoryId: 'personal',
            isPinned: false,
            notepadContent: 'Personal goals and aspirations.',
            contentNotepad: 'Detailed plans for achieving goals.',
            imagePaths: [],
            checklistItems: [
              Note(id: '14', title: 'Exercise 3x this week'),
              Note(id: '15', title: 'Read 30 minutes daily'),
              Note(id: '16', title: 'Learn Flutter'),
            ],
          ),
        ],
      ),
      Category(
        id: 'ideas',
        name: 'Ideas',
        color: Colors.purple,
        tabs: [
          ContentTab(
            id: 'ideas_brainstorms',
            name: 'Brainstorms',
            categoryId: 'ideas',
            isPinned: false,
            notepadContent: 'Creative ideas and brainstorming.',
            contentNotepad: 'Detailed notes on potential projects.',
            imagePaths: [],
            checklistItems: [
              Note(id: '17', title: 'App idea: Journal app'),
              Note(id: '18', title: 'Blog post topics'),
            ],
          ),
        ],
      ),
    ];

    // Select first category and first tab by default
    _selectedCategory = _categories.first;
    _selectedTab = _selectedCategory!.tabs.first;

    notifyListeners();
  }

  // Toggle category expansion
  void toggleCategoryExpansion(String categoryId) {
    final category = _categories.firstWhere((c) => c.id == categoryId);
    category.isExpanded = !category.isExpanded;
    notifyListeners();
  }

  // Select category
  void selectCategory(String categoryId) {
    _selectedCategory = _categories.firstWhere((c) => c.id == categoryId);
    // Auto-select first tab of new category
    if (_selectedCategory!.tabs.isNotEmpty) {
      _selectedTab = _selectedCategory!.tabs.first;
    }
    notifyListeners();
  }

  // Select tab
  void selectTab(String tabId) {
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

  // Toggle tab pinned status
  void toggleTabPinned(String tabId) {
    for (var category in _categories) {
      for (var tab in category.tabs) {
        if (tab.id == tabId) {
          tab.isPinned = !tab.isPinned;
          notifyListeners();
          return;
        }
      }
    }
  }

  // Toggle checklist item
  void toggleChecklistItem(String tabId, String itemId) {
    for (var category in _categories) {
      for (var tab in category.tabs) {
        if (tab.id == tabId) {
          tab.toggleCheckbox(itemId);
          notifyListeners();
          return;
        }
      }
    }
  }

  // Update notepad content (right grid)
  void updateNotepadContent(String tabId, String content) {
    for (var category in _categories) {
      for (var tab in category.tabs) {
        if (tab.id == tabId) {
          tab.notepadContent = content;
          notifyListeners();
          return;
        }
      }
    }
  }

  // Update content notepad (bottom grid)
  void updateContentNotepad(String tabId, String content) {
    for (var category in _categories) {
      for (var tab in category.tabs) {
        if (tab.id == tabId) {
          tab.contentNotepad = content;
          notifyListeners();
          return;
        }
      }
    }
  }

  // Add image to tab
  void addImage(String tabId, String imagePath) {
    for (var category in _categories) {
      for (var tab in category.tabs) {
        if (tab.id == tabId) {
          tab.imagePaths = [...tab.imagePaths, imagePath];
          notifyListeners();
          return;
        }
      }
    }
  }

  // Remove image from tab
  void removeImage(String tabId, int index) {
    for (var category in _categories) {
      for (var tab in category.tabs) {
        if (tab.id == tabId) {
          tab.imagePaths = List.from(tab.imagePaths)..removeAt(index);
          notifyListeners();
          return;
        }
      }
    }
  }

  // Add checklist item
  void addChecklistItem(String tabId, String title) {
    for (var category in _categories) {
      for (var tab in category.tabs) {
        if (tab.id == tabId) {
          tab.addChecklistItem(title);
          notifyListeners();
          return;
        }
      }
    }
  }
}
