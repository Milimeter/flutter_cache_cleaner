import 'dart:io';
import '../models/cache_target.dart';
import '../utils/platform_utils.dart';
import '../utils/path_utils.dart';

/// Defines global cache targets.
class GlobalTargets {
  /// Finds all global cache targets.
  /// Returns empty list if none are found or platform doesn't support them.
  static List<CacheTarget> findTargets() {
    final targets = <CacheTarget>[];

    // Dart/Flutter pub cache
    final pubCache = PlatformUtils.getPubCachePath();
    if (pubCache != null) {
      final size = _calculateSize(pubCache);
      targets.add(CacheTarget(
        type: 'pub_cache',
        path: pubCache,
        size: size,
        safeToDelete: true,
        isGlobal: true,
        exists: true,
      ));
    }

    // Gradle global cache
    final gradleCache = PlatformUtils.getGradleCachePath();
    if (gradleCache != null) {
      final size = _calculateSize(gradleCache);
      targets.add(CacheTarget(
        type: 'gradle_cache',
        path: gradleCache,
        size: size,
        safeToDelete: true,
        isGlobal: true,
        exists: true,
      ));
    }

    // Xcode DerivedData (macOS only)
    final xcodeDerivedData = PlatformUtils.getXcodeDerivedDataPath();
    if (xcodeDerivedData != null) {
      final size = _calculateSize(xcodeDerivedData);
      targets.add(CacheTarget(
        type: 'xcode_derived_data',
        path: xcodeDerivedData,
        size: size,
        safeToDelete: true,
        isGlobal: true,
        exists: true,
      ));
    }

    // CocoaPods cache (macOS only)
    final cocoapodsCache = PlatformUtils.getCocoaPodsCachePath();
    if (cocoapodsCache != null) {
      final size = _calculateSize(cocoapodsCache);
      targets.add(CacheTarget(
        type: 'cocoapods_cache',
        path: cocoapodsCache,
        size: size,
        safeToDelete: true,
        isGlobal: true,
        exists: true,
      ));
    }

    return targets;
  }

  /// Calculates the size of a directory in bytes.
  static int _calculateSize(String pathString) {
    return calculateDirectorySize(pathString);
  }

  /// Recalculates size using directory walking (more accurate for global caches).
  static int calculateDirectorySize(String pathString) {
    if (!PathUtils.isDirectory(pathString)) {
      if (PathUtils.isFile(pathString)) {
        try {
          return File(pathString).lengthSync();
        } catch (e) {
          return 0;
        }
      }
      return 0;
    }

    int total = 0;
    try {
      final dir = Directory(pathString);
      final files = dir.listSync(recursive: true, followLinks: false);
      for (final file in files) {
        if (file is File) {
          try {
            total += file.lengthSync();
          } catch (e) {
            // Skip files that can't be read
          }
        }
      }
    } catch (e) {
      // If directory can't be read, return 0
    }
    return total;
  }
}

