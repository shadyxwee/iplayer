
enum VortexNavTarget {
  search,
  home,
  movies,
  liveTv,
  series,
  settings,
}

enum VortexZone { sidebar, searchBar, filterBar, content }

enum VortexSortOption {
  recommended,
  nameAsc,
  nameDesc,
  releaseDate,
}

enum VortexFilterType { all, recent, inProgress, category }

class VortexActiveFilter {
  final VortexFilterType type;
  final String? categoryName;

  const VortexActiveFilter._(this.type, [this.categoryName]);

  static const all = VortexActiveFilter._(VortexFilterType.all);
  static const recent = VortexActiveFilter._(VortexFilterType.recent);
  static const inProgress = VortexActiveFilter._(VortexFilterType.inProgress);
  static VortexActiveFilter category(String name) => VortexActiveFilter._(VortexFilterType.category, name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VortexActiveFilter &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          categoryName == other.categoryName;

  @override
  int get hashCode => type.hashCode ^ categoryName.hashCode;
}
