import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api.dart';
import 'local_db.dart';

/// Pitch To Picture API prefix on P2P-backend.
const ptp = '/api/ptp/v1';

/// GET cache keyed by full path (incl. query), like react-query in the original app.
/// `ref.invalidate(apiGet)` refetches everything on screen after a mutation.
///
/// Every response is also saved in the on-device SQLite [LocalDb]; when the server can't be reached
/// the screen shows that saved copy instead of an error.
final apiGet = FutureProvider.autoDispose.family<dynamic, String>((ref, path) async {
  final db = ref.read(localDbProvider);
  try {
    final data = await ref.watch(apiClientProvider).get(path);
    unawaited(db.cachePut(path, data).catchError((_) {})); // the cache is best effort
    return data;
  } on ApiException catch (e) {
    if (e.statusCode == null) {
      final saved = await db.cacheGet(path).catchError((_) => null);
      if (saved != null) return saved;
    }
    rethrow;
  }
});

/// `withQuery('/discover', {'skill': 'Actor', 'city': ''})` → '/discover?skill=Actor' (empties dropped).
String withQuery(String path, Map<String, Object?> params) {
  final q = {
    for (final e in params.entries)
      if (e.value != null && '${e.value}'.trim().isNotEmpty) e.key: '${e.value}'.trim(),
  };
  return q.isEmpty ? path : '$path?${Uri(queryParameters: q).query}';
}
