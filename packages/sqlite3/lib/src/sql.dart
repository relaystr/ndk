import 'dart:convert';

/// Conditions joined with AND, with their positional arguments in order.
class SqlWhere {
  final _conditions = <String>[];
  final args = <Object?>[];

  void add(String condition, [List<Object?> conditionArgs = const []]) {
    _conditions.add(condition);
    args.addAll(conditionArgs);
  }

  /// Restricts [column] to [values], ignored when they are null or empty.
  void addIn(String column, List<Object>? values) {
    if (values == null || values.isEmpty) return;
    // `IN` makes SQLite sort every match before a LIMIT, `=` keeps the index
    // order and stops early.
    if (values.length == 1) {
      add('$column = ?', [values.single]);
    } else {
      add('$column IN $jsonArray', [jsonEncode(values)]);
    }
  }

  bool get isEmpty => _conditions.isEmpty;

  @override
  String toString() => _conditions.isEmpty ? '1' : _conditions.join(' AND ');
}

const eventColumns =
    'e.id, e.pub_key, e.kind, e.created_at, e.content, e.tags, e.sig, '
    'e.valid_sig, e.sources';

/// Filters on the `events` table aliased `e`, with the same semantics as the
/// other NDK cache backends: empty lists are ignored and tag values compare
/// trimmed and lowercased.
SqlWhere eventFilter({
  List<String>? ids,
  List<String>? pubKeys,
  List<int>? kinds,
  Map<String, List<String>>? tags,
  int? since,
  int? until,
  String? search,
}) {
  final hasTagValues = tags?.values.any((v) => v.isNotEmpty) ?? false;
  final where = SqlWhere()
    ..addIn('e.id', ids)
    ..addIn('e.pub_key', pubKeys)
    // `+` lets a tag value, far more selective than a kind, drive the query.
    ..addIn(hasTagValues ? '+e.kind' : 'e.kind', kinds);
  if (since != null) where.add('e.created_at >= ?', [since]);
  if (until != null) where.add('e.created_at <= ?', [until]);
  if (search != null && search.isNotEmpty) {
    where.add(contentContains, [likeContains(search)]);
  }
  for (final MapEntry(:key, :value) in (tags ?? const {}).entries) {
    final name = key.startsWith('#') && key.length > 1 ? key.substring(1) : key;
    if (value.isEmpty) {
      where.add('e.id IN (SELECT event_id FROM event_tags WHERE name = ?)', [
        name,
      ]);
    } else {
      where.add(
        'e.id IN (SELECT event_id FROM event_tags '
        'WHERE name = ? AND value IN $jsonArray)',
        [name, jsonEncode(value.map((v) => v.toLowerCase()).toList())],
      );
    }
  }
  return where;
}

/// A subquery over a JSON array argument, which keeps lists clear of the
/// bound variable limit.
const jsonArray = '(SELECT value FROM json_each(?))';

const contentContains = r"e.content LIKE ? ESCAPE '\'";

String likeContains(String text) =>
    '%${text.replaceAllMapped(RegExp(r'[\\%_]'), (m) => '\\${m[0]}')}%';

// The fragments below mirror EventCacheStateRecord.buildForEvents. `now` is
// inlined: it is an int computed here, never caller input.

String expiredSql(String e, int now) =>
    '($e.expiration IS NOT NULL AND $e.expiration <= $now)';

String deletedSql(String e) =>
    '($e.kind != 5 AND ('
    'EXISTS (SELECT 1 FROM deletion_targets x '
    'WHERE x.event_id = $e.id AND x.pub_key = $e.pub_key) '
    'OR ($e.conflict_key IS NOT NULL AND EXISTS ('
    'SELECT 1 FROM deletion_targets x WHERE x.conflict_key = $e.conflict_key '
    'AND x.pub_key = $e.pub_key AND x.created_at >= $e.created_at))))';

/// The id of one deletion covering [e], null when none does.
String deletedBySql(String e) =>
    'CASE WHEN $e.kind = 5 THEN NULL ELSE COALESCE('
    '(SELECT x.deletion_id FROM deletion_targets x '
    'WHERE x.event_id = $e.id AND x.pub_key = $e.pub_key LIMIT 1), '
    '(SELECT x.deletion_id FROM deletion_targets x '
    'WHERE $e.conflict_key IS NOT NULL AND x.conflict_key = $e.conflict_key '
    'AND x.pub_key = $e.pub_key AND x.created_at >= $e.created_at LIMIT 1)'
    ') END';

/// Whether a newer version of [e] that can win its conflict domain exists.
String _outrankedSql(String e, int now) =>
    'EXISTS (SELECT 1 FROM events o WHERE o.conflict_key = $e.conflict_key '
    'AND (o.created_at > $e.created_at '
    'OR (o.created_at = $e.created_at AND o.id < $e.id)) '
    'AND NOT ${expiredSql('o', now)} AND NOT ${deletedSql('o')})';

String visibleSql(String e, int now) =>
    '(NOT ${expiredSql(e, now)} AND NOT ${deletedSql(e)} '
    'AND ($e.conflict_key IS NULL OR NOT ${_outrankedSql(e, now)}))';

/// `EventCacheStateRecord.isCurrent`: an expired or deleted version never
/// wins its conflict domain, events without one are always current.
String currentSql(String e, int now) =>
    '($e.conflict_key IS NULL OR (NOT ${expiredSql(e, now)} '
    'AND NOT ${deletedSql(e)} AND NOT ${_outrankedSql(e, now)}))';

/// The `superseded` hidden reason, which excludes expired and deleted events.
String supersededSql(String e, int now) =>
    '($e.conflict_key IS NOT NULL AND NOT ${expiredSql(e, now)} '
    'AND NOT ${deletedSql(e)} AND ${_outrankedSql(e, now)})';
