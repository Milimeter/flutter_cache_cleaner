# Changelog

All notable changes to this project will be documented in this file.

## [0.1.1] - 2025-01-13

### Fixed
- Fixed argument parsing bug where command-specific options (--root, --include-defaults, etc.) were not recognized
- Fixed issue where global parser was rejecting unknown options before passing them to command parsers
- Improved argument parsing to correctly handle global flags both before and after command name

## [0.1.0] - 2024-01-XX

### Added
- Initial release
- Scan command to discover Flutter projects and cache files
- Clean command to remove cache files safely
- Doctor command to show environment information
- Priority path scanning
- Support for per-project and global cache targets
- Cross-platform support (macOS, Linux, Windows)

