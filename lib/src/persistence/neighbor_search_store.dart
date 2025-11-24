import 'package:ml_algo/src/retrieval/random_binary_projection_searcher/random_binary_projection_searcher.dart';

/// Interface for storing and retrieving [RandomBinaryProjectionSearcher] instances.
///
/// This interface provides methods to save, load, delete, and list searcher instances,
/// enabling persistence for large-scale applications like phrase translation systems.
///
/// Example:
///
/// ```dart
/// import 'package:ml_algo/ml_algo.dart';
/// import 'package:ml_dataframe/ml_dataframe.dart';
///
/// void main() async {
///   final store = SQLiteNeighborSearchStore('path/to/database.db');
///   final data = DataFrame([...]);
///   final searcher = RandomBinaryProjectionSearcher(data, 6);
///
///   // Save searcher
///   final searcherId = await searcher.saveToStore(store);
///
///   // Load searcher
///   final loadedSearcher = await RandomBinaryProjectionSearcher.loadFromStore(
///     store,
///     searcherId,
///   );
///
///   // Query
///   final neighbours = loadedSearcher!.query(point, k, searchRadius);
/// }
/// ```
abstract class NeighborSearchStore {
  /// Saves a [RandomBinaryProjectionSearcher] instance to the store.
  ///
  /// Returns the [searcherId] that can be used to retrieve the searcher later.
  /// If [searcherId] is provided, it will be used; otherwise, a unique ID will be generated.
  ///
  /// Throws an exception if the save operation fails.
  Future<String> saveSearcher(
    RandomBinaryProjectionSearcher searcher, {
    String? searcherId,
  });

  /// Loads a [RandomBinaryProjectionSearcher] instance from the store.
  ///
  /// Returns `null` if the searcher with the given [searcherId] does not exist.
  ///
  /// Throws an exception if the load operation fails.
  Future<RandomBinaryProjectionSearcher?> loadSearcher(String searcherId);

  /// Deletes a searcher instance from the store.
  ///
  /// Returns `true` if the searcher was deleted, `false` if it didn't exist.
  ///
  /// Throws an exception if the delete operation fails.
  Future<bool> deleteSearcher(String searcherId);

  /// Lists all searcher IDs stored in the store.
  ///
  /// Returns an empty list if no searchers are stored.
  ///
  /// Throws an exception if the list operation fails.
  Future<List<String>> listSearchers();

  /// Gets metadata for a searcher without loading the full instance.
  ///
  /// Returns `null` if the searcher with the given [searcherId] does not exist.
  ///
  /// The returned map contains keys such as:
  /// - `digitCapacity`: int
  /// - `seed`: int? (nullable)
  /// - `schemaVersion`: int
  /// - `dtype`: String
  /// - `columnCount`: int
  /// - `pointCount`: int
  /// - `createdAt`: String (ISO 8601 format)
  /// - `columns`: List<String>
  ///
  /// Throws an exception if the operation fails.
  Future<Map<String, dynamic>?> getSearcherMetadata(String searcherId);
}
