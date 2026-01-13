import 'dart:convert';
import 'dart:io';
import '../core/cache_scanner.dart';
import '../models/scan_result.dart';
import 'base_command.dart';

/// Command to scan for Flutter projects and cache files.
class ScanCommand extends BaseCommand {
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

  /// Runs the scan command.
  Future<int> run() async {
    if (priorityRoots.isEmpty && !includeDefaults) {
      printError('Error: No scan roots specified. Use --root or --include-defaults');
      return 1;
    }

    printVerbose('Scanning for Flutter projects...');
    printVerbose('Priority roots: $priorityRoots');
    printVerbose('Include defaults: $includeDefaults');
    printVerbose('Include optional: $includeOptional');
    printVerbose('Include global: $includeGlobal');
    printVerbose('Max depth: ${maxDepth == 0 ? "unlimited" : maxDepth}');

    try {
      final result = await CacheScanner.scan(
        priorityRoots: priorityRoots,
        includeDefaults: includeDefaults,
        includeOptional: includeOptional,
        includeGlobal: includeGlobal,
        maxDepth: maxDepth,
      );

      if (jsonOutput) {
        _printJson(result);
      } else {
        _printHumanReadable(result);
      }

      return 0;
    } catch (e) {
      printError('Error during scan: $e');
      return 1;
    }
  }

  /// Prints results in JSON format.
  void _printJson(ScanResult result) {
    final json = {
      'priorityProjects': result.priorityProjects.map((p) => {
            'path': p.path,
            'targets': p.targets.map((t) => {
                  'type': t.type,
                  'path': t.path,
                  'size': t.size,
                }).toList(),
            'totalSize': p.totalSize,
          }).toList(),
      'defaultProjects': result.defaultProjects.map((p) => {
            'path': p.path,
            'targets': p.targets.map((t) => {
                  'type': t.type,
                  'path': t.path,
                  'size': t.size,
                }).toList(),
            'totalSize': p.totalSize,
          }).toList(),
      'globalTargets': result.globalTargets.map((t) => {
            'type': t.type,
            'path': t.path,
            'size': t.size,
          }).toList(),
      'summary': {
        'totalProjects': result.projectCount,
        'priorityProjects': result.priorityProjects.length,
        'defaultProjects': result.defaultProjects.length,
        'globalTargets': result.globalTargets.length,
        'totalReclaimableSize': result.totalSize,
      },
    };

    stdout.writeln(jsonEncode(json));
  }

  /// Prints results in human-readable format.
  void _printHumanReadable(ScanResult result) {
    printMessage('');
    printMessage('Flutter Cache Cleaner - Scan Results');
    printMessage(repeatString('=', 50));

    // Priority projects
    if (result.priorityProjects.isNotEmpty) {
      printMessage('');
      printMessage('Priority Roots (${result.priorityProjects.length} projects):');
      printMessage(repeatString('-', 50));
      for (final project in result.priorityProjects) {
        printMessage('  ${project.path}');
        printMessage('    Targets: ${project.targets.length}');
        printMessage('    Reclaimable: ${formatSize(project.totalSize)}');
        if (verbose) {
          for (final target in project.targets) {
            printMessage('      - ${target.type}: ${formatSize(target.size)}');
          }
        }
      }
    }

    // Default projects
    if (result.defaultProjects.isNotEmpty) {
      printMessage('');
      printMessage('Default Roots (${result.defaultProjects.length} projects):');
      printMessage(repeatString('-', 50));
      for (final project in result.defaultProjects) {
        printMessage('  ${project.path}');
        printMessage('    Targets: ${project.targets.length}');
        printMessage('    Reclaimable: ${formatSize(project.totalSize)}');
        if (verbose) {
          for (final target in project.targets) {
            printMessage('      - ${target.type}: ${formatSize(target.size)}');
          }
        }
      }
    }

    // Global targets
    if (result.globalTargets.isNotEmpty) {
      printMessage('');
      printMessage('Global Caches (${result.globalTargets.length} targets):');
      printMessage(repeatString('-', 50));
      for (final target in result.globalTargets) {
        printMessage('  ${target.type}: ${formatSize(target.size)}');
        if (verbose) {
          printMessage('    Path: ${target.path}');
        }
      }
    }

    // Summary
    printMessage('');
    printMessage('Summary:');
    printMessage(repeatString('-', 50));
    printMessage('  Total projects: ${result.projectCount}');
    printMessage('  Priority projects: ${result.priorityProjects.length}');
    printMessage('  Default projects: ${result.defaultProjects.length}');
    printMessage('  Global targets: ${result.globalTargets.length}');
    printMessage('  Total reclaimable: ${formatSize(result.totalSize)}');
    printMessage('');
  }
}

