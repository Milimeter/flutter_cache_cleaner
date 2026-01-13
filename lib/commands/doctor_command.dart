import 'dart:io';
import 'dart:convert';
import '../utils/platform_utils.dart';
import '../utils/path_utils.dart';
import '../targets/global_targets.dart';
import 'base_command.dart';

/// Command to show environment and cache location information.
class DoctorCommand extends BaseCommand {
  /// Runs the doctor command.
  Future<int> run() async {
    try {
      final info = await _gatherInfo();

      if (jsonOutput) {
        _printJson(info);
      } else {
        _printHumanReadable(info);
      }

      return 0;
    } catch (e) {
      printError('Error: $e');
      return 1;
    }
  }

  /// Gathers environment and cache information.
  Future<Map<String, dynamic>> _gatherInfo() async {
    final info = <String, dynamic>{};

    // Platform info
    info['platform'] = PlatformUtils.getPlatformName();
    info['operatingSystem'] = Platform.operatingSystem;
    info['operatingSystemVersion'] = Platform.operatingSystemVersion;

    // Home directory
    info['homeDirectory'] = PathUtils.getHomeDirectory();

    // Flutter/Dart info
    try {
      final flutterResult = await Process.run('flutter', ['--version']);
      if (flutterResult.exitCode == 0) {
        info['flutterVersion'] = flutterResult.stdout.toString().split('\n').first;
      }
    } catch (e) {
      info['flutterVersion'] = 'Not found';
    }

    try {
      final dartResult = await Process.run('dart', ['--version']);
      if (dartResult.exitCode == 0) {
        info['dartVersion'] = dartResult.stdout.toString().trim();
      }
    } catch (e) {
      info['dartVersion'] = 'Not found';
    }

    // Cache locations
    final cacheLocations = <String, dynamic>{};

    final pubCache = PlatformUtils.getPubCachePath();
    cacheLocations['pubCache'] = pubCache ?? 'Not found';
    if (pubCache != null) {
      final size = GlobalTargets.calculateDirectorySize(pubCache);
      cacheLocations['pubCacheSize'] = size;
    }

    final gradleCache = PlatformUtils.getGradleCachePath();
    cacheLocations['gradleCache'] = gradleCache ?? 'Not found';
    if (gradleCache != null) {
      final size = GlobalTargets.calculateDirectorySize(gradleCache);
      cacheLocations['gradleCacheSize'] = size;
    }

    final xcodeDerivedData = PlatformUtils.getXcodeDerivedDataPath();
    cacheLocations['xcodeDerivedData'] = xcodeDerivedData ?? 'Not available (macOS only)';
    if (xcodeDerivedData != null) {
      final size = GlobalTargets.calculateDirectorySize(xcodeDerivedData);
      cacheLocations['xcodeDerivedDataSize'] = size;
    }

    final cocoapodsCache = PlatformUtils.getCocoaPodsCachePath();
    cacheLocations['cocoaPodsCache'] = cocoapodsCache ?? 'Not available (macOS only)';
    if (cocoapodsCache != null) {
      final size = GlobalTargets.calculateDirectorySize(cocoapodsCache);
      cacheLocations['cocoaPodsCacheSize'] = size;
    }

    info['cacheLocations'] = cacheLocations;

    // Default scan roots
    info['defaultScanRoots'] = PlatformUtils.getDefaultScanRoots();

    return info;
  }

  /// Prints information in JSON format.
  void _printJson(Map<String, dynamic> info) {
    stdout.writeln(jsonEncode(info));
  }

  /// Prints information in human-readable format.
  void _printHumanReadable(Map<String, dynamic> info) {
    printMessage('');
    printMessage('Flutter Cache Cleaner - Environment Information');
    printMessage(repeatString('=', 50));

    printMessage('');
    printMessage('Platform:');
    printMessage('  OS: ${info['platform']}');
    printMessage('  Version: ${info['operatingSystemVersion']}');
    printMessage('  Home: ${info['homeDirectory']}');

    printMessage('');
    printMessage('Tooling:');
    printMessage('  Flutter: ${info['flutterVersion']}');
    printMessage('  Dart: ${info['dartVersion']}');

    printMessage('');
    printMessage('Global Cache Locations:');
    final caches = info['cacheLocations'] as Map<String, dynamic>;
    printMessage('  Pub Cache: ${caches['pubCache']}');
    if (caches['pubCacheSize'] != null) {
      printMessage('    Size: ${formatSize(caches['pubCacheSize'] as int)}');
    }
    printMessage('  Gradle Cache: ${caches['gradleCache']}');
    if (caches['gradleCacheSize'] != null) {
      printMessage('    Size: ${formatSize(caches['gradleCacheSize'] as int)}');
    }
    printMessage('  Xcode DerivedData: ${caches['xcodeDerivedData']}');
    if (caches['xcodeDerivedDataSize'] != null) {
      printMessage('    Size: ${formatSize(caches['xcodeDerivedDataSize'] as int)}');
    }
    printMessage('  CocoaPods Cache: ${caches['cocoaPodsCache']}');
    if (caches['cocoaPodsCacheSize'] != null) {
      printMessage('    Size: ${formatSize(caches['cocoaPodsCacheSize'] as int)}');
    }

    printMessage('');
    printMessage('Default Scan Roots:');
    final roots = info['defaultScanRoots'] as List<dynamic>;
    if (roots.isEmpty) {
      printMessage('  None found');
    } else {
      for (final root in roots) {
        printMessage('  - $root');
      }
    }

    printMessage('');
  }
}

