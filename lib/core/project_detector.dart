import 'dart:io';
import 'package:path/path.dart' as path;
import '../utils/path_utils.dart';
import '../utils/safety_utils.dart';

/// Detects Flutter projects in directories.
class ProjectDetector {
  /// Checks if a directory is a Flutter project root.
  /// A directory is considered a Flutter project if it contains:
  /// - pubspec.yaml AND at least one of:
  ///   - .metadata
  ///   - android/
  ///   - ios/
  static bool isFlutterProject(String dirPath) {
    final resolved = PathUtils.resolveAbsolute(dirPath);
    if (resolved == null || !PathUtils.isDirectory(resolved)) {
      return false;
    }

    // Must have pubspec.yaml
    final pubspecPath = path.join(resolved, 'pubspec.yaml');
    if (!PathUtils.isFile(pubspecPath)) {
      return false;
    }

    // Must have at least one of: .metadata, android/, ios/
    final metadataPath = path.join(resolved, '.metadata');
    final androidPath = path.join(resolved, 'android');
    final iosPath = path.join(resolved, 'ios');

    return PathUtils.isFile(metadataPath) ||
        PathUtils.isDirectory(androidPath) ||
        PathUtils.isDirectory(iosPath);
  }

  /// Recursively finds all Flutter projects in a directory tree.
  /// [rootPath] is the root directory to search.
  /// [maxDepth] limits the recursion depth (0 = unlimited).
  /// [seenPaths] tracks already-seen paths to avoid duplicates.
  static List<String> findProjects(
    String rootPath, {
    int maxDepth = 0,
    Set<String>? seenPaths,
  }) {
    final projects = <String>[];
    final seen = seenPaths ?? <String>{};
    final resolvedRoot = PathUtils.resolveAbsolute(rootPath);

    if (resolvedRoot == null || !PathUtils.isDirectory(resolvedRoot)) {
      return projects;
    }

    _findProjectsRecursive(
      resolvedRoot,
      projects,
      seen,
      maxDepth: maxDepth,
      currentDepth: 0,
    );

    return projects;
  }

  /// Recursive helper for finding projects.
  static void _findProjectsRecursive(
    String dirPath,
    List<String> projects,
    Set<String> seenPaths, {
    required int maxDepth,
    required int currentDepth,
  }) {
    // Check depth limit
    if (maxDepth > 0 && currentDepth >= maxDepth) {
      return;
    }

    // Resolve and check if already seen
    final resolved = PathUtils.resolveAbsolute(dirPath);
    if (resolved == null) return;

    final normalized = PathUtils.normalize(resolved);
    if (seenPaths.contains(normalized)) {
      return;
    }
    seenPaths.add(normalized);

    // Check if this directory is a Flutter project
    if (isFlutterProject(resolved)) {
      projects.add(resolved);
      // Don't recurse deeper into a project root
      return;
    }

    // List directory contents
    try {
      final dir = Directory(resolved);
      final entities = dir.listSync(followLinks: false);

      for (final entity in entities) {
        if (entity is! Directory) continue;

        final dirName = path.basename(entity.path);
        // Prune irrelevant directories
        if (SafetyUtils.shouldPruneDirectory(dirName)) {
          continue;
        }

        // Recurse into subdirectories
        _findProjectsRecursive(
          entity.path,
          projects,
          seenPaths,
          maxDepth: maxDepth,
          currentDepth: currentDepth + 1,
        );
      }
    } catch (e) {
      // Skip directories that can't be read (permissions, etc.)
    }
  }

  /// Finds Flutter projects in multiple root directories.
  /// Returns a map of root path to list of projects found in that root.
  static Map<String, List<String>> findProjectsInRoots(
    List<String> rootPaths, {
    int maxDepth = 0,
  }) {
    final results = <String, List<String>>{};
    final seenPaths = <String>{};

    for (final rootPath in rootPaths) {
      final expanded = PathUtils.expandHome(rootPath);
      final resolved = PathUtils.resolveAbsolute(expanded);

      if (resolved == null) continue;

      final projects = findProjects(
        resolved,
        maxDepth: maxDepth,
        seenPaths: seenPaths,
      );

      if (projects.isNotEmpty) {
        results[resolved] = projects;
      }
    }

    return results;
  }
}

