import 'dart:io';
import 'package:ml_algo/ml_algo.dart';
import 'package:ml_algo/src/persistence/sqlite_neighbor_search_store.dart';
import 'package:ml_dataframe/ml_dataframe.dart';
import 'package:ml_linalg/vector.dart';

/// Example demonstrating SQLite persistence for RandomBinaryProjectionSearcher.
///
/// This example shows how to:
/// 1. Create a searcher
/// 2. Save it to SQLite
/// 3. Load it from SQLite
/// 4. Query the loaded searcher
///
/// This is useful for offline translation applications where you need to
/// persist large phrase embeddings and perform efficient similarity search.
Future<void> main() async {
  // Create sample data (simulating phrase embeddings)
  // In a real translation app, these would be embeddings from a language model
  final data = DataFrame([
    [0.1, 0.2, 0.3, 0.4, 0.5],
    [0.2, 0.3, 0.4, 0.5, 0.6],
    [0.3, 0.4, 0.5, 0.6, 0.7],
    [0.4, 0.5, 0.6, 0.7, 0.8],
    [0.5, 0.6, 0.7, 0.8, 0.9],
  ], headerExists: false);

  // Create a searcher
  final searcher = RandomBinaryProjectionSearcher(
    data,
    6, // digitCapacity
    seed: 42,
  );

  print('Created searcher with ${searcher.points.rowCount} points');

  // Create SQLite store
  final dbPath = 'example_searcher.db';
  final store = SQLiteNeighborSearchStore(dbPath);

  try {
    // Save searcher to SQLite
    final searcherId = await searcher.saveToStore(store);
    print('Searcher saved with ID: $searcherId');

    // Get metadata without loading full searcher
    final metadata = await store.getSearcherMetadata(searcherId);
    print('Metadata:');
    print('  - Digit Capacity: ${metadata!['digitCapacity']}');
    print('  - Point Count: ${metadata['pointCount']}');
    print('  - Column Count: ${metadata['columnCount']}');
    print('  - DType: ${metadata['dtype']}');

    // List all searchers
    final searchers = await store.listSearchers();
    print('\nStored searchers: ${searchers.length}');

    // Load searcher from SQLite
    final loadedSearcher =
        await RandomBinaryProjectionSearcher.loadFromStore(store, searcherId);

    if (loadedSearcher != null) {
      print('\nLoaded searcher successfully');

      // Query the loaded searcher
      final queryPoint = Vector.fromList([0.25, 0.35, 0.45, 0.55, 0.65]);
      final k = 3;
      final searchRadius = 3;

      final neighbours = loadedSearcher.query(queryPoint, k, searchRadius);

      print('\nFound ${neighbours.length} nearest neighbours:');
      for (final neighbour in neighbours) {
        print(
            '  - Index: ${neighbour.index}, Distance: ${neighbour.distance.toStringAsFixed(4)}');
      }
    }

    // Clean up: delete the searcher
    final deleted = await store.deleteSearcher(searcherId);
    print('\nSearcher deleted: $deleted');
  } finally {
    // Close the store
    store.close();

    // Clean up example database file
    final file = File(dbPath);
    if (await file.exists()) {
      await file.delete();
      print('Cleaned up example database file');
    }
  }
}
