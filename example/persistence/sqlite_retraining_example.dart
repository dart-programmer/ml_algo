import 'dart:io';
import 'package:ml_algo/ml_algo.dart';
import 'package:ml_algo/src/persistence/sqlite_neighbor_search_store.dart';
import 'package:ml_dataframe/ml_dataframe.dart';
import 'package:ml_linalg/vector.dart';
import 'package:sqlite3/sqlite3.dart';

/// Example demonstrating retraining workflow with SQLite persistence.
///
/// This example shows how to:
/// 1. Train a searcher from data in SQLite
/// 2. Save the trained searcher
/// 3. Retrain the searcher with new parameters
/// 4. Train directly from custom SQLite tables
///
/// This workflow is useful for offline translation applications where you
/// need to retrain models as new data becomes available.
Future<void> main() async {
  final dbPath = 'example_retraining.db';
  final store = SQLiteNeighborSearchStore(dbPath);

  try {
    // ============================================
    // Scenario 1: Train from existing searcher data
    // ============================================
    print('=== Scenario 1: Retraining from existing searcher ===\n');

    // Create initial data and train searcher
    final initialData = DataFrame([
      [0.1, 0.2, 0.3, 0.4, 0.5],
      [0.2, 0.3, 0.4, 0.5, 0.6],
      [0.3, 0.4, 0.5, 0.6, 0.7],
    ], headerExists: false);

    final originalSearcher = RandomBinaryProjectionSearcher(
      initialData,
      6,
      seed: 42,
    );

    // Save original searcher
    final originalId = await originalSearcher.saveToStore(store);
    print('Original searcher saved with ID: $originalId');

    // Retrain with different parameters
    final retrained = await store.retrainSearcher(
      originalId,
      digitCapacity: 8, // Different capacity
      seed: 999, // Different seed
    );

    print('Retrained searcher:');
    print('  - Digit Capacity: ${retrained.digitCapacity}');
    print('  - Seed: ${retrained.seed}');
    print('  - Points: ${retrained.points.rowCount}');

    // Save retrained searcher
    final retrainedId = await retrained.saveToStore(store, searcherId: 'retrained-v1');
    print('Retrained searcher saved with ID: $retrainedId\n');

    // ============================================
    // Scenario 2: Train from custom SQLite table
    // ============================================
    print('=== Scenario 2: Training from custom SQLite table ===\n');

    // Create a custom table for phrase translations
    final db = sqlite3.open(dbPath);
    db.execute('''
      CREATE TABLE IF NOT EXISTS phrase_translations (
        id INTEGER PRIMARY KEY,
        source_text TEXT NOT NULL,
        target_text TEXT NOT NULL,
        source_lang TEXT NOT NULL,
        target_lang TEXT NOT NULL,
        -- Embedding dimensions (simulating 768-dim embeddings with 5 dims for example)
        embedding_0 REAL,
        embedding_1 REAL,
        embedding_2 REAL,
        embedding_3 REAL,
        embedding_4 REAL
      )
    ''');

    // Insert sample translation data
    final insertStmt = db.prepare('''
      INSERT INTO phrase_translations 
      (source_text, target_text, source_lang, target_lang, 
       embedding_0, embedding_1, embedding_2, embedding_3, embedding_4)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''');

    // English to French translations
    insertStmt.execute(['hello', 'bonjour', 'en', 'fr', 0.1, 0.2, 0.3, 0.4, 0.5]);
    insertStmt.execute(['world', 'monde', 'en', 'fr', 0.2, 0.3, 0.4, 0.5, 0.6]);
    insertStmt.execute(['good', 'bon', 'en', 'fr', 0.3, 0.4, 0.5, 0.6, 0.7]);

    // English to Spanish translations
    insertStmt.execute(['hello', 'hola', 'en', 'es', 0.4, 0.5, 0.6, 0.7, 0.8]);
    insertStmt.execute(['world', 'mundo', 'en', 'es', 0.5, 0.6, 0.7, 0.8, 0.9]);

    insertStmt.dispose();
    db.dispose();

    print('Created phrase_translations table with sample data');

    // Train searcher from all English-to-French translations
    final enFrSearcher = await store.trainFromTable(
      'phrase_translations',
      ['embedding_0', 'embedding_1', 'embedding_2', 'embedding_3', 'embedding_4'],
      digitCapacity: 6,
      whereClause: 'source_lang = ? AND target_lang = ?',
      whereArgs: ['en', 'fr'],
    );

    print('Trained searcher for en->fr translations:');
    print('  - Points: ${enFrSearcher.points.rowCount}');
    print('  - Columns: ${enFrSearcher.points.columnCount}');

    // Save the searcher
    final enFrId = await enFrSearcher.saveToStore(store, searcherId: 'en-fr-searcher');
    print('Saved en->fr searcher with ID: $enFrId\n');

    // ============================================
    // Scenario 3: Using trainFromStore static method
    // ============================================
    print('=== Scenario 3: Using trainFromStore static method ===\n');

    // Retrain using the static method
    final retrainedStatic = await RandomBinaryProjectionSearcher.trainFromStore(
      store,
      'en-fr-searcher',
      digitCapacity: 8,
      seed: 123,
    );

    print('Retrained using static method:');
    print('  - Digit Capacity: ${retrainedStatic.digitCapacity}');
    print('  - Seed: ${retrainedStatic.seed}');

    // Query the retrained searcher
    final queryPoint = Vector.fromList([0.15, 0.25, 0.35, 0.45, 0.55]);
    final neighbours = retrainedStatic.query(queryPoint, 2, 3);

    print('\nQuery results:');
    for (final neighbour in neighbours) {
      print('  - Index: ${neighbour.index}, Distance: ${neighbour.distance.toStringAsFixed(4)}');
    }

    // ============================================
    // Summary
    // ============================================
    print('\n=== Summary ===');
    final allSearchers = await store.listSearchers();
    print('Total searchers stored: ${allSearchers.length}');
    for (final id in allSearchers) {
      final metadata = await store.getSearcherMetadata(id);
      print('  - $id: ${metadata!['pointCount']} points, capacity ${metadata['digitCapacity']}');
    }
  } finally {
    store.close();

    // Clean up example database file
    final file = File(dbPath);
    if (await file.exists()) {
      await file.delete();
      print('\nCleaned up example database file');
    }
  }
}
