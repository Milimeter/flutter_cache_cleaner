/// Represents a cache target that can be cleaned.
class CacheTarget {
  /// The type of cache target (e.g., 'build', 'dart_tool', 'pub_cache').
  final String type;

  /// The absolute path to the cache target.
  final String path;

  /// The size of the cache target in bytes.
  final int size;

  /// Whether this target is safe to delete.
  final bool safeToDelete;

  /// Whether this is a global cache (true) or per-project cache (false).
  final bool isGlobal;

  /// Whether this target was actually found and exists.
  final bool exists;

  CacheTarget({
    required this.type,
    required this.path,
    required this.size,
    this.safeToDelete = true,
    this.isGlobal = false,
    this.exists = true,
  });

  /// Creates a copy of this CacheTarget with updated fields.
  CacheTarget copyWith({
    String? type,
    String? path,
    int? size,
    bool? safeToDelete,
    bool? isGlobal,
    bool? exists,
  }) {
    return CacheTarget(
      type: type ?? this.type,
      path: path ?? this.path,
      size: size ?? this.size,
      safeToDelete: safeToDelete ?? this.safeToDelete,
      isGlobal: isGlobal ?? this.isGlobal,
      exists: exists ?? this.exists,
    );
  }

  @override
  String toString() {
    return 'CacheTarget(type: $type, path: $path, size: ${_formatSize(size)}, global: $isGlobal)';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

