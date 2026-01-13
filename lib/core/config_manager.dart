import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../utils/path_utils.dart';

/// Configuration for Flutter Cache Cleaner.
class Config {
  /// Preferred scan roots.
  final List<String> preferredRoots;

  /// Default targets to include.
  final List<String> defaultTargets;

  /// Profile name (safe, medium, aggressive).
  final String? profile;

  Config({
    this.preferredRoots = const [],
    this.defaultTargets = const [],
    this.profile,
  });

  /// Creates a Config from a JSON map.
  factory Config.fromJson(Map<String, dynamic> json) {
    return Config(
      preferredRoots: (json['preferredRoots'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      defaultTargets: (json['defaultTargets'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      profile: json['profile'] as String?,
    );
  }

  /// Converts Config to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'preferredRoots': preferredRoots,
      'defaultTargets': defaultTargets,
      if (profile != null) 'profile': profile,
    };
  }

  /// Creates a Config from a profile name.
  factory Config.fromProfile(String profileName) {
    switch (profileName.toLowerCase()) {
      case 'safe':
        return Config(
          profile: 'safe',
          defaultTargets: ['build', 'dart_tool', 'flutter_plugins'],
        );
      case 'medium':
        return Config(
          profile: 'medium',
          defaultTargets: [
            'build',
            'dart_tool',
            'flutter_plugins',
            'gradle',
            'pods'
          ],
        );
      case 'aggressive':
        return Config(
          profile: 'aggressive',
          defaultTargets: [
            'build',
            'dart_tool',
            'flutter_plugins',
            'idea',
            'gradle',
            'pods',
            'symlinks'
          ],
        );
      default:
        return Config(profile: profileName);
    }
  }
}

/// Manages configuration file operations.
class ConfigManager {
  /// Gets the config file path.
  static String getConfigPath() {
    final home = PathUtils.getHomeDirectory();
    if (home.isEmpty) {
      throw Exception('Cannot determine home directory');
    }
    return path.join(home, '.flutter_cache_cleaner', 'config.json');
  }

  /// Loads configuration from file.
  static Config? loadConfig() {
    try {
      final configPath = getConfigPath();
      if (!PathUtils.isFile(configPath)) {
        return null;
      }

      final file = File(configPath);
      final content = file.readAsStringSync();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return Config.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Saves configuration to file.
  static void saveConfig(Config config) {
    try {
      final configPath = getConfigPath();
      final configDir = Directory(path.dirname(configPath));
      if (!configDir.existsSync()) {
        configDir.createSync(recursive: true);
      }

      final file = File(configPath);
      final json = jsonEncode(config.toJson());
      file.writeAsStringSync(json);
    } catch (e) {
      throw Exception('Failed to save config: $e');
    }
  }

  /// Deletes the configuration file.
  static void deleteConfig() {
    try {
      final configPath = getConfigPath();
      if (PathUtils.isFile(configPath)) {
        File(configPath).deleteSync();
      }
    } catch (e) {
      // Ignore errors
    }
  }
}

