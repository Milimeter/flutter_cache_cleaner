import 'package:path/path.dart' as path;
import 'path_utils.dart';
import '../models/cache_target.dart';

/// Safety utilities for validating deletions.
class SafetyUtils {
  /// Known safe cache target types (allowlist).
  static const Set<String> safeTargetTypes = {
    'build',
    'dart_tool',
    'flutter_plugins',
    'flutter_plugins_dependencies',
    'idea',
    'gradle',
    'pods',
    'symlinks',
    'pub_cache',
    'gradle_cache',
    'xcode_derived_data',
    'cocoapods_cache',
  };

  /// Validates that a path is safe to delete.
  /// Returns null if safe, or an error message if not.
  static String? validateDeletion(CacheTarget target, String projectRoot) {
    // Resolve absolute paths
    final targetPath = PathUtils.resolveAbsolute(target.path);
    final projectRootPath = PathUtils.resolveAbsolute(projectRoot);

    if (targetPath == null) {
      return 'Target path does not exist or cannot be resolved: ${target.path}';
    }

    if (projectRootPath == null) {
      return 'Project root does not exist or cannot be resolved: $projectRoot';
    }

    // Check if target type is in allowlist
    if (!safeTargetTypes.contains(target.type)) {
      return 'Target type "${target.type}" is not in the safe allowlist';
    }

    // For global targets, verify they match expected global cache locations
    if (target.isGlobal) {
      if (!_isValidGlobalCachePath(targetPath, target.type)) {
        return 'Global cache path does not match expected location for type "${target.type}"';
      }
    } else {
      // For project targets, verify they are within the project root
      if (!PathUtils.isWithin(targetPath, projectRootPath)) {
        return 'Target path is not within project root: $targetPath';
      }
    }

    // Verify the path actually exists
    if (!PathUtils.isDirectory(targetPath) && !PathUtils.isFile(targetPath)) {
      return 'Target path does not exist: $targetPath';
    }

    return null; // Safe to delete
  }

  /// Checks if a global cache path is valid for its type.
  static bool _isValidGlobalCachePath(String cachePath, String type) {
    final normalized = path.normalize(cachePath.toLowerCase());
    switch (type) {
      case 'pub_cache':
        return normalized.contains('.pub-cache') ||
            normalized.contains('pub') && normalized.contains('cache');
      case 'gradle_cache':
        return normalized.contains('.gradle') && normalized.contains('caches');
      case 'xcode_derived_data':
        return normalized.contains('xcode') &&
            normalized.contains('deriveddata');
      case 'cocoapods_cache':
        return normalized.contains('cocoapods') && normalized.contains('cache');
      default:
        return false;
    }
  }

  /// Validates that a path is within allowed project roots.
  static bool isPathAllowed(
      String targetPath, List<String> allowedRoots, List<String> globalCachePaths) {
    final resolved = PathUtils.resolveAbsolute(targetPath);
    if (resolved == null) return false;

    // Check if it's a global cache path
    for (final globalPath in globalCachePaths) {
      final resolvedGlobal = PathUtils.resolveAbsolute(globalPath);
      if (resolvedGlobal != null && PathUtils.isWithin(resolved, resolvedGlobal)) {
        return true;
      }
    }

    // Check if it's within any allowed project root
    for (final root in allowedRoots) {
      final resolvedRoot = PathUtils.resolveAbsolute(root);
      if (resolvedRoot != null && PathUtils.isWithin(resolved, resolvedRoot)) {
        return true;
      }
    }

    return false;
  }

  /// Checks if a directory name should be pruned during scanning.
  static bool shouldPruneDirectory(String dirName) {
    // Prune common directories that are not Flutter projects
    final pruneList = {
      '.git',
      'node_modules',
      '.dart_tool',
      'build',
      '.idea',
      '.vscode',
      '.vs',
      'DerivedData',
      'Pods',
      '.gradle',
      'target', // Rust
      'venv',
      'env',
      '.venv',
      '__pycache__',
      '.pytest_cache',
    };

    return pruneList.contains(dirName);
  }
}

