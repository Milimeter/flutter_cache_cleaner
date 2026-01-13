import 'dart:io';
import '../models/cache_target.dart';
import '../models/project_info.dart';
import '../utils/platform_utils.dart';
import '../utils/safety_utils.dart';

/// Result of a cleaning operation.
class CleanResult {
  /// Paths that were successfully deleted.
  final List<String> deletedPaths;

  /// Paths that failed to delete (with error messages).
  final Map<String, String> failedPaths;

  /// Total size reclaimed in bytes.
  final int reclaimedSize;

  CleanResult({
    this.deletedPaths = const [],
    this.failedPaths = const {},
    this.reclaimedSize = 0,
  });

  /// Creates a copy with updated fields.
  CleanResult copyWith({
    List<String>? deletedPaths,
    Map<String, String>? failedPaths,
    int? reclaimedSize,
  }) {
    return CleanResult(
      deletedPaths: deletedPaths ?? this.deletedPaths,
      failedPaths: failedPaths ?? this.failedPaths,
      reclaimedSize: reclaimedSize ?? this.reclaimedSize,
    );
  }
}

/// Cleans cache targets safely.
class CacheCleaner {
  /// Whether to move to trash instead of deleting directly.
  final bool moveToTrash;

  CacheCleaner({this.moveToTrash = false});

  /// Cleans cache targets from a project.
  /// Returns a CleanResult with deleted paths and errors.
  Future<CleanResult> cleanProject(ProjectInfo project) async {
    final deletedPaths = <String>[];
    final failedPaths = <String, String>{};
    int reclaimedSize = 0;

    for (final target in project.targets) {
      // Validate deletion safety
      final validationError =
          SafetyUtils.validateDeletion(target, project.path);
      if (validationError != null) {
        failedPaths[target.path] = validationError;
        continue;
      }

      // Attempt deletion
      final success = await _deleteTarget(target);
      if (success) {
        deletedPaths.add(target.path);
        reclaimedSize += target.size;
      } else {
        failedPaths[target.path] = 'Failed to delete';
      }
    }

    return CleanResult(
      deletedPaths: deletedPaths,
      failedPaths: failedPaths,
      reclaimedSize: reclaimedSize,
    );
  }

  /// Cleans a list of global cache targets.
  Future<CleanResult> cleanGlobalTargets(List<CacheTarget> targets) async {
    final deletedPaths = <String>[];
    final failedPaths = <String, String>{};
    int reclaimedSize = 0;

    for (final target in targets) {
      // Validate that it's a global target
      if (!target.isGlobal) {
        failedPaths[target.path] = 'Not a global cache target';
        continue;
      }

      // Validate deletion safety
      final validationError = SafetyUtils.validateDeletion(
        target,
        target.path, // For global targets, use the target path itself as root
      );
      if (validationError != null) {
        failedPaths[target.path] = validationError;
        continue;
      }

      // Attempt deletion
      final success = await _deleteTarget(target);
      if (success) {
        deletedPaths.add(target.path);
        reclaimedSize += target.size;
      } else {
        failedPaths[target.path] = 'Failed to delete';
      }
    }

    return CleanResult(
      deletedPaths: deletedPaths,
      failedPaths: failedPaths,
      reclaimedSize: reclaimedSize,
    );
  }

  /// Deletes a single cache target.
  Future<bool> _deleteTarget(CacheTarget target) async {
    try {
      if (moveToTrash) {
        return await PlatformUtils.moveToTrash(target.path);
      } else {
        return await _deleteDirectly(target.path);
      }
    } catch (e) {
      return false;
    }
  }

  /// Directly deletes a file or directory.
  Future<bool> _deleteDirectly(String pathString) async {
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
}

