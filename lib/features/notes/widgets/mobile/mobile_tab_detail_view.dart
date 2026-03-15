import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/tab.dart';
import '../../models/category.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
