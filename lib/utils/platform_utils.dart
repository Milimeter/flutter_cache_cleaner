import 'dart:io';
import 'package:path/path.dart' as path;
import 'path_utils.dart';

/// Platform-specific utilities.
class PlatformUtils {
  /// Gets the Dart/Flutter pub cache directory.
  static String? getPubCachePath() {
    final env = Platform.environment;
    final pubCache = env['PUB_CACHE'];
    if (pubCache != null && pubCache.isNotEmpty) {
      return PathUtils.resolveAbsolute(pubCache);
    }

    // Default locations
    final home = PathUtils.getHomeDirectory();
    if (home.isEmpty) return null;

    if (Platform.isWindows) {
      return PathUtils.resolveAbsolute(path.join(home, 'AppData', 'Local', 'Pub', 'Cache'));
    } else {
      return PathUtils.resolveAbsolute(path.join(home, '.pub-cache'));
    }
  }

  /// Gets the Gradle global cache directory.
  static String? getGradleCachePath() {
    final home = PathUtils.getHomeDirectory();
    if (home.isEmpty) return null;

    if (Platform.isWindows) {
      return PathUtils.resolveAbsolute(path.join(home, '.gradle', 'caches'));
    } else {
      return PathUtils.resolveAbsolute(path.join(home, '.gradle', 'caches'));
    }
  }

  /// Gets the Xcode DerivedData directory (macOS only).
  static String? getXcodeDerivedDataPath() {
    if (!Platform.isMacOS) return null;

    final home = PathUtils.getHomeDirectory();
    if (home.isEmpty) return null;

    return PathUtils.resolveAbsolute(
        path.join(home, 'Library', 'Developer', 'Xcode', 'DerivedData'));
  }

  /// Gets the CocoaPods cache directory (macOS only).
  static String? getCocoaPodsCachePath() {
    if (!Platform.isMacOS) return null;

    final home = PathUtils.getHomeDirectory();
    if (home.isEmpty) return null;

    return PathUtils.resolveAbsolute(
        path.join(home, 'Library', 'Caches', 'CocoaPods'));
  }

  /// Gets default scan roots for the current platform.
  static List<String> getDefaultScanRoots() {
    final home = PathUtils.getHomeDirectory();
    if (home.isEmpty) return [];

    final roots = <String>[];
    final commonDirs = ['Developer', 'Projects', 'Documents'];

    for (final dir in commonDirs) {
      final fullPath = path.join(home, dir);
      if (PathUtils.isDirectory(fullPath)) {
        roots.add(fullPath);
      }
    }

    return roots;
  }

  /// Moves a file or directory to trash (OS-dependent).
  /// Returns true if successful, false otherwise.
  /// Falls back to direct deletion if trash is not available.
  static Future<bool> moveToTrash(String pathString) async {
    try {
      if (Platform.isMacOS) {
        // Use macOS trash command
        final result = await Process.run('osascript', [
          '-e',
          'tell application "Finder" to move POSIX file "$pathString" to trash'
        ]);
        return result.exitCode == 0;
      } else if (Platform.isLinux) {
        // Use gio trash (GNOME) or fallback
        final result = await Process.run('gio', ['trash', pathString]);
        if (result.exitCode == 0) return true;
        // Fallback to direct deletion
        return _deleteDirectly(pathString);
      } else if (Platform.isWindows) {
        // Use PowerShell to move to Recycle Bin
        final result = await Process.run('powershell', [
          '-Command',
          'Add-Type -AssemblyName Microsoft.VisualBasic; [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile("$pathString", \'OnlyErrorDialogs\', \'SendToRecycleBin\')'
        ]);
        return result.exitCode == 0;
      }
      // Fallback to direct deletion
      return _deleteDirectly(pathString);
    } catch (e) {
      return _deleteDirectly(pathString);
    }
  }

  /// Directly deletes a file or directory.
  static Future<bool> _deleteDirectly(String pathString) async {
    try {
      final entity = FileSystemEntity.typeSync(pathString);
      if (entity == FileSystemEntityType.directory) {
        await Directory(pathString).delete(recursive: true);
      } else if (entity == FileSystemEntityType.file) {
        await File(pathString).delete();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Gets the platform name as a string.
  static String getPlatformName() {
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    if (Platform.isWindows) return 'Windows';
    return Platform.operatingSystem;
  }
}

