import 'dart:io';
import '../utils/path_utils.dart';

/// Calculates sizes of files and directories efficiently.
class SizeCalculator {
  /// Calculates the size of a file or directory in bytes.
  /// Returns 0 if the path doesn't exist or can't be read.
  static int calculateSize(String pathString) {
    if (!PathUtils.isDirectory(pathString) && !PathUtils.isFile(pathString)) {
      return 0;
    }

    final entity = FileSystemEntity.typeSync(pathString);
    if (entity == FileSystemEntityType.file) {
      try {
        return File(pathString).lengthSync();
      } catch (e) {
        return 0;
      }
    } else if (entity == FileSystemEntityType.directory) {
      return _calculateDirectorySize(pathString);
    }

    return 0;
  }

  /// Calculates the size of a directory by walking its contents.
  static int _calculateDirectorySize(String dirPath) {
    int total = 0;
    try {
      final dir = Directory(dirPath);
      final files = dir.listSync(recursive: true, followLinks: false);
      for (final file in files) {
        if (file is File) {
          try {
            total += file.lengthSync();
          } catch (e) {
            // Skip files that can't be read (permissions, etc.)
          }
        }
      }
    } catch (e) {
      // If directory can't be read, return 0
    }
    return total;
  }

  /// Formats bytes into human-readable string.
  static String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

