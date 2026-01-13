#!/usr/bin/env dart

import 'dart:io';
import 'package:args/args.dart';
import 'commands/scan_command.dart';
import 'commands/clean_command.dart';
import 'commands/doctor_command.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('verbose', abbr: 'v', help: 'Enable verbose output')
    ..addFlag('quiet', abbr: 'q', help: 'Suppress all output except errors')
    ..addFlag('json', help: 'Output in JSON format')
    ..addFlag('no-color', help: 'Disable colored output');

  final commands = <String, CommandRunner>{};

  // Scan command
  final scanParser = ArgParser()
    ..addFlag('verbose', abbr: 'v', help: 'Enable verbose output')
    ..addFlag('quiet', abbr: 'q', help: 'Suppress all output except errors')
    ..addFlag('json', help: 'Output in JSON format')
    ..addFlag('no-color', help: 'Disable colored output')
    ..addMultiOption('root',
        abbr: 'r',
        help: 'Root directory to scan (can be specified multiple times)',
        valueHelp: 'path')
    ..addFlag('include-defaults',
        help: 'Include default scan roots (~/Developer, ~/Projects, etc.)',
        defaultsTo: false)
    ..addFlag('no-defaults',
        help: 'Exclude default scan roots (opposite of --include-defaults)',
        defaultsTo: false)
    ..addFlag('optional',
        abbr: 'o',
        help: 'Include optional cache targets (.idea, .gradle, Pods, etc.)',
        defaultsTo: false)
    ..addFlag('global',
        abbr: 'g',
        help: 'Include global cache targets (pub cache, Gradle, Xcode, etc.)',
        defaultsTo: false)
    ..addOption('depth',
        abbr: 'd',
        help: 'Maximum recursion depth (0 = unlimited)',
        defaultsTo: '0');

  commands['scan'] = CommandRunner(
    'scan',
    'Scan for Flutter projects and cache files',
    scanParser,
    (args, globalFlags) async {
      final command = ScanCommand()
        ..verbose = globalFlags['verbose'] as bool
        ..quiet = globalFlags['quiet'] as bool
        ..jsonOutput = globalFlags['json'] as bool
        ..colorOutput = !(globalFlags['no-color'] as bool)
        ..priorityRoots = (args['root'] as List<dynamic>?)
                ?.map((r) => r.toString())
                .toList() ??
            []
        ..includeDefaults = (args['include-defaults'] as bool? ?? false) &&
            !(args['no-defaults'] as bool? ?? false)
        ..includeOptional = args['optional'] as bool? ?? false
        ..includeGlobal = args['global'] as bool? ?? false
        ..maxDepth = int.tryParse(args['depth']?.toString() ?? '0') ?? 0;
      return await command.run();
    },
  );

  // Clean command
  final cleanParser = ArgParser()
    ..addFlag('verbose', abbr: 'v', help: 'Enable verbose output')
    ..addFlag('quiet', abbr: 'q', help: 'Suppress all output except errors')
    ..addFlag('json', help: 'Output in JSON format')
    ..addFlag('no-color', help: 'Disable colored output')
    ..addMultiOption('root',
        abbr: 'r',
        help: 'Root directory to scan (can be specified multiple times)',
        valueHelp: 'path')
    ..addFlag('include-defaults',
        help: 'Include default scan roots (~/Developer, ~/Projects, etc.)',
        defaultsTo: false)
    ..addFlag('no-defaults',
        help: 'Exclude default scan roots (opposite of --include-defaults)',
        defaultsTo: false)
    ..addFlag('optional',
        abbr: 'o',
        help: 'Include optional cache targets (.idea, .gradle, Pods, etc.)',
        defaultsTo: false)
    ..addFlag('global',
        abbr: 'g',
        help: 'Include global cache targets (pub cache, Gradle, Xcode, etc.)',
        defaultsTo: false)
    ..addOption('depth',
        abbr: 'd',
        help: 'Maximum recursion depth (0 = unlimited)',
        defaultsTo: '0')
    ..addFlag('apply',
        abbr: 'a',
        help: 'Actually perform deletions (required for cleaning)',
        defaultsTo: false)
    ..addFlag('yes',
        abbr: 'y', help: 'Skip confirmation prompts', defaultsTo: false)
    ..addFlag('trash',
        help: 'Move to trash instead of deleting directly', defaultsTo: false);

  commands['clean'] = CommandRunner(
    'clean',
    'Clean Flutter project and global caches',
    cleanParser,
    (args, globalFlags) async {
      final command = CleanCommand()
        ..verbose = globalFlags['verbose'] as bool
        ..quiet = globalFlags['quiet'] as bool
        ..jsonOutput = globalFlags['json'] as bool
        ..colorOutput = !(globalFlags['no-color'] as bool)
        ..priorityRoots = (args['root'] as List<dynamic>?)
                ?.map((r) => r.toString())
                .toList() ??
            []
        ..includeDefaults = (args['include-defaults'] as bool? ?? false) &&
            !(args['no-defaults'] as bool? ?? false)
        ..includeOptional = args['optional'] as bool? ?? false
        ..includeGlobal = args['global'] as bool? ?? false
        ..maxDepth = int.tryParse(args['depth']?.toString() ?? '0') ?? 0
        ..apply = args['apply'] as bool? ?? false
        ..yes = args['yes'] as bool? ?? false
        ..moveToTrash = args['trash'] as bool? ?? false;
      return await command.run();
    },
  );

  // Doctor command
  final doctorParser = ArgParser()
    ..addFlag('verbose', abbr: 'v', help: 'Enable verbose output')
    ..addFlag('quiet', abbr: 'q', help: 'Suppress all output except errors')
    ..addFlag('json', help: 'Output in JSON format')
    ..addFlag('no-color', help: 'Disable colored output');

  commands['doctor'] = CommandRunner(
    'doctor',
    'Show environment and cache location information',
    doctorParser,
    (args, globalFlags) async {
      final command = DoctorCommand()
        ..verbose = globalFlags['verbose'] as bool
        ..quiet = globalFlags['quiet'] as bool
        ..jsonOutput = globalFlags['json'] as bool
        ..colorOutput = !(globalFlags['no-color'] as bool);
      return await command.run();
    },
  );

  // Parse arguments
  ArgResults results;
  try {
    results = parser.parse(arguments);
  } catch (e) {
    stderr.writeln('Error parsing arguments: $e');
    exit(1);
  }

  // Handle global flags
  final globalFlags = {
    'verbose': results['verbose'] as bool,
    'quiet': results['quiet'] as bool,
    'json': results['json'] as bool,
    'no-color': results['no-color'] as bool,
  };

  // Get command
  if (results.rest.isEmpty) {
    _printUsage(parser, commands);
    exit(1);
  }

  final commandName = results.rest[0];
  final commandArgs = results.rest.sublist(1);

  if (!commands.containsKey(commandName)) {
    stderr.writeln('Unknown command: $commandName');
    _printUsage(parser, commands);
    exit(1);
  }

  // Parse command-specific arguments
  final commandRunner = commands[commandName]!;
  ArgResults commandResults;
  try {
    commandResults = commandRunner.parser.parse(commandArgs);
  } catch (e) {
    stderr.writeln('Error parsing command arguments: $e');
    stderr.writeln(commandRunner.parser.usage);
    exit(1);
  }

  // Extract global flags from command arguments and merge with initial global flags
  // Command-argument flags take precedence over flags before the command
  final commandGlobalFlags = {
    'verbose': commandResults.wasParsed('verbose')
        ? (commandResults['verbose'] as bool)
        : (globalFlags['verbose'] as bool),
    'quiet': commandResults.wasParsed('quiet')
        ? (commandResults['quiet'] as bool)
        : (globalFlags['quiet'] as bool),
    'json': commandResults.wasParsed('json')
        ? (commandResults['json'] as bool)
        : (globalFlags['json'] as bool),
    'no-color': commandResults.wasParsed('no-color')
        ? (commandResults['no-color'] as bool)
        : (globalFlags['no-color'] as bool),
  };

  // Run command
  try {
    final exitCode =
        await commandRunner.runner(commandResults, commandGlobalFlags);
    exit(exitCode);
  } catch (e, stackTrace) {
    stderr.writeln('Error: $e');
    if (commandGlobalFlags['verbose'] as bool) {
      stderr.writeln(stackTrace);
    }
    exit(1);
  }
}

void _printUsage(ArgParser parser, Map<String, CommandRunner> commands) {
  stdout.writeln('Flutter Cache Cleaner CLI');
  stdout.writeln('');
  stdout.writeln('Usage: flutter_cleaner <command> [options]');
  stdout.writeln('');
  stdout.writeln('Commands:');
  for (final entry in commands.entries) {
    stdout.writeln('  ${entry.key.padRight(10)} ${entry.value.description}');
  }
  stdout.writeln('');
  stdout.writeln('Global options:');
  stdout.writeln(parser.usage);
  stdout.writeln('');
  stdout.writeln(
      'Use "flutter_cleaner <command> --help" for command-specific options.');
}

class CommandRunner {
  final String name;
  final String description;
  final ArgParser parser;
  final Future<int> Function(ArgResults, Map<String, dynamic>) runner;

  CommandRunner(this.name, this.description, this.parser, this.runner);
}
