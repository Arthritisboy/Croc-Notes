// lib/features/notes/widgets/bottom_notepad.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:super_clipboard/super_clipboard.dart';
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

  // Debounce variables
  DateTime _lastPasteTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _pasteDebounceDuration = 500; // milliseconds

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _currentTabId = widget.tab.id;
    _initializeController();

    // Add listener for paste events
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      // Register for paste events when focused
      _setupPasteListener();
    } else {
      // Remove handler when focus lost
      HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    }
  }

  void _setupPasteListener() {
    // Remove any existing handler first
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    // Add new handler
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  bool _handleKeyEvent(KeyEvent event) {
    // Only handle key down events
    if (event is! KeyDownEvent) return false;

    // Check for Ctrl+V (Windows/Linux) or Cmd+V (Mac)
    final bool isControlPressed =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    final bool isVKey = event.logicalKey == LogicalKeyboardKey.keyV;

    if (isControlPressed && isVKey) {
      // Debounce: prevent multiple rapid calls
      final now = DateTime.now();
      if (now.difference(_lastPasteTime).inMilliseconds <
          _pasteDebounceDuration) {
        debugPrint('Paste debounced');
        return true; // Event handled (debounced)
      }

      _lastPasteTime = now;
      _handlePaste();
      return true; // Event handled
    }

    return false; // Event not handled
  }

  Future<void> _handlePaste() async {
    debugPrint('Handling paste operation');

    try {
      final clipboard = SystemClipboard.instance;
      if (clipboard == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Clipboard not available on this platform'),
              duration: Duration(seconds: 1),
            ),
          );
        }
        return;
      }

      // Read from clipboard
      final reader = await clipboard.read();

      // Check for image formats using getFile API
      bool imageFound = false;

      // Try each image format
      final imageFormats = [
        Formats.png,
        Formats.jpeg,
        Formats.bmp,
        Formats.tiff,
        Formats.webp,
        Formats.gif,
      ];

      for (final format in imageFormats) {
        if (reader.canProvide(format)) {
          debugPrint('Found image format: $format');

          // Use a completer to handle the async file reading
          final completer = Completer<Uint8List?>();

          // Use getFile to read the image data
          reader.getFile(format, (file) async {
            try {
              final bytes = await file.readAll();
              completer.complete(bytes);
            } catch (e) {
              completer.completeError(e);
            } finally {
              file.close();
            }
          });

          // Wait for the file to be read
          final imageBytes = await completer.future;

          if (imageBytes != null && imageBytes.isNotEmpty) {
            imageFound = true;

            // Determine mime type based on format
            String mimeType = 'image/png';
            if (format == Formats.jpeg)
              mimeType = 'image/jpeg';
            else if (format == Formats.bmp)
              mimeType = 'image/bmp';
            else if (format == Formats.tiff)
              mimeType = 'image/tiff';
            else if (format == Formats.webp)
              mimeType = 'image/webp';
            else if (format == Formats.gif)
              mimeType = 'image/gif';

            // Insert image at current cursor position
            final base64Image = base64Encode(imageBytes);
            final index = _controller.selection.baseOffset;

            // Ensure we have a valid index
            if (index >= 0) {
              _controller.document.insert(
                index,
                BlockEmbed.image('data:$mimeType;base64,$base64Image'),
              );

              // Save to ViewModel's image list
              final timestamp = DateTime.now().millisecondsSinceEpoch;
              final fileName = 'pasted_image_$timestamp.png';
              final tempDir = await Directory.systemTemp.createTemp();
              final tempFile = File('${tempDir.path}/$fileName');
              await tempFile.writeAsBytes(imageBytes);

              final viewModel = Provider.of<NotesViewModel>(
                context,
                listen: false,
              );
              viewModel.addImage(widget.tab.id, tempFile.path);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Image pasted successfully'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            }

            break; // Exit loop once we've processed an image
          }
        }
      }

      if (!imageFound) {
        // Check for plain text as fallback
        if (reader.canProvide(Formats.plainText)) {
          debugPrint('No image found, letting Quill handle text paste');
          // Let Quill handle text paste normally
          return;
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No image found in clipboard'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error pasting image: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error pasting image: $e')));
      }
    }
  }

  void _initializeController() {
    // Initialize Quill controller with existing content
    if (widget.tab.contentNotepad.isNotEmpty &&
        widget.tab.contentNotepad != '[]' &&
        widget.tab.contentNotepad != '') {
      try {
        final content = widget.tab.contentNotepad;
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
    if (oldWidget.tab.id != widget.tab.id) {
      _currentTabId = widget.tab.id;
      _controller.dispose();
      HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
      _initializeController();
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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

        final index = _controller.selection.baseOffset;
        if (index >= 0) {
          _controller.document.insert(
            index,
            BlockEmbed.image('data:image/jpeg;base64,$base64Image'),
          );

          final viewModel = Provider.of<NotesViewModel>(context, listen: false);
          viewModel.addImage(widget.tab.id, pickedFile.path);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error inserting image: $e')));
      }
    }
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

          Divider(height: 1, color: Colors.grey.shade300),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: QuillEditor(
                controller: _controller,
                focusNode: _focusNode,
                scrollController: _scrollController,
                config: QuillEditorConfig(
                  placeholder:
                      'Write your content here... (Ctrl+V to paste images)',
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
