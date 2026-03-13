// lib/features/settings/views/settings_view.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:modular_journal/core/database/database_service.dart';
import 'package:modular_journal/data/services/backup_service.dart';
import 'package:modular_journal/data/services/image_storage_service.dart';
import 'package:path_provider/path_provider.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final BackupService _backupService = BackupService();
  bool _isExporting = false;
  bool _isImporting = false;

  Future<void> _exportBackup() async {
    setState(() => _isExporting = true);

    try {
      final backupPath = await _backupService.exportBackup();

      if (backupPath != null && mounted) {
        _showSuccessDialog(
          'Backup Created Successfully',
          'Your journal has been backed up to:\n$backupPath',
        );
      } else {
        throw Exception('Backup failed');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Export Failed', e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _importBackup() async {
    setState(() => _isImporting = true);

    try {
      // Pick a backup file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;

        // Confirm before importing
        final confirm = await _showConfirmDialog(
          'Import Backup',
          'This will replace all your current data. Make sure you have a backup of your current journal if needed.\n\nContinue?',
        );

        if (confirm == true) {
          final success = await _backupService.importBackup(filePath);

          if (success && mounted) {
            _showSuccessDialog(
              'Import Successful',
              'Your journal has been restored from backup.\n\nThe app will restart to apply changes.',
            );

            // Optional: restart the app or refresh data
            // You might want to trigger a reload of your ViewModel here
          } else {
            throw Exception('Import failed');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Import Failed', e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text('Error: $error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Backup Section Header
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Backup & Restore',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // Export Backup Button
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.backup, color: Colors.blue),
              ),
              title: const Text('Export Backup'),
              subtitle: const Text('Save all your journal data to a ZIP file'),
              trailing: _isExporting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward),
              onTap: _isExporting || _isImporting ? null : _exportBackup,
            ),
          ),

          // Import Backup Button
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.restore, color: Colors.green),
              ),
              title: const Text('Import Backup'),
              subtitle: const Text('Restore your journal from a backup file'),
              trailing: _isImporting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward),
              onTap: _isExporting || _isImporting ? null : _importBackup,
            ),
          ),

          const Divider(height: 32),

          // Info Section
          Card(
            color: Colors.grey.shade900,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About Backups',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Backups include all your categories, tabs, notes, timers, and images.\n'
                    '• Export creates a ZIP file in your Downloads folder.\n'
                    '• Import replaces all current data with the backup.\n'
                    '• Always keep a copy of your backups in a safe place.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          ElevatedButton(
            onPressed: () async {
              final dbDir = await DatabaseService().getAppDataDirectory();
              final imgDir = await ImageStorageService().getImagesDirectory();

              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Storage Locations'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Database: $dbDir'),
                      const SizedBox(height: 8),
                      Text('Images: $imgDir'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Show Storage Locations'),
          ),
        ],
      ),
    );
  }
}
