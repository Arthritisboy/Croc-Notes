import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:modular_journal/core/database/database_service.dart';
import 'package:path/path.dart' as path;

class ImageService {
  final DatabaseService _db = DatabaseService();

  // Pick and save an image
  Future<String?> pickAndSaveImage(String tabId) async {
    try {
      // Pick image
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024, // Resize to save space
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      // Generate unique filename
      final imagesDir = await _db.getImagesDirectory();
      final fileExt = path.extension(pickedFile.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$fileExt';
      final filePath = path.join(imagesDir, fileName);

      // Copy file to app directory
      final file = File(pickedFile.path);
      await file.copy(filePath);

      // Save reference in database
      final db = await _db.database;
      await db.insert('images', {
        'id': fileName,
        'tabId': tabId,
        'filePath': filePath,
        'fileName': fileName,
        'fileSize': await File(filePath).length(),
        'sortOrder': 0,
      });

      return fileName;
    } catch (e) {
      print('Error saving image: $e');
      return null;
    }
  }

  // Load image for display
  Future<File?> getImageFile(String fileName) async {
    final imagesDir = await _db.getImagesDirectory();
    final filePath = path.join(imagesDir, fileName);
    final file = File(filePath);

    if (await file.exists()) {
      return file;
    }
    return null;
  }

  // Get all images for a tab
  Future<List<Map<String, dynamic>>> getImagesForTab(String tabId) async {
    final db = await _db.database;
    return await db.query(
      'images',
      where: 'tabId = ?',
      whereArgs: [tabId],
      orderBy: 'sortOrder ASC',
    );
  }

  // Delete image
  Future<void> deleteImage(String fileName) async {
    // Delete file
    final imagesDir = await _db.getImagesDirectory();
    final filePath = path.join(imagesDir, fileName);
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }

    // Delete database reference
    final db = await _db.database;
    await db.delete('images', where: 'id = ?', whereArgs: [fileName]);
  }
}
