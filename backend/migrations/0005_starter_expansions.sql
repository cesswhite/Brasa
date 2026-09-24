-- Applied by catalog seeding, once per expansion across the accounts then present.
-- This ledger prevents a reseed from restoring a subsequently revoked free body.
CREATE TABLE catalog_starter_expansions (id TEXT PRIMARY KEY, applied_at TEXT NOT NULL);
