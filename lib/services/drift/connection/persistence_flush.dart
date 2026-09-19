import 'package:drift/drift.dart';

/// Makes the web database durable across a reload.
///
/// On the web, drift keeps the SQLite file in memory and writes it to
/// IndexedDB only when its worker "flushes" (`WasmStorageImplementation`
/// `sharedIndexedDb` / `unsafeIndexedDb`, which Chromium gets whenever the page
/// is not cross-origin isolated — the production PWA, GitHub Pages and a local
/// build alike). drift 2.35.0 flushes after a statement that runs **outside**
/// a transaction, and nowhere else:
///
/// - the `PRAGMA user_version` it writes once migrations have run is never
///   flushed, so a reload finds version 0 and runs `onCreate` again;
/// - a `COMMIT` runs while the delegate still counts itself in the
///   transaction, so a transaction — deleting a game, for one — is not
///   flushed either, and a reload brings the deleted rows back.
///
/// Both only reach IndexedDB once some later statement happens to run outside
/// a transaction, and are lost if the page is reloaded first. Every flush
/// writes *all* pending pages, so this interceptor runs one cheap statement,
/// [flushStatement], outside any transaction at the two points drift misses:
/// right after the database first opens (migrations and version included),
/// and right after each outermost transaction ends.
///
/// Harmless on any other executor: it only adds a `SELECT 1`.
class PersistenceFlushInterceptor extends QueryInterceptor {
  /// The statement run to make drift's web worker flush. A read: it changes
  /// nothing, and drift flushes after any statement run through `runCustom`.
  static const flushStatement = 'SELECT 1';

  bool _flushedAfterOpen = false;

  /// The executor each outermost transaction was started from — where its
  /// flush runs once it is over. Nested transactions (savepoints) are absent.
  final Expando<QueryExecutor> _parentOf = Expando('parentOf');

  @override
  Future<bool> ensureOpen(QueryExecutor executor, QueryExecutorUser user) async {
    final opened = await executor.ensureOpen(user);
    if (!_flushedAfterOpen && executor is! TransactionExecutor) {
      _flushedAfterOpen = true;
      await executor.runCustom(flushStatement);
    }
    return opened;
  }

  @override
  TransactionExecutor beginTransaction(QueryExecutor parent) {
    final transaction = parent.beginTransaction();
    if (parent is! TransactionExecutor) {
      _parentOf[transaction] = parent;
    }
    return transaction;
  }

  @override
  Future<void> commitTransaction(TransactionExecutor inner) async {
    await inner.send();
    await _flushAfter(inner);
  }

  @override
  Future<void> rollbackTransaction(TransactionExecutor inner) async {
    try {
      await inner.rollback();
    } finally {
      // A rollback rewrites pages in memory too; flush them so memory and
      // IndexedDB agree. Never let the flush hide the rollback's own error.
      try {
        await _flushAfter(inner);
      } catch (_) {}
    }
  }

  Future<void> _flushAfter(TransactionExecutor transaction) async {
    final parent = _parentOf[transaction];
    if (parent == null) return;
    _parentOf[transaction] = null;
    await parent.runCustom(flushStatement);
  }
}
