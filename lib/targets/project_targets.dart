import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/cache_target.dart';
import '../utils/path_utils.dart';

/// Defines per-project cache targets.
class ProjectTargets {
  /// Required cache targets (always included).
  static const List<String> requiredTargets = [
    'build',
    'dart_tool',
    'flutter_plugins',
    'flutter_plugins_dependencies',
  ];

  /// Optional cache targets (included with flags).
  static const List<String> optionalTargets = [
    'idea',
    'gradle',
    'pods',
    'symlinks',
  ];

  /// Finds all cache targets in a Flutter project.
  /// [projectRoot] is the absolute path to the project root.
  /// [includeOptional] includes optional targets if true.
  static List<CacheTarget> findTargets(
    String projectRoot, {
    bool includeOptional = false,
  }) {
    final targets = <CacheTarget>[];

    // Required targets
    for (final targetName in requiredTargets) {
      final target = _findTarget(projectRoot, targetName);
      if (target != null) {
        targets.add(target);
      }
    }

    // Optional targets
    if (includeOptional) {
      for (final targetName in optionalTargets) {
        final target = _findTarget(projectRoot, targetName);
        if (target != null) {
          targets.add(target);
        }
      }
    }

    return targets;
  }

  /// Finds a specific cache target in a project.
  static CacheTarget? _findTarget(String projectRoot, String targetName) {
    String? targetPath;
    int size = 0;
    bool exists = false;

    switch (targetName) {
      case 'build':
        targetPath = path.join(projectRoot, 'build');
        break;
      case 'dart_tool':
        targetPath = path.join(projectRoot, '.dart_tool');
        break;
      case 'flutter_plugins':
        targetPath = path.join(projectRoot, '.flutter-plugins');
        break;
      case 'flutter_plugins_dependencies':
        targetPath = path.join(projectRoot, '.flutter-plugins-dependencies');
        break;
      case 'idea':
        targetPath = path.join(projectRoot, '.idea');
        break;
      case 'gradle':
        targetPath = path.join(projectRoot, 'android', '.gradle');
        break;
      case 'pods':
        targetPath = path.join(projectRoot, 'ios', 'Pods');
        break;
      case 'symlinks':
        targetPath = path.join(projectRoot, 'ios', '.symlinks');
        break;
    }

    if (targetPath == null) return null;

    final resolved = PathUtils.resolveAbsolute(targetPath);
    if (resolved == null) return null;

    exists = PathUtils.isDirectory(resolved) || PathUtils.isFile(resolved);
    if (!exists) return null;

    // Calculate size
    try {
      size = _calculateSize(resolved);
    } catch (e) {
      // If size calculation fails, still include the target but with 0 size
      size = 0;
    }

    return CacheTarget(
      type: targetName,
      path: resolved,
      size: size,
      safeToDelete: true,
      isGlobal: false,
      exists: exists,
    );
  }

  /// Calculates the size of a file or directory in bytes.
  static int _calculateSize(String pathString) {
    final entity = FileSystemEntity.typeSync(pathString);
    if (entity == FileSystemEntityType.file) {
      return File(pathString).lengthSync();
    } else if (entity == FileSystemEntityType.directory) {
      int total = 0;
      try {
        final dir = Directory(pathString);
        final files = dir.listSync(recursive: true, followLinks: false);
        for (final file in files) {
          if (file is File) {
            try {
              total += file.lengthSync();
            } catch (e) {
              // Skip files that can't be read
            }
          }
        }
      } catch (e) {
        // If directory can't be read, return 0
      }
      return total;
    }
    return 0;
  }
}

