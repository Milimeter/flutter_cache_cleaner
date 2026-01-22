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

  /// Prints verbose progress message (for ongoing operations).
  void printVerboseProgress(String message) {
    if (verbose && !quiet) {
      stdout.writeln('  → $message');
    }
  }

  /// Prints verbose step information (for step-by-step operations).
  void printVerboseStep(String step, [String? details]) {
    if (verbose && !quiet) {
      if (details != null) {
        stdout.writeln('  [$step] $details');
      } else {
        stdout.writeln('  [$step]');
      }
    }
  }

  /// Prints verbose timing information.
  void printVerboseTiming(String operation, Duration duration) {
    if (verbose && !quiet) {
      final seconds = duration.inMilliseconds / 1000.0;
      stdout.writeln('  ⏱  $operation: ${seconds.toStringAsFixed(2)}s');
    }
  }

  /// Gets a verbose logger function that can be passed to core classes.
  /// Returns null if verbose is disabled.
  void Function(String message)? getVerboseLogger() {
    if (verbose && !quiet) {
      return (String message) => stdout.writeln('  → $message');
    }
    return null;
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

