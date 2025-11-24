/// Helper functions for serializing and deserializing bin maps.
///
/// A bin map is `Map<int, List<int>>` where:
/// - Key: bin ID (integer)
/// - Value: list of point indices in that bin

/// Flattens a bin map into a list of (binId, pointIndex) pairs.
///
/// This format is suitable for storing in a SQLite table.
List<MapEntry<int, int>> flattenBinMap(Map<int, List<int>> bins) {
  final flattened = <MapEntry<int, int>>[];
  for (final entry in bins.entries) {
    final binId = entry.key;
    for (final pointIndex in entry.value) {
      flattened.add(MapEntry(binId, pointIndex));
    }
  }
  return flattened;
}

/// Reconstructs a bin map from a list of (binId, pointIndex) pairs.
///
/// The pairs are expected to be sorted by binId for efficiency.
Map<int, List<int>> reconstructBinMap(List<MapEntry<int, int>> flattened) {
  final bins = <int, List<int>>{};
  for (final entry in flattened) {
    final binId = entry.key;
    final pointIndex = entry.value;
    bins.putIfAbsent(binId, () => <int>[]).add(pointIndex);
  }
  return bins;
}
