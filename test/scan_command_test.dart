import 'package:test/test.dart';
import 'package:flutter_cache_cleaner/commands/scan_command.dart';
import 'dart:io';

void main() {
  group('ScanCommand', () {
    test('should run scan command on StudioProjects directory', () async {
      final testDir = '${Platform.environment['HOME']!}/StudioProjects';
      final dir = Directory(testDir);
      
      if (!await dir.exists()) {
        print('Warning: Test directory $testDir does not exist. Skipping test.');
        return;
      }

      final command = ScanCommand()
        ..priorityRoots = [testDir]
        ..includeOptional = true
        ..includeGlobal = false
        ..verbose = true
        ..jsonOutput = false;

      print('\n=== Running ScanCommand on $testDir ===\n');

      // Run the command and check the exit code
      final exitCode = await command.run();

      expect(exitCode, equals(0), reason: 'Scan command should succeed');
    });

    test('should fail when no roots specified', () async {
      final command = ScanCommand()
        ..priorityRoots = []
        ..includeDefaults = false;

      final exitCode = await command.run();

      expect(exitCode, equals(1), reason: 'Should fail when no roots specified');
    });

    test('should produce JSON output', () async {
      final testDir = '${Platform.environment['HOME']!}/StudioProjects';
      final dir = Directory(testDir);
      
      if (!await dir.exists()) {
        print('Warning: Test directory $testDir does not exist. Skipping test.');
        return;
      }

      final command = ScanCommand()
        ..priorityRoots = [testDir]
        ..includeOptional = true
        ..jsonOutput = true
        ..quiet = true; // Suppress non-JSON output

      final exitCode = await command.run();

      expect(exitCode, equals(0), reason: 'JSON output should succeed');
    });
  });
}

