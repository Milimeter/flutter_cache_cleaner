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
  /// [verboseLogger] optional callback for verbose logging.
  static Future<ScanResult> scan({
    required List<String> priorityRoots,
    bool includeDefaults = false,
    bool includeOptional = false,
    bool includeGlobal = false,
    int maxDepth = 0,
    void Function(String message)? verboseLogger,
  }) async {
    final scanStart = DateTime.now();
    verboseLogger?.call('Starting scan...');
    final priorityProjects = <ProjectInfo>[];
    final defaultProjects = <ProjectInfo>[];
    final globalTargets = <CacheTarget>[];

    // Scan priority roots
    final priorityRootsExpanded = priorityRoots
        .map((r) => PathUtils.expandHome(r))
        .where((r) => PathUtils.resolveAbsolute(r) != null)
        .toList();

    if (priorityRootsExpanded.isNotEmpty) {
      verboseLogger?.call('Scanning ${priorityRootsExpanded.length} priority root(s)...');
      final priorityStart = DateTime.now();
      
      final projectsMap = ProjectDetector.findProjectsInRoots(
        priorityRootsExpanded,
        maxDepth: maxDepth,
        verboseLogger: verboseLogger,
      );

      final priorityScanTime = DateTime.now().difference(priorityStart);
      verboseLogger?.call('Priority roots scan completed in ${priorityScanTime.inMilliseconds / 1000.0}s');

      verboseLogger?.call('Analyzing ${projectsMap.values.fold(0, (sum, list) => sum + list.length)} project(s) for cache targets...');
      
      int projectIndex = 0;
      final totalProjects = projectsMap.values.fold(0, (sum, list) => sum + list.length);
      
      for (final entry in projectsMap.entries) {
        for (final projectPath in entry.value) {
          projectIndex++;
          verboseLogger?.call('Analyzing project $projectIndex/$totalProjects: $projectPath');
          
          final targets = ProjectTargets.findTargets(
            projectPath,
            includeOptional: includeOptional,
          );
          
          if (targets.isNotEmpty) {
            final totalSize = targets.fold(0, (sum, t) => sum + t.size);
            verboseLogger?.call('  Found ${targets.length} target(s), total size: ${_formatSize(totalSize)}');
            
            priorityProjects.add(ProjectInfo(
              path: projectPath,
              targets: targets,
              isPriority: true,
            ));
          } else {
            verboseLogger?.call('  No cache targets found');
          }
        }
      }
      
      verboseLogger?.call('Priority roots: ${priorityProjects.length} project(s) with cache targets');
    }

    // Scan default roots if enabled
    if (includeDefaults) {
      final defaultRoots = PlatformUtils.getDefaultScanRoots();
      if (defaultRoots.isNotEmpty) {
        verboseLogger?.call('Scanning ${defaultRoots.length} default root(s)...');
        final defaultStart = DateTime.now();
        
        final projectsMap = ProjectDetector.findProjectsInRoots(
          defaultRoots,
          maxDepth: maxDepth,
          verboseLogger: verboseLogger,
        );

        final defaultScanTime = DateTime.now().difference(defaultStart);
        verboseLogger?.call('Default roots scan completed in ${defaultScanTime.inMilliseconds / 1000.0}s');

        // Filter out projects already found in priority roots
        final priorityPaths = priorityProjects.map((p) => p.path).toSet();
        verboseLogger?.call('Filtering out ${priorityPaths.length} project(s) already found in priority roots...');

        int projectIndex = 0;
        int skippedCount = 0;
        final totalProjects = projectsMap.values.fold(0, (sum, list) => sum + list.length);
        
        for (final entry in projectsMap.entries) {
          for (final projectPath in entry.value) {
            projectIndex++;
            
            if (priorityPaths.contains(projectPath)) {
              skippedCount++;
              verboseLogger?.call('Skipping duplicate project $projectIndex/$totalProjects: $projectPath');
              continue;
            }

            verboseLogger?.call('Analyzing project $projectIndex/$totalProjects: $projectPath');
            
            final targets = ProjectTargets.findTargets(
              projectPath,
              includeOptional: includeOptional,
            );
            
            if (targets.isNotEmpty) {
              final totalSize = targets.fold(0, (sum, t) => sum + t.size);
              verboseLogger?.call('  Found ${targets.length} target(s), total size: ${_formatSize(totalSize)}');
              
              defaultProjects.add(ProjectInfo(
                path: projectPath,
                targets: targets,
                isPriority: false,
              ));
            } else {
              verboseLogger?.call('  No cache targets found');
            }
          }
        }
        
        verboseLogger?.call('Default roots: ${defaultProjects.length} project(s) with cache targets (skipped $skippedCount duplicate(s))');
      }
    }

    // Find global targets if enabled
    if (includeGlobal) {
      verboseLogger?.call('Scanning for global cache targets...');
      final globalStart = DateTime.now();
      
      globalTargets.addAll(GlobalTargets.findTargets());
      verboseLogger?.call('Found ${globalTargets.length} global target(s)');
      
      // Recalculate sizes for global targets (they can be large)
      for (var i = 0; i < globalTargets.length; i++) {
        final target = globalTargets[i];
        verboseLogger?.call('Calculating size for ${target.type}: ${target.path}');
        
        final size = GlobalTargets.calculateDirectorySize(target.path);
        globalTargets[i] = target.copyWith(size: size);
        
        verboseLogger?.call('  Size: ${_formatSize(size)}');
      }
      
      final globalTime = DateTime.now().difference(globalStart);
      verboseLogger?.call('Global targets scan completed in ${globalTime.inMilliseconds / 1000.0}s');
    }

    final totalScanTime = DateTime.now().difference(scanStart);
    verboseLogger?.call('Scan completed in ${totalScanTime.inMilliseconds / 1000.0}s');
    verboseLogger?.call('Total: ${priorityProjects.length + defaultProjects.length} project(s), ${globalTargets.length} global target(s)');

    return ScanResult(
      priorityProjects: priorityProjects,
      defaultProjects: defaultProjects,
      globalTargets: globalTargets,
    );
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

