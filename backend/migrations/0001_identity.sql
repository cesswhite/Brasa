PRAGMA foreign_keys = ON;
CREATE TABLE accounts (id TEXT PRIMARY KEY, created_at TEXT NOT NULL);
CREATE TABLE local_sessions (token_hash TEXT PRIMARY KEY, account_id TEXT NOT NULL REFERENCES accounts(id), expires_at INTEGER NOT NULL, revoked_at INTEGER, created_at TEXT NOT NULL);
CREATE INDEX local_sessions_account ON local_sessions(account_id);
CREATE TABLE catalog_versions (hash TEXT PRIMARY KEY, version INTEGER NOT NULL, payload TEXT NOT NULL CHECK(json_valid(payload)), created_at TEXT NOT NULL);
CREATE TABLE cosmetic_definitions (inventory_id TEXT PRIMARY KEY, slot TEXT NOT NULL, cosmetic_id TEXT NOT NULL, definition TEXT NOT NULL CHECK(json_valid(definition)), catalog_hash TEXT NOT NULL REFERENCES catalog_versions(hash), UNIQUE(slot, cosmetic_id));
CREATE TABLE owned_cosmetics (account_id TEXT NOT NULL REFERENCES accounts(id), inventory_id TEXT NOT NULL REFERENCES cosmetic_definitions(inventory_id), source TEXT NOT NULL, granted_at TEXT NOT NULL, PRIMARY KEY(account_id, inventory_id));
CREATE TABLE fighters (id TEXT PRIMARY KEY, account_id TEXT NOT NULL REFERENCES accounts(id), archetype_id TEXT NOT NULL, revision INTEGER NOT NULL DEFAULT 1 CHECK(revision > 0), last_mutation TEXT NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, UNIQUE(account_id, archetype_id));
CREATE INDEX fighters_owner ON fighters(account_id);
CREATE TABLE fighter_identity (fighter_id TEXT PRIMARY KEY REFERENCES fighters(id), display_name TEXT NOT NULL, normalized_name TEXT NOT NULL);
CREATE TABLE fighter_progression (fighter_id TEXT PRIMARY KEY REFERENCES fighters(id), revision INTEGER NOT NULL DEFAULT 1, payload TEXT NOT NULL CHECK(json_valid(payload)));
CREATE TABLE fighter_appearance (fighter_id TEXT PRIMARY KEY REFERENCES fighters(id), body_style_id TEXT NOT NULL, palette_id TEXT NOT NULL, aura_id TEXT NOT NULL, trail_id TEXT NOT NULL, victory_pose_id TEXT NOT NULL, intro_animation_id TEXT NOT NULL);
CREATE VIEW equipped_cosmetics AS SELECT a.fighter_id, j.key AS slot, j.value AS cosmetic_id FROM fighter_appearance a, json_each(json_object('body_style_id',a.body_style_id,'palette_id',a.palette_id,'aura_id',a.aura_id,'trail_id',a.trail_id,'victory_pose_id',a.victory_pose_id,'intro_animation_id',a.intro_animation_id)) j;
CREATE TRIGGER appearance_owned_insert AFTER INSERT ON fighter_appearance BEGIN
 SELECT RAISE(ABORT, 'COSMETIC_NOT_OWNED') WHERE EXISTS (SELECT 1 FROM equipped_cosmetics e JOIN fighters f ON f.id=e.fighter_id LEFT JOIN cosmetic_definitions c ON c.slot=e.slot AND c.cosmetic_id=e.cosmetic_id LEFT JOIN owned_cosmetics o ON o.account_id=f.account_id AND o.inventory_id=c.inventory_id WHERE e.fighter_id=NEW.fighter_id AND o.inventory_id IS NULL);
END;
CREATE TRIGGER appearance_owned_update AFTER UPDATE ON fighter_appearance BEGIN
 SELECT RAISE(ABORT, 'COSMETIC_NOT_OWNED') WHERE EXISTS (SELECT 1 FROM equipped_cosmetics e JOIN fighters f ON f.id=e.fighter_id LEFT JOIN cosmetic_definitions c ON c.slot=e.slot AND c.cosmetic_id=e.cosmetic_id LEFT JOIN owned_cosmetics o ON o.account_id=f.account_id AND o.inventory_id=c.inventory_id WHERE e.fighter_id=NEW.fighter_id AND o.inventory_id IS NULL);
END;
CREATE TRIGGER inventory_preserve_equipped BEFORE DELETE ON owned_cosmetics BEGIN
 SELECT RAISE(ABORT, 'COSMETIC_EQUIPPED') WHERE EXISTS (SELECT 1 FROM equipped_cosmetics e JOIN fighters f ON f.id=e.fighter_id JOIN cosmetic_definitions c ON c.slot=e.slot AND c.cosmetic_id=e.cosmetic_id WHERE f.account_id=OLD.account_id AND c.inventory_id=OLD.inventory_id);
END;
CREATE TABLE fighter_snapshots (id TEXT PRIMARY KEY, fighter_id TEXT NOT NULL REFERENCES fighters(id), owner_account_id TEXT NOT NULL REFERENCES accounts(id), kind TEXT NOT NULL CHECK(kind IN ('battle_participant','opponent_listing')), reference_id TEXT NOT NULL, source_revision INTEGER NOT NULL, progression_revision INTEGER NOT NULL, catalog_hash TEXT NOT NULL REFERENCES catalog_versions(hash), payload TEXT NOT NULL CHECK(json_valid(payload)), sha256 TEXT NOT NULL, created_at TEXT NOT NULL, UNIQUE(fighter_id,kind,reference_id));
CREATE TRIGGER snapshots_immutable_update BEFORE UPDATE ON fighter_snapshots BEGIN SELECT RAISE(ABORT, 'SNAPSHOT_IMMUTABLE'); END;
CREATE TRIGGER snapshots_immutable_delete BEFORE DELETE ON fighter_snapshots BEGIN SELECT RAISE(ABORT, 'SNAPSHOT_IMMUTABLE'); END;
