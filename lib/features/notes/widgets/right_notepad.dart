// lib/features/notes/widgets/right_notepad.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:modular_journal/features/notes/widgets/collapsible_toolbar.dart';
import 'package:provider/provider.dart';
import '../models/tab.dart';
import '../viewmodels/notes_viewmodel.dart';

class RightNotepad extends StatefulWidget {
  final ContentTab tab;
  final Color categoryColor;

  const RightNotepad({
    super.key,
    required this.tab,
    required this.categoryColor,
  });

  @override
  State<RightNotepad> createState() => _RightNotepadState();
}

class _RightNotepadState extends State<RightNotepad> {
  late QuillController _controller;
  late FocusNode _focusNode;
  final ScrollController _scrollController = ScrollController();
  late String _currentTabId;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _currentTabId = widget.tab.id;
    _initializeController();
  }

  void _initializeController() {
    // Initialize Quill controller with existing content
    if (widget.tab.notepadContent.isNotEmpty &&
        widget.tab.notepadContent != '[]' &&
        widget.tab.notepadContent != '') {
      try {
        final content = widget.tab.notepadContent;
        List<dynamic>? deltaJson;

        if (content.startsWith('[') && content != '[]') {
          try {
            final parsed = jsonDecode(content);
            if (parsed is List) {
              deltaJson = parsed;
            }
          } catch (e) {
            // Not valid JSON, treat as plain text
          }
        }

        if (deltaJson != null && deltaJson.isNotEmpty) {
          final doc = Document.fromJson(deltaJson);
          _controller = QuillController(
            document: doc,
            selection: const TextSelection.collapsed(offset: 0),
          );
        } else {
          if (content.isNotEmpty && content != '[]') {
            _controller = QuillController.basic();
            _controller.document.insert(0, content);
          } else {
            _controller = QuillController.basic();
          }
        }
      } catch (e) {
        _controller = QuillController.basic();
      }
    } else {
      _controller = QuillController.basic();
    }

    // Listen to changes to save automatically
    _controller.document.changes.listen((event) {
      if (_controller.document.isEmpty()) {
        final viewModel = Provider.of<NotesViewModel>(context, listen: false);
        viewModel.updateNotepadContent(widget.tab.id, '');
        return;
      }

      final viewModel = Provider.of<NotesViewModel>(context, listen: false);
      final jsonContent = _controller.document.toDelta().toJson();
      viewModel.updateNotepadContent(widget.tab.id, jsonEncode(jsonContent));
    });
  }

  @override
  void didUpdateWidget(RightNotepad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tab.id != widget.tab.id) {
      _currentTabId = widget.tab.id;
      _controller.dispose();
      _initializeController();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: const BorderRadius.only(topRight: Radius.circular(8)),
      ),
      child: Column(
        children: [
          CollapsibleToolbar(
            title: const Text(
              'Notepad',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            categoryColor: widget.categoryColor,
            toolbar: QuillSimpleToolbar(
              controller: _controller,
              config: QuillSimpleToolbarConfig(
                toolbarIconAlignment: WrapAlignment.start,
                toolbarIconCrossAlignment: WrapCrossAlignment.center,
                toolbarSize: 40.0,

                showBoldButton: true,
                showItalicButton: true,
                showUnderLineButton: true,
                showStrikeThrough: true,
                showColorButton: true,
                showBackgroundColorButton: true,
                showClearFormat: true,
                showAlignmentButtons: true,
                showLeftAlignment: true,
                showCenterAlignment: true,
                showRightAlignment: true,
                showJustifyAlignment: true,
                showHeaderStyle: true,
                showListNumbers: true,
                showListBullets: true,
                showListCheck: true,
                showQuote: true,
                showIndent: true,
                showLink: true,
                showUndo: true,
                showRedo: true,
                showFontFamily: true,
                showFontSize: true,
                showDividers: true,

                showSmallButton: false,
                showInlineCode: false,
                showCodeBlock: false,
                showDirection: false,
                showSearchButton: false,
                showSubscript: false,
                showSuperscript: false,
                showLineHeightButton: false,

                color: widget.categoryColor.withOpacity(0.05),
                axis: Axis.horizontal,

                buttonOptions: QuillSimpleToolbarButtonOptions(
                  fontFamily: QuillToolbarFontFamilyButtonOptions(
                    items: {
                      'Arial': 'Arial',
                      'Courier New': 'Courier New',
                      'Georgia': 'Georgia',
                      'Times New Roman': 'Times New Roman',
                      'Verdana': 'Verdana',
                      'Roboto': 'Roboto',
                      'Clear': 'Clear',
                    },
                  ),
                  fontSize: QuillToolbarFontSizeButtonOptions(
                    items: {
                      '8': '8',
                      '9': '9',
                      '10': '10',
                      '11': '11',
                      '12': '12',
                      '14': '14',
                      '16': '16',
                      '18': '18',
                      '20': '20',
                      '22': '22',
                      '24': '24',
                      '26': '26',
                      '28': '28',
                      '36': '36',
                      '48': '48',
                      '72': '72',
                    },
                    initialValue: '12',
                  ),
                ),
              ),
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade300),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: QuillEditor(
                controller: _controller,
                focusNode: _focusNode,
                scrollController: _scrollController,
                config: QuillEditorConfig(
                  placeholder: 'Write your notes here...',
                  autoFocus: false,
                  expands: false,
                  padding: const EdgeInsets.all(8),
                  scrollable: true,
                  scrollBottomInset: 0.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
