# Changelog

All notable changes to this project will be documented in this file.

## [0.1.2] - 2026-01-22

### Added
- Enhanced verbose output with real-time progress tracking
- Progress indicators showing current operation and project counts
- Timing information for major operations (scanning, analysis, cleaning)
- Detailed logging throughout core operations:
  - Project detection progress (directories scanned, projects found)
  - Cache target analysis with per-project progress (X/Y projects)
  - Cleaning progress with per-target deletion status
  - Global cache size calculation progress
- New verbose helper methods in BaseCommand:
  - `printVerboseProgress()` for ongoing operations
  - `printVerboseStep()` for step-by-step operations
  - `printVerboseTiming()` for timing information
  - `getVerboseLogger()` for passing to core classes

### Improved
- Verbose output now provides comprehensive feedback during long-running operations
- Better visibility into what the tool is doing at each stage
- More informative error context in verbose mode

## [0.1.1] - 2026-01-13

### Fixed
- Fixed argument parsing bug where command-specific options (--root, --include-defaults, etc.) were not recognized
- Fixed issue where global parser was rejecting unknown options before passing them to command parsers
- Improved argument parsing to correctly handle global flags both before and after command name

## [0.1.0] - 2025-12-20

### Added
- Initial release
- Scan command to discover Flutter projects and cache files
- Clean command to remove cache files safely
- Doctor command to show environment information
- Priority path scanning
- Support for per-project and global cache targets
- Cross-platform support (macOS, Linux, Windows)

