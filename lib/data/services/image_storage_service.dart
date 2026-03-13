// lib/core/services/image_storage_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageStorageService {
  static final ImageStorageService _instance = ImageStorageService._internal();
  factory ImageStorageService() => _instance;
  ImageStorageService._internal();

  // Get the app's data directory (same as DatabaseService)
  Future<String> getAppDataDirectory() async {
    if (Platform.isWindows) {
      // For Windows, use the directory where the executable is located
      final executablePath = Platform.resolvedExecutable;
      final appDir = path.dirname(executablePath);

      // Create a 'data' subfolder to keep things organized
      final dataDir = path.join(appDir, 'data');
      final dataDirectory = Directory(dataDir);

      if (!await dataDirectory.exists()) {
        await dataDirectory.create(recursive: true);
        debugPrint('📁 Created data directory: $dataDir');
      }

      return dataDir;
    } else {
      // For other platforms, fallback to app documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      final appDir = path.join(documentsDir.path, 'CrocNotes');
      final appDirectory = Directory(appDir);

      if (!await appDirectory.exists()) {
        await appDirectory.create(recursive: true);
      }

      return appDir;
    }
  }

  // Get the images directory (inside the app data folder)
  Future<String> getImagesDirectory() async {
    final appDir = await getAppDataDirectory();
    final imagesDir = Directory(path.join(appDir, 'images'));

    debugPrint('🔍 ImageStorageService: Images directory: ${imagesDir.path}');

    if (!await imagesDir.exists()) {
      debugPrint('📁 ImageStorageService: Creating images directory');
      await imagesDir.create(recursive: true);
    }

    return imagesDir.path;
  }

  // Save an image and return the filename
  Future<String> saveImage(File sourceImage, {String? customName}) async {
    debugPrint('💾 ImageStorageService: Attempting to save image');
    debugPrint('   Source image path: ${sourceImage.path}');
    debugPrint('   Source image exists: ${await sourceImage.exists()}');

    if (!await sourceImage.exists()) {
      debugPrint('❌ ImageStorageService: Source image does not exist!');
      throw Exception('Source image file does not exist');
    }

    final imagesDir = await getImagesDirectory();
    final fileName =
        customName ?? 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final destinationPath = path.join(imagesDir, fileName);

    debugPrint('   Destination path: $destinationPath');

    try {
      await sourceImage.copy(destinationPath);

      // Verify the copy worked
      final savedFile = File(destinationPath);
      if (await savedFile.exists()) {
        final savedSize = await savedFile.length();
        debugPrint('✅ ImageStorageService: Image saved successfully');
        debugPrint('   Saved file size: $savedSize bytes');
        debugPrint('   Saved filename: $fileName');
        debugPrint('   Saved to: $destinationPath');
      }

      return fileName;
    } catch (e) {
      debugPrint('❌ ImageStorageService: Error saving image: $e');
      rethrow;
    }
  }

  // Get the full path for displaying an image
  Future<File?> getImageFile(String relativePath) async {
    if (relativePath.isEmpty) return null;

    final imagesDir = await getImagesDirectory();
    final fullPath = path.join(imagesDir, relativePath);
    final file = File(fullPath);

    if (await file.exists()) {
      return file;
    }
    return null;
  }

  // Delete an image
  Future<void> deleteImage(String fileName) async {
    if (fileName.isEmpty) return;

    final imagesDir = await getImagesDirectory();
    final fullPath = path.join(imagesDir, fileName);
    final file = File(fullPath);

    if (await file.exists()) {
      await file.delete();
      debugPrint('🗑️ Deleted image: $fileName');
    }
  }

  // Get all images for export
  Future<Map<String, File>> getAllImagesForExport() async {
    final imagesDir = await getImagesDirectory();
    final images = <String, File>{};

    if (await Directory(imagesDir).exists()) {
      await for (final entity in Directory(imagesDir).list()) {
        if (entity is File) {
          final fileName = path.basename(entity.path);
          images[fileName] = entity;
        }
      }
      debugPrint('📤 Found ${images.length} images for export');
    }

    return images;
  }

  // Import an image from backup
  Future<String> importImage(File sourceImage, String fileName) async {
    final imagesDir = await getImagesDirectory();
    final destinationPath = path.join(imagesDir, fileName);

    await Directory(imagesDir).create(recursive: true);
    await sourceImage.copy(destinationPath);

    return fileName;
  }
}
