import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:modular_journal/core/database/database_service.dart';
import 'package:modular_journal/data/services/backup_service.dart';
import 'package:modular_journal/data/services/image_storage_service.dart';
import 'package:permission_handler/permission_handler.dart';

class MobileSettingsView extends StatefulWidget {
  const MobileSettingsView({super.key});

  @override
  State<MobileSettingsView> createState() => _MobileSettingsViewState();
}

class _MobileSettingsViewState extends State<MobileSettingsView> {
  bool _isExporting = false;
  bool _isImporting = false;
  PermissionStatus _storagePermissionStatus = PermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    if (Platform.isAndroid) {
      debugPrint('=== Checking Permission Status ===');

      // For Android 11+
      final manageStorage = await Permission.manageExternalStorage.status;
      debugPrint('Manage external storage: $manageStorage');

      // For Android 10 and below
      final storage = await Permission.storage.status;
      debugPrint('Storage permission: $storage');

      // For Android 13+
      final photos = await Permission.photos.status;
      debugPrint('Photos permission: $photos');

      // Determine overall permission status
      PermissionStatus overallStatus;
      if (manageStorage.isGranted || storage.isGranted || photos.isGranted) {
        overallStatus = PermissionStatus.granted;
      } else {
        overallStatus = PermissionStatus.denied;
      }

      setState(() {
        _storagePermissionStatus = overallStatus;
      });
    }
  }

  Future<void> _requestPermission() async {
    if (Platform.isAndroid) {
      try {
        PermissionStatus status;

        // Try the most appropriate permission for the Android version
        if (await Permission.manageExternalStorage.isPermanentlyDenied) {
          _showPermissionDialog();
          return;
        }

        // Request MANAGE_EXTERNAL_STORAGE for Android 11+
        status = await Permission.manageExternalStorage.request();
        debugPrint('Manage external storage request result: $status');

        if (!status.isGranted) {
          // Fallback to storage permission
          status = await Permission.storage.request();
          debugPrint('Storage permission request result: $status');
        }

        setState(() {
          _storagePermissionStatus = status;
        });

        if (status.isPermanentlyDenied) {
          _showPermissionDialog();
        }
      } catch (e) {
        debugPrint('Error requesting permission: $e');
        await _checkPermissionStatus();
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.settings, color: Colors.blue, size: 48),
        content: const Text(
          'Storage permission is required for backup features. '
          'Please enable it in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showPermissionInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.info, color: Colors.blue, size: 48),
        content: const Text(
          'Storage permission is already granted.\n\n'
          'You can revoke it in system settings if needed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('App Settings'),
          ),
        ],
      ),
    );
  }

  void _showPermissionRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.security, color: Colors.orange, size: 48),
        content: const Text(
          'Storage permission is required to backup your data.\n\n'
          'Please enable it using the toggle above.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup() async {
    if (Platform.isAndroid && !_storagePermissionStatus.isGranted) {
      _showPermissionRequiredDialog();
      return;
    }

    setState(() => _isExporting = true);

    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [CircularProgressIndicator()],
        ),
      ),
    );

    try {
      final backupService = BackupService();
      final path = await backupService.exportBackup();

      Navigator.pop(context); // Close loading dialog

      if (mounted) {
        if (path != null) {
          _showSuccessDialog(context, 'Backup saved to Downloads folder');
        } else {
          _showErrorDialog(context, 'Failed to create backup');
        }
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      if (mounted) {
        _showErrorDialog(context, 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _importBackup() async {
    if (Platform.isAndroid && !_storagePermissionStatus.isGranted) {
      _showPermissionRequiredDialog();
      return;
    }

    setState(() => _isImporting = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result != null && mounted) {
        // Show confirm dialog
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Import Backup'),
            content: const Text(
              'This will replace all current data. Continue?',
            ),
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

        if (confirm == true) {
          // Show loading dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Restoring backup...'),
                ],
              ),
            ),
          );

          final backupService = BackupService();
          final success = await backupService.importBackup(
            result.files.single.path!,
          );

          Navigator.pop(context); // Close loading dialog

          if (mounted) {
            if (success) {
              _showSuccessDialog(context, 'Backup restored successfully');
            } else {
              _showErrorDialog(context, 'Failed to restore backup');
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(context, 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasPermission = Platform.isAndroid
        ? _storagePermissionStatus.isGranted
        : true; // Windows always has permission

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),

          // Permission Section (Android only)
          if (Platform.isAndroid) ...[
            _buildSectionHeader(context, 'Permissions'),

            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: hasPermission
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        hasPermission ? Icons.check_circle : Icons.security,
                        color: hasPermission ? Colors.green : Colors.orange,
                      ),
                    ),
                    title: const Text('Storage Permission'),
                    subtitle: Text(
                      hasPermission
                          ? 'Permission granted - Backup available'
                          : 'Required for backup features',
                      style: TextStyle(
                        color: hasPermission ? Colors.green : Colors.orange,
                      ),
                    ),
                    value: hasPermission,
                    onChanged: (bool value) async {
                      debugPrint(
                        '🔘 Toggle pressed! Current status: $_storagePermissionStatus',
                      );

                      if (!hasPermission) {
                        await _requestPermission();
                        await _checkPermissionStatus();
                      } else {
                        _showPermissionInfoDialog();
                      }
                    },
                    activeColor: Colors.green,
                  ),

                  // Manual request button for testing
                  if (!hasPermission)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          debugPrint('📢 Manual request button pressed');
                          await _requestPermission();
                          await _checkPermissionStatus();
                        },
                        icon: const Icon(Icons.security),
                        label: const Text('Request Permission Manually'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const Divider(height: 32),
          ],

          // Backup section
          _buildSectionHeader(context, 'Backup & Restore'),

          // Export Backup Button
          _buildSettingsCard(
            icon: Icons.backup,
            iconColor: Colors.blue,
            title: 'Export Backup',
            subtitle: hasPermission
                ? 'Save your data to a ZIP file'
                : 'Enable storage permission first',
            isLoading: _isExporting,
            enabled: hasPermission && !_isExporting && !_isImporting,
            onTap: hasPermission ? _exportBackup : null,
          ),

          // Import Backup Button
          _buildSettingsCard(
            icon: Icons.restore,
            iconColor: Colors.green,
            title: 'Import Backup',
            subtitle: hasPermission
                ? 'Restore from a backup file'
                : 'Enable storage permission first',
            isLoading: _isImporting,
            enabled: hasPermission && !_isExporting && !_isImporting,
            onTap: hasPermission ? _importBackup : null,
          ),

          // Permission reminder if not granted
          if (Platform.isAndroid && !hasPermission) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade300),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Enable storage permission above to use backup features',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Divider(height: 32),

          // Storage info
          _buildSectionHeader(context, 'Storage'),

          FutureBuilder<String>(
            future: DatabaseService().getImagesDirectory(),
            builder: (context, snapshot) {
              final path = snapshot.data ?? 'Loading...';
              return _buildInfoCard(
                icon: Icons.folder,
                title: 'Images Location',
                content: path,
              );
            },
          ),

          FutureBuilder<int>(
            future: _getImageCount(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return _buildInfoCard(
                icon: Icons.image,
                title: 'Stored Images',
                content: '$count images',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isLoading,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: iconColor,
                  ),
                )
              : Icon(icon, color: iconColor),
        ),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: enabled ? null : Colors.grey.shade600),
        ),
        trailing: enabled
            ? const Icon(Icons.arrow_forward_ios, size: 16)
            : Icon(Icons.lock, size: 16, color: Colors.grey.shade600),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<int> _getImageCount() async {
    final storage = ImageStorageService();
    final images = await storage.getAllImagesForExport();
    return images.length;
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.error, color: Colors.red, size: 48),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
