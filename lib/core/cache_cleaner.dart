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

  /// Optional verbose logger for progress updates.
  final void Function(String message)? verboseLogger;

  CacheCleaner({
    this.moveToTrash = false,
    this.verboseLogger,
  });

  /// Cleans cache targets from a project.
  /// Returns a CleanResult with deleted paths and errors.
  Future<CleanResult> cleanProject(ProjectInfo project) async {
    verboseLogger?.call('Cleaning project: ${project.path}');
    verboseLogger?.call('  Targets: ${project.targets.length}');
    
    final deletedPaths = <String>[];
    final failedPaths = <String, String>{};
    int reclaimedSize = 0;

    for (int i = 0; i < project.targets.length; i++) {
      final target = project.targets[i];
      verboseLogger?.call('  [$i/${project.targets.length}] ${target.type}: ${target.path}');
      
      // Validate deletion safety
      final validationError =
          SafetyUtils.validateDeletion(target, project.path);
      if (validationError != null) {
        verboseLogger?.call('    ❌ Validation failed: $validationError');
        failedPaths[target.path] = validationError;
        continue;
      }

      // Attempt deletion
      final deleteStart = DateTime.now();
      final success = await _deleteTarget(target);
      final deleteTime = DateTime.now().difference(deleteStart);
      
      if (success) {
        deletedPaths.add(target.path);
        reclaimedSize += target.size;
        verboseLogger?.call('    ✅ Deleted (${_formatSize(target.size)}) in ${deleteTime.inMilliseconds}ms');
      } else {
        verboseLogger?.call('    ❌ Failed to delete');
        failedPaths[target.path] = 'Failed to delete';
      }
    }

    verboseLogger?.call('  Project complete: ${deletedPaths.length} deleted, ${failedPaths.length} failed, ${_formatSize(reclaimedSize)} reclaimed');

    return CleanResult(
      deletedPaths: deletedPaths,
      failedPaths: failedPaths,
      reclaimedSize: reclaimedSize,
    );
  }

  /// Cleans a list of global cache targets.
  Future<CleanResult> cleanGlobalTargets(List<CacheTarget> targets) async {
    verboseLogger?.call('Cleaning ${targets.length} global target(s)...');
    
    final deletedPaths = <String>[];
    final failedPaths = <String, String>{};
    int reclaimedSize = 0;

    for (int i = 0; i < targets.length; i++) {
      final target = targets[i];
      verboseLogger?.call('  [$i/${targets.length}] ${target.type}: ${target.path}');
      
      // Validate that it's a global target
      if (!target.isGlobal) {
        verboseLogger?.call('    ❌ Not a global cache target');
        failedPaths[target.path] = 'Not a global cache target';
        continue;
      }

      // Validate deletion safety
      final validationError = SafetyUtils.validateDeletion(
        target,
        target.path, // For global targets, use the target path itself as root
      );
      if (validationError != null) {
        verboseLogger?.call('    ❌ Validation failed: $validationError');
        failedPaths[target.path] = validationError;
        continue;
      }

      // Attempt deletion
      verboseLogger?.call('    Deleting ${_formatSize(target.size)}...');
      final deleteStart = DateTime.now();
      final success = await _deleteTarget(target);
      final deleteTime = DateTime.now().difference(deleteStart);
      
      if (success) {
        deletedPaths.add(target.path);
        reclaimedSize += target.size;
        verboseLogger?.call('    ✅ Deleted in ${deleteTime.inMilliseconds / 1000.0}s');
      } else {
        verboseLogger?.call('    ❌ Failed to delete');
        failedPaths[target.path] = 'Failed to delete';
      }
    }

    verboseLogger?.call('Global targets complete: ${deletedPaths.length} deleted, ${failedPaths.length} failed, ${_formatSize(reclaimedSize)} reclaimed');

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

  /// Helper to format size for verbose output.
  static String _formatSize(int bytes) {
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

