import '../models/project_info.dart';
import '../models/cache_target.dart';
import '../models/scan_result.dart';
import '../core/project_detector.dart';
import '../targets/project_targets.dart';
import '../targets/global_targets.dart';
import '../utils/path_utils.dart';
import '../utils/platform_utils.dart';

/// Scans for Flutter projects and cache targets.
class CacheScanner {
  /// Scans for projects and caches in the specified roots.
  /// [priorityRoots] are user-specified roots (scanned first).
  /// [includeDefaults] whether to include default scan roots.
  /// [includeOptional] whether to include optional project targets.
  /// [includeGlobal] whether to include global cache targets.
  /// [maxDepth] limits recursion depth (0 = unlimited).
  static Future<ScanResult> scan({
    required List<String> priorityRoots,
    bool includeDefaults = false,
    bool includeOptional = false,
    bool includeGlobal = false,
    int maxDepth = 0,
  }) async {
    final priorityProjects = <ProjectInfo>[];
    final defaultProjects = <ProjectInfo>[];
    final globalTargets = <CacheTarget>[];

    // Scan priority roots
    final priorityRootsExpanded = priorityRoots
        .map((r) => PathUtils.expandHome(r))
        .where((r) => PathUtils.resolveAbsolute(r) != null)
        .toList();

    if (priorityRootsExpanded.isNotEmpty) {
      final projectsMap = ProjectDetector.findProjectsInRoots(
        priorityRootsExpanded,
        maxDepth: maxDepth,
      );

      for (final entry in projectsMap.entries) {
        for (final projectPath in entry.value) {
          final targets = ProjectTargets.findTargets(
            projectPath,
            includeOptional: includeOptional,
          );
          if (targets.isNotEmpty) {
            priorityProjects.add(ProjectInfo(
              path: projectPath,
              targets: targets,
              isPriority: true,
            ));
          }
        }
      }
    }

    // Scan default roots if enabled
    if (includeDefaults) {
      final defaultRoots = PlatformUtils.getDefaultScanRoots();
      if (defaultRoots.isNotEmpty) {
        final projectsMap = ProjectDetector.findProjectsInRoots(
          defaultRoots,
          maxDepth: maxDepth,
        );

        // Filter out projects already found in priority roots
        final priorityPaths = priorityProjects.map((p) => p.path).toSet();

        for (final entry in projectsMap.entries) {
          for (final projectPath in entry.value) {
            if (priorityPaths.contains(projectPath)) continue;

            final targets = ProjectTargets.findTargets(
              projectPath,
              includeOptional: includeOptional,
            );
            if (targets.isNotEmpty) {
              defaultProjects.add(ProjectInfo(
                path: projectPath,
                targets: targets,
                isPriority: false,
              ));
            }
          }
        }
      }
    }

    // Find global targets if enabled
    if (includeGlobal) {
      globalTargets.addAll(GlobalTargets.findTargets());
      // Recalculate sizes for global targets (they can be large)
      for (var i = 0; i < globalTargets.length; i++) {
        final target = globalTargets[i];
        final size = GlobalTargets.calculateDirectorySize(target.path);
        globalTargets[i] = target.copyWith(size: size);
      }
    }

    return ScanResult(
      priorityProjects: priorityProjects,
      defaultProjects: defaultProjects,
      globalTargets: globalTargets,
    );
  }
}

