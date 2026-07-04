import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Convenience extension for Riverpod 3.x [AsyncValue].
///
/// In Riverpod 3.x, `valueOrNull` was removed from [AsyncValue]. This
/// extension restores the convenience getter project-wide.
extension AsyncValueX<T> on AsyncValue<T> {
  /// Returns the data value if in the data state, otherwise null.
  T? get valueOrNull => asData?.value;
}
