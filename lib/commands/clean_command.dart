import 'dart:convert';
import 'dart:io';
import '../core/cache_scanner.dart';
import '../core/cache_cleaner.dart';
import '../models/scan_result.dart';
import 'base_command.dart';

/// Command to clean Flutter project and global caches.
class CleanCommand extends BaseCommand {
  /// Priority roots to scan (user-specified).
  List<String> priorityRoots = [];

  /// Whether to include default scan roots.
  bool includeDefaults = false;

  /// Whether to include optional project targets.
  bool includeOptional = false;

  /// Whether to include global cache targets.
  bool includeGlobal = false;

  /// Maximum recursion depth (0 = unlimited).
  int maxDepth = 0;

  /// Whether to actually perform deletion (required for cleaning).
  bool apply = false;

  /// Whether to skip confirmation prompts.
  bool yes = false;

  /// Whether to move to trash instead of deleting directly.
  bool moveToTrash = false;

  /// Runs the clean command.
  Future<int> run() async {
    if (!apply) {
      printError(
          'Error: --apply flag is required to perform deletions. This is a safety measure.');
      printError('Run with --apply to actually delete files.');
      return 1;
    }

    if (priorityRoots.isEmpty && !includeDefaults) {
      printError('Error: No scan roots specified. Use --root or --include-defaults');
      return 1;
    }

    printVerbose('Scanning for Flutter projects and caches...');

    try {
      // First, scan to find what will be deleted
      final verboseLogger = getVerboseLogger();
      final scanResult = await CacheScanner.scan(
        priorityRoots: priorityRoots,
        includeDefaults: includeDefaults,
        includeOptional: includeOptional,
        includeGlobal: includeGlobal,
        maxDepth: maxDepth,
        verboseLogger: verboseLogger,
      );

      if (scanResult.totalSize == 0) {
        printMessage('No cache files found to clean.');
        return 0;
      }

      // Show summary
      _printSummary(scanResult);

      // Confirm deletion
      if (!yes) {
        stdout.write('Do you want to proceed with deletion? (yes/no): ');
        final response = stdin.readLineSync()?.toLowerCase().trim();
        if (response != 'yes' && response != 'y') {
          printMessage('Cancelled.');
          return 0;
        }
      }

      // Perform cleaning
      printMessage('');
      printMessage('Cleaning caches...');
      printVerbose('Move to trash: $moveToTrash');

      final cleaner = CacheCleaner(
        moveToTrash: moveToTrash,
        verboseLogger: verboseLogger,
      );
      final cleanResult = await _performCleaning(scanResult, cleaner);

      // Print results
      if (jsonOutput) {
        _printJsonResult(cleanResult);
      } else {
        _printHumanReadableResult(cleanResult);
      }

      return cleanResult.failedPaths.isEmpty ? 0 : 1;
    } catch (e) {
      printError('Error during cleaning: $e');
      return 1;
    }
  }

  /// Performs the actual cleaning operation.
  Future<CleanResult> _performCleaning(
      ScanResult scanResult, CacheCleaner cleaner) async {
    final verboseLogger = getVerboseLogger();
    final cleanStart = DateTime.now();
    
    final allDeletedPaths = <String>[];
    final allFailedPaths = <String, String>{};
    int totalReclaimed = 0;

    final totalProjects = scanResult.priorityProjects.length + scanResult.defaultProjects.length;
    verboseLogger?.call('Starting cleanup: $totalProjects project(s), ${scanResult.globalTargets.length} global target(s)');

    // Clean priority projects
    if (scanResult.priorityProjects.isNotEmpty) {
      verboseLogger?.call('Cleaning ${scanResult.priorityProjects.length} priority project(s)...');
      int projectIndex = 0;
      for (final project in scanResult.priorityProjects) {
        projectIndex++;
        verboseLogger?.call('Priority project $projectIndex/${scanResult.priorityProjects.length}');
        final result = await cleaner.cleanProject(project);
        allDeletedPaths.addAll(result.deletedPaths);
        allFailedPaths.addAll(result.failedPaths);
        totalReclaimed += result.reclaimedSize;
      }
    }

    // Clean default projects
    if (scanResult.defaultProjects.isNotEmpty) {
      verboseLogger?.call('Cleaning ${scanResult.defaultProjects.length} default project(s)...');
      int projectIndex = 0;
      for (final project in scanResult.defaultProjects) {
        projectIndex++;
        verboseLogger?.call('Default project $projectIndex/${scanResult.defaultProjects.length}');
        final result = await cleaner.cleanProject(project);
        allDeletedPaths.addAll(result.deletedPaths);
        allFailedPaths.addAll(result.failedPaths);
        totalReclaimed += result.reclaimedSize;
      }
    }

    // Clean global targets
    if (scanResult.globalTargets.isNotEmpty) {
      verboseLogger?.call('Cleaning ${scanResult.globalTargets.length} global target(s)...');
      final result = await cleaner.cleanGlobalTargets(scanResult.globalTargets);
      allDeletedPaths.addAll(result.deletedPaths);
      allFailedPaths.addAll(result.failedPaths);
      totalReclaimed += result.reclaimedSize;
    }

    final cleanTime = DateTime.now().difference(cleanStart);
    verboseLogger?.call('Cleanup completed in ${cleanTime.inMilliseconds / 1000.0}s');
    verboseLogger?.call('Total: ${allDeletedPaths.length} deleted, ${allFailedPaths.length} failed, ${formatSize(totalReclaimed)} reclaimed');

    return CleanResult(
      deletedPaths: allDeletedPaths,
      failedPaths: allFailedPaths,
      reclaimedSize: totalReclaimed,
    );
  }

  /// Prints a summary of what will be deleted.
  void _printSummary(ScanResult scanResult) {
    printMessage('');
    printMessage('Flutter Cache Cleaner - Clean Summary');
    printMessage(repeatString('=', 50));
    printMessage('Projects to clean: ${scanResult.projectCount}');
    printMessage('Global targets: ${scanResult.globalTargets.length}');
    printMessage('Total reclaimable: ${formatSize(scanResult.totalSize)}');
    printMessage('');

    if (verbose) {
      printMessage('Projects:');
      for (final project in scanResult.allProjects) {
        printMessage('  - ${project.path} (${formatSize(project.totalSize)})');
      }
      if (scanResult.globalTargets.isNotEmpty) {
        printMessage('Global targets:');
        for (final target in scanResult.globalTargets) {
          printMessage('  - ${target.type} (${formatSize(target.size)})');
        }
      }
      printMessage('');
    }
  }

  /// Prints results in JSON format.
  void _printJsonResult(CleanResult result) {
    final json = {
      'deletedPaths': result.deletedPaths,
      'failedPaths': result.failedPaths,
      'reclaimedSize': result.reclaimedSize,
      'success': result.failedPaths.isEmpty,
    };
    stdout.writeln(jsonEncode(json));
  }

  /// Prints results in human-readable format.
  void _printHumanReadableResult(CleanResult result) {
    printMessage('');
    printMessage('Cleaning complete!');
    printMessage(repeatString('=', 50));
    printMessage('Deleted: ${result.deletedPaths.length} targets');
    printMessage('Failed: ${result.failedPaths.length} targets');
    printMessage('Reclaimed: ${formatSize(result.reclaimedSize)}');
    printMessage('');

    if (result.failedPaths.isNotEmpty) {
      printError('Failed deletions:');
      for (final entry in result.failedPaths.entries) {
        printError('  ${entry.key}: ${entry.value}');
      }
    }

    if (verbose && result.deletedPaths.isNotEmpty) {
      printMessage('Deleted paths:');
      for (final path in result.deletedPaths) {
        printMessage('  - $path');
      }
    }
  }
}

