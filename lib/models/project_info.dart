import '../models/cache_target.dart';

/// Represents a detected Flutter project with its cache targets.
class ProjectInfo {
  /// The absolute path to the project root.
  final String path;

  /// List of cache targets found in this project.
  final List<CacheTarget> targets;

  /// Whether this project was found in a priority root.
  final bool isPriority;

  /// Total reclaimable size in bytes.
  int get totalSize => targets.fold(0, (sum, target) => sum + target.size);

  ProjectInfo({
    required this.path,
    required this.targets,
    this.isPriority = false,
  });

  /// Creates a copy of this ProjectInfo with updated fields.
  ProjectInfo copyWith({
    String? path,
    List<CacheTarget>? targets,
    bool? isPriority,
  }) {
    return ProjectInfo(
      path: path ?? this.path,
      targets: targets ?? this.targets,
      isPriority: isPriority ?? this.isPriority,
    );
  }

  @override
  String toString() {
    return 'ProjectInfo(path: $path, targets: ${targets.length}, size: ${_formatSize(totalSize)}, priority: $isPriority)';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

