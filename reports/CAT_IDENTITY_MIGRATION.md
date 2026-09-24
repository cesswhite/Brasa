# Ónix and Bruma identity and inventory continuity

The hotfix found and fixed two previous account crashes: the local identity file required newly added bodies to already be present, and D1 seeding updated the catalog without granting them to existing accounts. New accounts already received both.

## local file

Only the **identity sidecar goes from v1 to v2**. League and Story Mode files and progression schemes do not change.

The upload first validates the old identity, its 22 options, and appearances against its original inventory. Then add only `body_style:onix` and `body_style:bruma` in memory. Maintains account ID, individual fighter IDs, custom or legacy names, equipped bodies, dates, and inventory records. It does not grant rewards or support unknown cosmetics. A v2 file missing a required body is still invalid.

Load does not write. The following explicit save persists v2 and leaves the original v1 bytes in `.bak`; a repeated save without changes does not rotate that copy. Write failures and concurrent writers preserve the previous file. A corrupted identity remains protected even if a valid copy exists.

## Server accounts

The new migration **0005_starter_expansions.sql** creates a record of applied expansions. Catalog seeding runs `cats-v1` - delivers only the two free bodies to existing accounts and registers the application. Reseeding does not replace later revoked bodies, missing previous defaults or progress rewards. Does not change fighters, names, stats, XP or reviews.

New accounts continue to receive the initial cosmetic 24 through the existing stream. No migration queries or writes were added per HTTP request. It is necessary to apply the five migrations and seed the catalog, following [DEPLOYMENT.md](../backend/docs/DEPLOYMENT.md); this job did not execute remote actions.

## Evidence

- **95 local checks, 0 failures:** portable fixture v1 with 13 identities and 22 options, inherited names and custom body; migration, equipping both cats, shared identity between modes, exact preservation of copied progression files, corruption, rename failure and concurrency.
- **4 tests D1, 0 failures:** old accounts with 22 options; before seeding they receive 403 when creating cats and then create both correctly; identity and trained progress remain the same; revocation, reseed, SQL rollback and concurrency checked.

[Validation and hashes](cat_identity_migration_validation.json) · [Local test](../tests/test_cat_identity_migration.gd) · [D1 test](../backend/tests/cat-inventory-migration.test.mjs).

All verifications used own fixtures. No real game, remote base or personal credential was opened or written.
