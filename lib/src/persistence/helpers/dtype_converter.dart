import 'package:ml_linalg/dtype.dart';

/// Converts [DType] to a string representation for storage.
String dtypeToString(DType dtype) {
  switch (dtype) {
    case DType.float32:
      return 'float32';
    case DType.float64:
      return 'float64';
  }
}

/// Converts a string representation back to [DType].
DType stringToDType(String dtypeString) {
  switch (dtypeString) {
    case 'float32':
      return DType.float32;
    case 'float64':
      return DType.float64;
    default:
      throw ArgumentError('Unknown dtype: $dtypeString');
  }
}
