import 'package:flutter/material.dart';
import 'tab.dart';

class Category {
  String id;
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

  // Convert to JSON for database
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'colorValue': color.value,
    'isExpanded': isExpanded ? 1 : 0,
  };

  // Create from JSON
  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'],
    name: json['name'],
    color: Color(json['colorValue']),
    isExpanded: (json['isExpanded'] as int?) == 1,
  );
}
