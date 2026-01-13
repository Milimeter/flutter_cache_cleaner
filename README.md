# Flutter Cache Cleaner CLI (FCC)

A cross-platform developer CLI utility designed to reclaim disk space and reduce system clutter caused by accumulated Flutter project build artifacts and global dependency caches.

## Overview

Over years of Flutter development, machines often accumulate tens of gigabytes of redundant data across multiple projects and global tooling caches. Flutter Cache Cleaner provides a **safe, transparent, and efficient** way to detect, report, and clean this data without risking source code or developer workflows.

## Features

- **Safe by default**: Dry-run mode prevents accidental deletions
- **Priority path scanning**: Scan user-specified directories first
- **Comprehensive cache detection**: Finds per-project and global caches
- **Cross-platform**: Works on macOS, Linux, and Windows
- **Efficient**: Fast scanning even with large project directories
- **Flexible**: Supports optional targets and global caches
- **JSON output**: Machine-readable output for scripting

## Installation

### From pub.dev (when published)

```bash
dart pub global activate flutter_cache_cleaner
```

### From source

```bash
git clone <repository-url>
cd flutter_cache_cleaner
dart pub global activate --source path .
```

After installation, ensure `~/.pub-cache/bin` is in your PATH, or use `dart pub global run flutter_cache_cleaner` instead.

## Usage

### Scan Command dart run lib/main.dart doctor --verbose

Scan for Flutter projects and cache files without deleting anything:

```bash
# Scan a specific directory
flutter_cleaner scan --root ~/Developer/flutter

# Scan multiple directories
flutter_cleaner scan --root ~/Developer/flutter --root ~/Projects

# Include default scan roots (~/Developer, ~/Projects, ~/Documents)
flutter_cleaner scan --root ~/Developer/flutter --include-defaults

# Include optional targets (.idea, .gradle, Pods, etc.)
flutter_cleaner scan --root ~/Developer/flutter --optional

# Include global caches (pub cache, Gradle, Xcode, etc.)
flutter_cleaner scan --root ~/Developer/flutter --global

# Limit recursion depth
flutter_cleaner scan --root ~/Developer/flutter --depth 3

# JSON output
flutter_cleaner scan --root ~/Developer/flutter --json
```

### Clean Command

Clean cache files (requires `--apply` flag for safety):

```bash
# Scan and show what would be deleted (dry-run)
flutter_cleaner clean --root ~/Developer/flutter

# Actually perform deletion
flutter_cleaner clean --root ~/Developer/flutter --apply

# Skip confirmation prompt
flutter_cleaner clean --root ~/Developer/flutter --apply --yes

# Move to trash instead of deleting directly
flutter_cleaner clean --root ~/Developer/flutter --apply --trash

# Include optional targets
flutter_cleaner clean --root ~/Developer/flutter --apply --optional

# Include global caches (use with caution!)
flutter_cleaner clean --root ~/Developer/flutter --apply --global
```

### Doctor Command

Show environment and cache location information:

```bash
# Show environment info
flutter_cleaner doctor

# JSON output
flutter_cleaner doctor --json
```

## Commands Reference

### Global Options

- `--verbose, -v`: Enable verbose output
- `--quiet, -q`: Suppress all output except errors
- `--json`: Output in JSON format
- `--no-color`: Disable colored output

### Scan Command Options

- `--root, -r <path>`: Root directory to scan (can be specified multiple times)
- `--include-defaults`: Include default scan roots (~/Developer, ~/Projects, etc.)
- `--no-defaults`: Exclude default scan roots
- `--optional, -o`: Include optional cache targets (.idea, .gradle, Pods, etc.)
- `--global, -g`: Include global cache targets (pub cache, Gradle, Xcode, etc.)
- `--depth, -d <n>`: Maximum recursion depth (0 = unlimited)

### Clean Command Options

All scan options plus:

- `--apply, -a`: **Required** - Actually perform deletions (safety measure)
- `--yes, -y`: Skip confirmation prompts
- `--trash`: Move to trash instead of deleting directly

## Cache Targets

### Per-Project Targets (Safe Default)

These are recreated automatically on the next build:

- `build/` - Flutter build output
- `.dart_tool/` - Dart tooling cache
- `.flutter-plugins` - Flutter plugins manifest
- `.flutter-plugins-dependencies` - Flutter plugins dependencies

### Optional Per-Project Targets

Included with `--optional` flag:

- `.idea/` - IntelliJ/Android Studio project files
- `android/.gradle/` - Android Gradle cache
- `ios/Pods/` - CocoaPods dependencies
- `ios/.symlinks/` - iOS symlinks

### Global Targets (Aggressive Mode)

Included with `--global` flag (opt-in only):

- **Dart/Flutter pub cache** (`~/.pub-cache` or platform equivalent)
- **Gradle global cache** (`~/.gradle/caches`)
- **Xcode DerivedData** (`~/Library/Developer/Xcode/DerivedData` - macOS only)
- **CocoaPods cache** (`~/Library/Caches/CocoaPods` - macOS only)

⚠️ **Warning**: Cleaning global caches will require re-downloading dependencies on next build, which can be time-consuming.

## Safety Guarantees

Flutter Cache Cleaner is designed with safety as the top priority:

1. **Dry-run by default**: All operations are safe unless `--apply` is explicitly passed
2. **Path validation**: All paths are resolved to absolute and verified before deletion
3. **Allowlist-only**: Only known cache targets are deleted, never arbitrary files
4. **Confirmation prompts**: Requires explicit confirmation unless `--yes` is passed
5. **Error handling**: Non-fatal errors per-path, continues processing other targets
6. **Source code protection**: Never deletes source code or developer-authored files

## Flutter Project Detection

A directory is considered a Flutter project root if it contains:

- `pubspec.yaml` **AND** at least one of:
  - `.metadata`
  - `android/`
  - `ios/`

Once detected, the directory is treated as a project root and deep recursion inside it is stopped (except known sub-packages if enabled).

## Priority Path Scanning

User-provided `--root` paths are scanned **first** and take priority over any default scan locations. This allows you to focus on specific directories where your Flutter projects are stored.

Default scan roots (when `--include-defaults` is used):
- `~/Developer`
- `~/Projects`
- `~/Documents`
- `~/StudioProjects` (Android Studio)
- `~/IdeaProjects` (IntelliJ IDEA)
- `~/workspace` (Eclipse)
- `~/Code`, `~/source`, `~/src`, `~/repos`, `~/repositories` (common workspace locations)

## Configuration

Configuration file support is available (optional). The config file is located at:

- **macOS/Linux**: `~/.flutter_cache_cleaner/config.json`
- **Windows**: `%USERPROFILE%\.flutter_cache_cleaner\config.json`

Example config:

```json
{
  "preferredRoots": [
    "~/Developer/flutter",
    "~/Projects"
  ],
  "defaultTargets": [
    "build",
    "dart_tool",
    "flutter_plugins"
  ],
  "profile": "safe"
}
```

Profiles:
- `safe`: Only required targets (build, dart_tool, flutter_plugins)
- `medium`: Required + gradle + pods
- `aggressive`: All targets including optional ones

## Examples

### Basic Usage

```bash
# 1. Scan to see what would be cleaned
flutter_cleaner scan --root ~/Developer

# 2. Review the output

# 3. Clean with confirmation
flutter_cleaner clean --root ~/Developer --apply

# 4. Or clean without confirmation
flutter_cleaner clean --root ~/Developer --apply --yes
```

### Advanced Usage

```bash
# Scan with all options
flutter_cleaner scan \
  --root ~/Developer/flutter \
  --root ~/Projects \
  --include-defaults \
  --optional \
  --global \
  --depth 5

# Clean with trash (macOS/Linux)
flutter_cleaner clean \
  --root ~/Developer/flutter \
  --apply \
  --optional \
  --trash

# JSON output for scripting
flutter_cleaner scan --root ~/Developer --json | jq '.summary.totalReclaimableSize'
```

### CI/CD Usage

```bash
# Clean without prompts for CI
flutter_cleaner clean \
  --root /path/to/projects \
  --apply \
  --yes \
  --json > cleanup-report.json
```

## Performance

Flutter Cache Cleaner is optimized for performance:

- **Metadata-only scanning**: Uses directory metadata, avoids reading file contents
- **Early pruning**: Skips known irrelevant directories (`.git`, `node_modules`, etc.)
- **Bounded concurrency**: Limits parallel operations to avoid overwhelming system
- **Deduplication**: Uses resolved real paths to avoid processing same directory twice
- **Depth limiting**: Respects `--depth` flag to limit recursion

Target performance: Scan thousands of directories in seconds with minimal memory footprint.

## Troubleshooting

### "No scan roots specified"

You must provide at least one `--root` path or use `--include-defaults`.

### "Error: --apply flag is required"

This is a safety measure. Add `--apply` to actually perform deletions.

### Permission errors

Some directories may require elevated permissions. The tool will skip these and continue with others.

### Large global caches

Global caches (especially pub cache) can be very large. Use `--global` with caution and expect longer rebuild times after cleaning.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT

## Support

For issues, questions, or feature requests, please open an issue on the GitHub repository.
