import 'package:flutter/material.dart';
import 'package:modular_journal/features/notes/models/tab.dart';

class Category {
  final String id;
  String name;
  Color color;
  List<ContentTab> tabs;
  bool isExpanded;

  Category({
    required this.id,
    required this.name,
    required this.color,
    this.tabs = const [],
    this.isExpanded = true,
  });

  // Get pinned tabs in this category
  List<ContentTab> get pinnedTabs => tabs.where((tab) => tab.isPinned).toList();

  // Get unpinned tabs
  List<ContentTab> get unpinnedTabs =>
      tabs.where((tab) => !tab.isPinned).toList();

  // Predefined colors
  static const List<Color> availableColors = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.brown,
    Colors.grey,
  ];
}
