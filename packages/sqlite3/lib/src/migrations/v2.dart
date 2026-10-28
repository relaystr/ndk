// NIP-05 records are keyed by identifier since #936, the cached rows are
// dropped.
const v2 = '''
DROP TABLE nip05s;
CREATE TABLE nip05s (
  nip05 TEXT NOT NULL PRIMARY KEY,
  data TEXT NOT NULL
) STRICT;
''';
