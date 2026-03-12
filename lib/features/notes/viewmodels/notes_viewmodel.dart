import 'package:flutter/material.dart';
import 'package:modular_journal/core/database/database_service.dart';
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

  // Getters
  List<Category> get categories => _categories;
  Category? get selectedCategory => _selectedCategory;
  ContentTab? get selectedTab => _selectedTab;
  bool get showPinnedOnly => _showPinnedOnly;
  bool get isLoading => _isLoading;
  String? get error => _error;

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
      print('Loaded ${categoryMaps.length} categories'); // Debug print

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

        print(
          'Loaded ${tabMaps.length} tabs for category ${category.name}',
        ); // Debug print

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

          for (var itemMap in itemMaps) {
            tab.checklistItems.add(
              Note(
                id: itemMap['id'] as String,
                title: itemMap['title'] as String,
                checkboxState:
                    CheckboxState.values[itemMap['checkboxState'] as int],
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

      print('Data loaded successfully'); // Debug print
      notifyListeners();
    } catch (e) {
      print('Error loading data: $e');
      _error = e.toString();
      rethrow; // Rethrow so _init can catch it
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
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type "${category.name}" to confirm deletion:'),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: category.name,
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text == category.name) {
                Navigator.pop(context, true);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
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

    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tab'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type "${tabToDelete!.name}" to confirm deletion:'),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: tabToDelete.name,
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text == tabToDelete?.name) {
                Navigator.pop(context, true);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
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

  Future<void> addImage(String tabId, String imagePath) async {
    for (var category in _categories) {
      for (var tab in category.tabs) {
        if (tab.id == tabId) {
          tab.imagePaths = [...tab.imagePaths, imagePath];

          final db = await _db.database;
          await db.insert('images', {
            'id': imagePath,
            'tabId': tabId,
            'filePath': await _db.getImagesDirectory() + '/$imagePath',
            'fileName': imagePath,
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
}
