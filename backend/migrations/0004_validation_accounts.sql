-- Administrative flag only; no public endpoint can set or change it.
-- Test accounts can challenge one another, never ordinary players.
ALTER TABLE accounts ADD COLUMN is_test INTEGER NOT NULL DEFAULT 0 CHECK(is_test IN (0,1));
