const createCountersTableSql = '''
CREATE TABLE IF NOT EXISTS counters (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  color TEXT NOT NULL,
  started_at INTEGER NOT NULL,
  period TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
''';

const createResetsTableSql = '''
CREATE TABLE IF NOT EXISTS resets (
  id TEXT PRIMARY KEY,
  counter_id TEXT NOT NULL,
  reset_at INTEGER NOT NULL,
  note TEXT,
  previous_started_at INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (counter_id) REFERENCES counters(id) ON DELETE CASCADE
);
''';

const createGoalsTableSql = '''
CREATE TABLE IF NOT EXISTS goals (
  id TEXT PRIMARY KEY,
  counter_id TEXT NOT NULL,
  target_value INTEGER NOT NULL,
  target_unit TEXT NOT NULL,
  note TEXT,
  is_completed INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (counter_id) REFERENCES counters(id) ON DELETE CASCADE
);
''';

const enableForeignKeysSql = 'PRAGMA foreign_keys = ON;';

const schemaSql = [
  createCountersTableSql,
  createResetsTableSql,
  createGoalsTableSql,
];
