// lib/features/notes/widgets/bottom_notepad.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:modular_journal/core/database/database_service.dart';
import 'package:modular_journal/data/services/image_storage_service.dart';
import 'package:modular_journal/features/notes/widgets/collapsible_toolbar.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:super_clipboard/super_clipboard.dart';
import '../models/tab.dart';
import '../viewmodels/notes_viewmodel.dart';
import 'package:modular_journal/main.dart'
    show cachedImagesDirectory; // Import if using global

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
  final ImageStorageService _imageStorage = ImageStorageService();
  final DatabaseService _db = DatabaseService();
  final Map<String, FileImage> _imageProviderCache = {};

  // Cache the images directory for synchronous access
  String? _cachedImagesDir;

  // Debounce variables
  DateTime _lastPasteTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _pasteDebounceDuration = 500;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _currentTabId = widget.tab.id;
    _initializeController();
    _focusNode.addListener(_onFocusChange);
  }

  // Synchronous image provider - NO FUTURES, NO WAITING!
  ImageProvider? _createImageProvider(String imageIdentifier) {
    // Check cache first
    if (_imageProviderCache.containsKey(imageIdentifier)) {
      return _imageProviderCache[imageIdentifier];
    }

    // If it's already a full path, use FileImage directly
    if (imageIdentifier.startsWith(RegExp(r'^[A-Z]:|^/'))) {
      final file = File(imageIdentifier);
      if (file.existsSync()) {
        final provider = FileImage(file);
        _imageProviderCache[imageIdentifier] = provider;
        return provider;
      }
      return null;
    }

    // If it's a data URI, let Quill handle it
    if (imageIdentifier.startsWith('data:image')) {
      return null;
    }

    // Use the GLOBAL cached path - SYNCHRONOUS, AVAILABLE IMMEDIATELY!
    final fullPath = path.join(cachedImagesDirectory, imageIdentifier);
    final file = File(fullPath);

    if (file.existsSync()) {
      final provider = FileImage(file);
      _imageProviderCache[imageIdentifier] = provider;
      debugPrint('🖼️ Cached: $imageIdentifier');
      return provider;
    } else {
      debugPrint('❌ Image not found: $fullPath');
    }

    return null;
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _setupPasteListener();
    } else {
      HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    }
  }

  void _setupPasteListener() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final bool isControlPressed =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    final bool isVKey = event.logicalKey == LogicalKeyboardKey.keyV;

    if (isControlPressed && isVKey) {
      final now = DateTime.now();
      if (now.difference(_lastPasteTime).inMilliseconds <
          _pasteDebounceDuration) {
        return true;
      }
      _lastPasteTime = now;
      _handlePaste();
      return true;
    }
    return false;
  }

  Future<void> _handlePaste() async {
    debugPrint('Handling paste operation');

    try {
      final clipboard = SystemClipboard.instance;
      if (clipboard == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Clipboard not available'),
              duration: Duration(seconds: 1),
            ),
          );
        }
        return;
      }

      final reader = await clipboard.read();
      bool imageFound = false;

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

          final completer = Completer<Uint8List?>();

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

          final imageBytes = await completer.future;

          if (imageBytes != null && imageBytes.isNotEmpty) {
            imageFound = true;

            // Determine extension based on format
            String extension = 'png';
            if (format == Formats.jpeg) {
              extension = 'jpg';
            } else if (format == Formats.bmp) {
              extension = 'bmp';
            } else if (format == Formats.tiff) {
              extension = 'tiff';
            } else if (format == Formats.webp) {
              extension = 'webp';
            } else if (format == Formats.gif) {
              extension = 'gif';
            }

            // Create a unique filename
            final fileName =
                'pasted_${DateTime.now().millisecondsSinceEpoch}.$extension';

            // Save directly to your images folder
            final imagesDir = await _imageStorage.getImagesDirectory();
            final imagePath = path.join(imagesDir, fileName);

            // Write the file directly
            final imageFile = File(imagePath);
            await imageFile.writeAsBytes(imageBytes);

            debugPrint('✅ Image saved directly to: $imagePath');

            // Insert the FILENAME ONLY into Quill
            final index = _controller.selection.baseOffset;
            if (index >= 0) {
              _controller.document.insert(
                index,
                BlockEmbed.image(fileName), // Store just the filename!
              );

              // Save the filename to database
              final viewModel = Provider.of<NotesViewModel>(
                context,
                listen: false,
              );
              await viewModel.addImage(widget.tab.id, fileName);

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
        if (reader.canProvide(Formats.plainText)) {
          return; // Let Quill handle text paste
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
          } catch (e) {}
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

    // OPTIMIZATION: Debounce auto-save
    _controller.document.changes.listen((event) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        if (_controller.document.isEmpty()) {
          final viewModel = Provider.of<NotesViewModel>(context, listen: false);
          viewModel.updateContentNotepad(widget.tab.id, '');
          return;
        }

        final viewModel = Provider.of<NotesViewModel>(context, listen: false);
        final jsonContent = _controller.document.toDelta().toJson();
        viewModel.updateContentNotepad(widget.tab.id, jsonEncode(jsonContent));
      });
    });
  }

  Timer? _debounceTimer;

  @override
  void didUpdateWidget(BottomNotepad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tab.id != widget.tab.id) {
      _currentTabId = widget.tab.id;
      _controller.dispose();
      HardwareKeyboard.instance.removeHandler(_handleKeyEvent);

      _imageProviderCache.clear();

      _initializeController();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _imageProviderCache.clear();

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
          CollapsibleToolbar(
            title: const Row(
              children: [
                Text(
                  'Content Notepad',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Spacer(),
              ],
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

                // Use onImageInsertCallback to insert filename only
                embedButtons: FlutterQuillEmbeds.toolbarButtons(
                  imageButtonOptions: QuillToolbarImageButtonOptions(
                    imageButtonConfig: QuillToolbarImageConfig(
                      onImageInsertCallback:
                          (String imagePath, QuillController controller) async {
                            debugPrint(
                              '🖼️ Image insertion requested: $imagePath',
                            );

                            try {
                              final file = File(imagePath);
                              if (!await file.exists()) {
                                debugPrint(
                                  '❌ Image file does not exist: $imagePath',
                                );
                                return;
                              }

                              // Save using your ImageStorageService - returns just the filename
                              final fileName = await _imageStorage.saveImage(
                                file,
                              );
                              debugPrint(
                                '✅ Image saved with filename: $fileName',
                              );

                              // Save to database (filename only)
                              final viewModel = Provider.of<NotesViewModel>(
                                context,
                                listen: false,
                              );
                              await viewModel.addImage(widget.tab.id, fileName);

                              // Insert the image with the FILENAME ONLY
                              final index = controller.selection.baseOffset;
                              if (index >= 0) {
                                controller.document.insert(
                                  index,
                                  BlockEmbed.image(
                                    fileName,
                                  ), // Store just the filename!
                                );
                                debugPrint(
                                  '✅ Inserted image with filename only',
                                );
                              }
                            } catch (e) {
                              debugPrint('❌ Error saving image: $e');
                            }
                          },
                    ),
                  ),
                ),

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
              child: RepaintBoundary(
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
                    embedBuilders: [
                      // Use the default image embed builder
                      // We'll customize it via imageProviderBuilder instead of custom builder
                      ...kIsWeb
                          ? FlutterQuillEmbeds.editorWebBuilders(
                              imageEmbedConfig: QuillEditorImageEmbedConfig(
                                imageProviderBuilder: (context, imageUrl) {
                                  return _createImageProvider(imageUrl);
                                },
                              ),
                            )
                          : FlutterQuillEmbeds.editorBuilders(
                              imageEmbedConfig: QuillEditorImageEmbedConfig(
                                imageProviderBuilder: (context, imageUrl) {
                                  return _createImageProvider(imageUrl);
                                },
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
