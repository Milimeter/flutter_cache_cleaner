import '../models/project_info.dart';
import '../models/cache_target.dart';

/// Aggregates scan results from multiple roots.
class ScanResult {
  /// Projects found in priority roots (user-specified).
  final List<ProjectInfo> priorityProjects;

  /// Projects found in default roots.
  final List<ProjectInfo> defaultProjects;

  /// Global cache targets found.
  final List<CacheTarget> globalTargets;

  /// Total reclaimable size in bytes.
  int get totalSize {
    final projectSize = [...priorityProjects, ...defaultProjects]
        .fold(0, (sum, project) => sum + project.totalSize);
    final globalSize =
        globalTargets.fold(0, (sum, target) => sum + target.size);
    return projectSize + globalSize;
  }

  /// Total number of projects found.
  int get projectCount => priorityProjects.length + defaultProjects.length;

  ScanResult({
    this.priorityProjects = const [],
    this.defaultProjects = const [],
    this.globalTargets = const [],
  });

  /// Creates a copy of this ScanResult with updated fields.
  ScanResult copyWith({
    List<ProjectInfo>? priorityProjects,
    List<ProjectInfo>? defaultProjects,
    List<CacheTarget>? globalTargets,
  }) {
    return ScanResult(
      priorityProjects: priorityProjects ?? this.priorityProjects,
      defaultProjects: defaultProjects ?? this.defaultProjects,
      globalTargets: globalTargets ?? this.globalTargets,
    );
  }

  /// Gets all projects (priority and default combined).
  List<ProjectInfo> get allProjects => [...priorityProjects, ...defaultProjects];

  @override
  String toString() {
    return 'ScanResult(projects: $projectCount, priority: ${priorityProjects.length}, default: ${defaultProjects.length}, global: ${globalTargets.length}, totalSize: ${_formatSize(totalSize)})';
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

