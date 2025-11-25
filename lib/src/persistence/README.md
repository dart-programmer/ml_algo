# SQLite Persistence for RandomBinaryProjectionSearcher

This module provides SQLite-based persistence for `RandomBinaryProjectionSearcher`, enabling efficient storage and retrieval for large-scale applications like offline translation systems.

## Quick Start

```dart
import 'package:ml_algo/ml_algo.dart';
import 'package:ml_algo/src/persistence/sqlite_neighbor_search_store.dart';
import 'package:ml_dataframe/ml_dataframe.dart';

void main() async {
  // Create store
  final store = SQLiteNeighborSearchStore('path/to/database.db');

  // Create and save searcher
  final data = DataFrame([...]);
  final searcher = RandomBinaryProjectionSearcher(data, 6);
  final searcherId = await searcher.saveToStore(store);

  // Load searcher
  final loaded = await RandomBinaryProjectionSearcher.loadFromStore(store, searcherId);

  // Query
  final neighbours = loaded!.query(point, k, searchRadius);

  // Cleanup
  store.close();
}
```

## Features

- ✅ **Save/Load**: Persist searchers to SQLite database
- ✅ **Retraining**: Retrain searchers from stored data or custom tables
- ✅ **Metadata Queries**: Get searcher info without loading full instance
- ✅ **Batch Operations**: Efficient storage with transactions
- ✅ **SQL Injection Protection**: Validated identifiers
- ✅ **Large Dataset Support**: Handles 100K+ vectors efficiently

## API Overview

### Basic Operations

```dart
// Save searcher
final id = await searcher.saveToStore(store, searcherId: 'my-id');

// Load searcher
final loaded = await RandomBinaryProjectionSearcher.loadFromStore(store, id);

// Delete searcher
final deleted = await store.deleteSearcher(id);

// List all searchers
final ids = await store.listSearchers();

// Get metadata
final metadata = await store.getSearcherMetadata(id);
```

### Retraining

```dart
// Retrain from existing searcher data
final retrained = await store.retrainSearcher(
  'existing-id',
  digitCapacity: 10,
  seed: 42,
);

// Train from custom SQLite table
final searcher = await store.trainFromTable(
  'phrase_translations',
  ['embedding_0', 'embedding_1', ..., 'embedding_767'],
  digitCapacity: 8,
  whereClause: 'source_lang = ? AND target_lang = ?',
  whereArgs: ['en', 'fr'],
);
```

## Database Schema

The implementation uses 5 tables:

1. **neighbor_searchers** - Main metadata table
2. **searcher_columns** - Column names
3. **searcher_points** - Vector data (BLOBs)
4. **searcher_random_vectors** - Random projection vectors
5. **searcher_bins** - Bin mapping structure

All tables use foreign keys with CASCADE delete for data integrity.

## Performance Considerations

### Large Datasets

For datasets with 100K+ vectors:

- **Save**: Uses transactions for atomicity, batch inserts for efficiency
- **Load**: Loads all points into memory (consider lazy loading for 1M+ vectors)
- **Query**: Same performance as in-memory searcher

### Memory Usage

- Points are stored as BLOBs (binary format)
- Full searcher is loaded into memory on `loadSearcher()`
- For very large datasets, consider:
  - Using `getSearcherMetadata()` to check size before loading
  - Implementing lazy loading (future enhancement)
  - Splitting into multiple searchers

## Security

### SQL Injection Protection

The `trainFromTable()` method validates table and column names to prevent SQL injection:

- ✅ Table names are validated
- ✅ Column names are validated
- ⚠️ WHERE clauses should use parameterized queries (`?` placeholders)

**Safe**:
```dart
whereClause: 'source_lang = ? AND target_lang = ?',
whereArgs: ['en', 'fr'],
```

**Unsafe** (don't do this):
```dart
whereClause: 'source_lang = "en"', // Direct string interpolation
```

## Error Handling

Common errors and solutions:

### Database Locked
- **Cause**: Another process is accessing the database
- **Solution**: Use connection pooling or retry logic

### Disk Full
- **Cause**: Insufficient disk space
- **Solution**: Check available space before saving large searchers

### Corrupted Database
- **Cause**: Database file corruption
- **Solution**: Restore from backup or recreate database

## Best Practices

1. **Always close the store** when done:
   ```dart
   try {
     // Use store
   } finally {
     store.close();
   }
   ```

2. **Use transactions** for multiple operations (already handled internally)

3. **Validate inputs** before calling `trainFromTable()`:
   ```dart
   if (embeddingColumns.isEmpty) {
     throw ArgumentError('embeddingColumns cannot be empty');
   }
   ```

4. **Check metadata** before loading large searchers:
   ```dart
   final metadata = await store.getSearcherMetadata(id);
   if (metadata!['pointCount'] > 100000) {
     // Consider lazy loading or splitting
   }
   ```

## Migration from JSON

If you're currently using JSON serialization:

1. Load searcher from JSON:
   ```dart
   final searcher = RandomBinaryProjectionSearcher.fromJson(jsonString);
   ```

2. Save to SQLite:
   ```dart
   final id = await searcher.saveToStore(store);
   ```

3. Use SQLite store going forward

## Limitations

- **Memory**: Full searcher loaded into memory (not lazy)
- **Concurrent Access**: Single connection (consider connection pooling for multi-threaded apps)
- **Schema Migration**: Schema version stored but migration not implemented yet

## Future Enhancements

See `IMPROVEMENTS.md` for planned features:
- Lazy loading for very large datasets
- Schema migration system
- Batch operations API
- Export/Import between stores
- Compression/Encryption support

## Examples

See `example/persistence/` directory for:
- Basic usage: `sqlite_rbps_example.dart`
- Retraining workflow: `sqlite_retraining_example.dart`

## Testing

Run tests:
```bash
dart test test/persistence/
dart test e2e/persistence/
```

## License

Same as ml_algo package.
