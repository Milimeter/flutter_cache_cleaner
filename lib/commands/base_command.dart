import 'dart:io';

/// Base class for CLI commands.
abstract class BaseCommand {
  /// Whether verbose output is enabled.
  bool verbose = false;

  /// Whether quiet output is enabled.
  bool quiet = false;

  /// Whether JSON output is enabled.
  bool jsonOutput = false;

  /// Whether color output is enabled.
  bool colorOutput = true;

  /// Prints a message if not in quiet mode.
  void printMessage(String message) {
    if (!quiet) {
      stdout.writeln(message);
    }
  }

  /// Prints an error message.
  void printError(String message) {
    stderr.writeln(message);
  }

  /// Prints verbose message if verbose mode is enabled.
  void printVerbose(String message) {
    if (verbose && !quiet) {
      stdout.writeln(message);
    }
  }

  /// Formats a size in bytes to human-readable format.
  String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Repeats a string a given number of times.
  String repeatString(String str, int count) {
    return List.filled(count, str).join();
  }
}

