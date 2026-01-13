import 'dart:io';
import 'package:path/path.dart' as path;

/// Utilities for cross-platform path handling.
class PathUtils {
  /// Resolves a path to its absolute, canonical form.
  /// Returns null if the path doesn't exist or can't be resolved.
  static String? resolveAbsolute(String pathString) {
    try {
      final dir = Directory(pathString);
      if (!dir.existsSync()) {
        return null;
      }
      return dir.absolute.resolveSymbolicLinksSync();
    } catch (e) {
      return null;
    }
  }

  /// Checks if a path is within a parent directory.
  static bool isWithin(String childPath, String parentPath) {
    try {
      final child = path.normalize(path.absolute(childPath));
      final parent = path.normalize(path.absolute(parentPath));
      return child.startsWith(parent + path.separator) || child == parent;
    } catch (e) {
      return false;
    }
  }

  /// Normalizes a path for comparison.
  static String normalize(String pathString) {
    return path.normalize(path.absolute(pathString));
  }

  /// Gets the home directory path.
  static String getHomeDirectory() {
    final env = Platform.environment;
    if (Platform.isWindows) {
      return env['USERPROFILE'] ?? env['HOME'] ?? '';
    }
    return env['HOME'] ?? '';
  }

  /// Expands a path that starts with ~ to the home directory.
  static String expandHome(String pathString) {
    if (pathString.startsWith('~')) {
      final home = getHomeDirectory();
      if (home.isNotEmpty) {
        return path.join(home, pathString.substring(1));
      }
    }
    return pathString;
  }

  /// Checks if a path exists and is a directory.
  static bool isDirectory(String pathString) {
    try {
      return Directory(pathString).existsSync();
    } catch (e) {
      return false;
    }
  }

  /// Checks if a path exists and is a file.
  static bool isFile(String pathString) {
    try {
      return File(pathString).existsSync();
    } catch (e) {
      return false;
    }
  }
}

