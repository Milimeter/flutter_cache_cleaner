import 'package:test/test.dart';
import 'package:flutter_cache_cleaner/core/cache_scanner.dart';
import 'package:flutter_cache_cleaner/models/scan_result.dart';
import 'dart:io';

void main() {
  group('CacheScanner', () {
    test('should scan a specific directory', () async {
      // Test scanning the user's StudioProjects directory
      final testDir = '${Platform.environment['HOME']!}/StudioProjects';

      // Check if directory exists
      final dir = Directory(testDir);
      if (!await dir.exists()) {
        print(
            'Warning: Test directory $testDir does not exist. Skipping test.');
        return;
      }

      print('\n=== Scanning $testDir ===\n');

      final result = await CacheScanner.scan(
        priorityRoots: [testDir],
        includeDefaults: false,
        includeOptional: true,
        includeGlobal: false,
        maxDepth: 0, // Unlimited depth
      );

      // Verify we got a result
      expect(result, isNotNull);
      expect(result, isA<ScanResult>());

      // Print results
      print('Scan Results:');
      print('  Total projects found: ${result.projectCount}');
      print('  Priority projects: ${result.priorityProjects.length}');
      print('  Default projects: ${result.defaultProjects.length}');
      print('  Total reclaimable size: ${_formatSize(result.totalSize)}');
      print('');

      // Print project details
      if (result.priorityProjects.isNotEmpty) {
        print('Priority Projects:');
        for (final project in result.priorityProjects) {
          print('  - ${project.path}');
          print('    Targets: ${project.targets.length}');
          print('    Size: ${_formatSize(project.totalSize)}');
          if (project.targets.isNotEmpty) {
            print(
                '    Target types: ${project.targets.map((t) => t.type).join(", ")}');
          }
        }
        print('');
      }

      // Basic assertions
      expect(result.projectCount, greaterThanOrEqualTo(0));
      expect(result.totalSize, greaterThanOrEqualTo(0));
    });

    test('should scan with verbose output', () async {
      final testDir = '${Platform.environment['HOME']!}/StudioProjects';
      final dir = Directory(testDir);

      if (!await dir.exists()) {
        print(
            'Warning: Test directory $testDir does not exist. Skipping test.');
        return;
      }

      print('\n=== Verbose Scan of $testDir ===\n');

      final result = await CacheScanner.scan(
        priorityRoots: [testDir],
        includeDefaults: false,
        includeOptional: true,
        includeGlobal: true, // Include global caches
        maxDepth: 2, // Limit depth for faster testing
      );

      print('Detailed Scan Results:');
      print('  Projects: ${result.projectCount}');
      print('  Total size: ${_formatSize(result.totalSize)}');
      print('  Global targets: ${result.globalTargets.length}');
      print('');

      // Print all targets for each project
      for (final project in result.priorityProjects) {
        print('Project: ${project.path}');
        print('  Total size: ${_formatSize(project.totalSize)}');
        for (final target in project.targets) {
          print('    - ${target.type}: ${_formatSize(target.size)}');
          print('      Path: ${target.path}');
        }
        print('');
      }

      // Print global targets
      if (result.globalTargets.isNotEmpty) {
        print('Global Targets:');
        for (final target in result.globalTargets) {
          print('  - ${target.type}: ${_formatSize(target.size)}');
          print('    Path: ${target.path}');
        }
      }

      expect(result, isNotNull);
    });

    test('should handle empty directory gracefully', () async {
      // Create a temporary empty directory
      final tempDir = Directory.systemTemp.createTempSync('fcc_test_');

      try {
        final result = await CacheScanner.scan(
          priorityRoots: [tempDir.path],
          includeDefaults: false,
          includeOptional: false,
          includeGlobal: false,
        );

        expect(result.projectCount, equals(0));
        expect(result.totalSize, equals(0));
        expect(result.priorityProjects, isEmpty);
      } finally {
        // Clean up
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('should respect maxDepth parameter', () async {
      final testDir = '${Platform.environment['HOME']!}/StudioProjects';
      final dir = Directory(testDir);

      if (!await dir.exists()) {
        print(
            'Warning: Test directory $testDir does not exist. Skipping test.');
        return;
      }

      // Test with limited depth
      final resultLimited = await CacheScanner.scan(
        priorityRoots: [testDir],
        includeDefaults: false,
        includeOptional: true,
        includeGlobal: false,
        maxDepth: 1, // Only 1 level deep
      );

      // Test with unlimited depth
      final resultUnlimited = await CacheScanner.scan(
        priorityRoots: [testDir],
        includeDefaults: false,
        includeOptional: true,
        includeGlobal: false,
        maxDepth: 0, // Unlimited
      );

      print('\nDepth comparison:');
      print('  Limited depth (1): ${resultLimited.projectCount} projects');
      print('  Unlimited depth: ${resultUnlimited.projectCount} projects');

      // Unlimited should find at least as many projects as limited
      expect(resultUnlimited.projectCount,
          greaterThanOrEqualTo(resultLimited.projectCount));
    });
  });
}

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(2)} KB';
  }
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}
