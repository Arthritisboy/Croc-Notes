import 'dart:io';
import 'package:flutter/material.dart';
import 'package:win32_registry/win32_registry.dart';

class StartupService {
  static final StartupService _instance = StartupService._internal();
  factory StartupService() => _instance;
  StartupService._internal();

  static const String _registryPath =
      r'Software\Microsoft\Windows\CurrentVersion\Run';
  static const String _appName = 'CrocNotes';

  // Check if app is set to run at startup
  Future<bool> isStartupEnabled() async {
    if (!Platform.isWindows) return false;

    RegistryKey? key;
    try {
      // Open the key using Registry.openPath
      key = Registry.openPath(
        RegistryHive.currentUser,
        path: _registryPath,
        desiredAccessRights: AccessRights.readOnly,
      );

      // Get the value - returns RegistryValue?
      final registryValue = key.getValue(_appName);

      // RegistryValue likely has a 'data' or 'value' field
      // Let's print it to see what's available
      if (registryValue != null) {
        debugPrint('Registry value found: ${registryValue.toString()}');
        // Try to access the data - might be .data or .value
        // For now, just check if it's not null
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking startup status: $e');
      return false;
    } finally {
      key?.close();
    }
  }

  // Enable/disable startup
  Future<void> setStartupEnabled(bool enabled) async {
    if (!Platform.isWindows) return;

    RegistryKey? key;
    try {
      if (enabled) {
        // Open or create the key with write access
        key = Registry.openPath(
          RegistryHive.currentUser,
          path: _registryPath,
          desiredAccessRights: AccessRights.writeOnly,
        );

        // Get the path to the executable
        final exePath = Platform.resolvedExecutable;

        // Create the registry value
        key.createValue(
          RegistryValue(_appName, RegistryValueType.string, exePath),
        );

        debugPrint('✅ Added to startup: $exePath');
      } else {
        // Open key with write access to delete
        key = Registry.openPath(
          RegistryHive.currentUser,
          path: _registryPath,
          desiredAccessRights: AccessRights.writeOnly,
        );

        key.deleteValue(_appName);
        debugPrint('✅ Removed from startup');
      }
    } catch (e) {
      debugPrint('❌ Error setting startup: $e');
    } finally {
      key?.close();
    }
  }
}
