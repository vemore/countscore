/// Not the web: nothing is stored in IndexedDB.
Future<T?> readPersistedDatabase<T>(
  T Function(List<Map<String, Object?>> Function(String sql) select) read,
) async =>
    null;
