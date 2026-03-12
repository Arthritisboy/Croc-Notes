// lib/features/notes/widgets/bottom_notepad.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/tab.dart';
import '../viewmodels/notes_viewmodel.dart';

class BottomNotepad extends StatefulWidget {
  final ContentTab tab;
  final Color categoryColor;

  const BottomNotepad({
    super.key,
    required this.tab,
    required this.categoryColor,
  });

  @override
  State<BottomNotepad> createState() => _BottomNotepadState();
}

class _BottomNotepadState extends State<BottomNotepad> {
  late QuillController _controller;
  late FocusNode _focusNode;
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
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
    if (widget.tab.contentNotepad.isNotEmpty &&
        widget.tab.contentNotepad != '[]' &&
        widget.tab.contentNotepad != '') {
      try {
        // Try to parse the stored content
        final content = widget.tab.contentNotepad;
        List<dynamic>? deltaJson;

        // Check if it's a JSON string (stored as JSON)
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
          // Create document from JSON delta
          final doc = Document.fromJson(deltaJson);
          _controller = QuillController(
            document: doc,
            selection: const TextSelection.collapsed(offset: 0),
          );
        } else {
          // Treat as plain text (but only if not empty)
          if (content.isNotEmpty && content != '[]') {
            _controller = QuillController.basic();
            _controller.document.insert(0, content);
          } else {
            _controller = QuillController.basic();
          }
        }
      } catch (e) {
        // If all else fails, create empty controller
        _controller = QuillController.basic();
      }
    } else {
      _controller = QuillController.basic();
    }

    // Listen to changes to save automatically
    _controller.document.changes.listen((event) {
      if (_controller.document.isEmpty()) {
        // Save empty string instead of '[]'
        final viewModel = Provider.of<NotesViewModel>(context, listen: false);
        viewModel.updateContentNotepad(widget.tab.id, '');
        return;
      }

      final viewModel = Provider.of<NotesViewModel>(context, listen: false);
      final jsonContent = _controller.document.toDelta().toJson();
      viewModel.updateContentNotepad(widget.tab.id, jsonEncode(jsonContent));
    });
  }

  @override
  void didUpdateWidget(BottomNotepad oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the tab ID changed, we need to recreate the controller
    if (oldWidget.tab.id != widget.tab.id) {
      _currentTabId = widget.tab.id;
      _controller.dispose();
      _initializeController();
    }
  }

  Future<void> _insertImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await File(pickedFile.path).readAsBytes();
        final base64Image = base64Encode(bytes);

        // Insert image at current cursor position
        final index = _controller.selection.baseOffset;
        _controller.document.insert(
          index,
          BlockEmbed.image('data:image/jpeg;base64,$base64Image'),
        );

        // Save to ViewModel's image list for traditional storage
        final viewModel = Provider.of<NotesViewModel>(context, listen: false);
        viewModel.addImage(widget.tab.id, pickedFile.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error inserting image: $e')));
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
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Column(
        children: [
          QuillSimpleToolbar(
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

              embedButtons: FlutterQuillEmbeds.toolbarButtons(),

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
                  placeholder: 'Write your content here...',
                  autoFocus: false,
                  expands: false,
                  padding: const EdgeInsets.all(8),
                  scrollable: true,
                  scrollBottomInset: 0.0,
                  embedBuilders: kIsWeb
                      ? FlutterQuillEmbeds.editorWebBuilders()
                      : FlutterQuillEmbeds.editorBuilders(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
