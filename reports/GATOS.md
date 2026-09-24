# Ónix and Bruma

Two new playable companions: **Ónix**, black cat with yellow eyes, and **Bruma**, gray cat with greenish eyes. They are added at the end of the roster, preserving the indexes of the previous 13 characters. There are 15 companions and two bosses.

![Ónix and Bruma](gatos.png)

They are chosen from **League → Teammates** and **Story Mode → Teammates**. Each has independent progress, five techniques, six talents and Signature Strike. Ónix favors speed, combos and evasion; Bruma favors precision, defense and counterattacks. The values, techniques, and 6,768 balance bouts are documented in [CAT_ROSTER_BALANCE.md](CAT_ROSTER_BALANCE.md).

## Art and animation

Each cat has three transparent atlases: eight canonical poses, sixteen movement poses, and sixteen reaction poses. They are **80 new poses in six PNGs**. They include preparation, attacks, running, jumping, recovery, impacts, falling, getting up and winning. They use the existing animation player, also when customizing another archetype with their body.

Images were generated and corrected using ChatGPT's **`image_gen` built-in mode**. The tool does not expose a verifiable selector named “Image 2.5”. Transparency was produced with that same tool; accepted PNGs were copied without modifying their pixels. Godot uses JSON regions and anchors, with a common body scale per atlas. No previous images were replaced.

- [Atlas, regions, hashes and source checking](../assets/sprites/GATOS.json).
- Ónix: [full prompts](cats-provenance/onix-prompts.json), [generation history](cats-provenance/onix.json), [movement](cats-provenance/onix-movement.png), [reactions](cats-provenance/onix-reactions.png).
- Bruma: [full prompts](cats-provenance/bruma-prompts.json), [generation history](cats-provenance/bruma.json), [movement](cats-provenance/bruma-movement.png), [reactions](cats-provenance/bruma-reactions.png).

The entire roster now has **34 benches and 544 additional poses**, in addition to the eight canonical poses for each body. The [current manifest](../assets/sprites/sequences/manifest.json) includes both cats. The [previous manifest](animation-manifest-before-cats.json) preserves the provenance of the delivery of 480 poses.

## Previous games and local server

The combat rules and progression formats of League and Story are preserved. The cosmetic identity is moved from v1 to v2 so that a previous inventory can access the two free bodies without losing names, IDs, equipment or rewards. D1 includes the 0005 migration and a one-time grant when seeding the catalog. [Detail and compatibility tests](CAT_IDENTITY_MIGRATION.md). The local backend shares the 15 characters, 75 techniques, and 90 talents; His battles still use the authoritative engine and the same rules as Godot.

This extension is tested with disposable files and accounts. It does not require opening the actual games or publishing to Cloudflare.

## Verification

**16,511 Godot checks across 11 suites and 365 backend tests, with no failures.** [Verifiable summary](cats-validation/summary.json) · [Godot logs](cats-validation/headless-checks.json) · Backend log (`cats-validation/backend-tests.log`; not included).

| Check | Result |
|---|---:|
| Data, techniques, progression and previous games | 721 |
| Previous identity migration | 95 |
| Canonical atlas of the bodies 17 | 5,419 |
| 34 animation banks, framing and both directions | 7,010 |
| Cosmetic identity and persistence | 982 |
| Identity integration in Main | 86 |
| Save errors and replays | 28 |
| Compatibility of the previous Mexican squad | 816 |
| Online interface and cat previews | 758 |
| Story Mode panels in seven sizes | 443 |
| Native tour of both cats | 153 |

The native tour selects, customizes, battles, rewards and recharges both characters in **1360×880** and **390×844**, in League and Story. The eight battle captures are taken during observed active engine contacts, without imposing a frame or result. [Capture Log](cats-validation/native-observations.json).

The card was adjusted to show repeated biographies only once and the Story Mode cards were given enough height so that their last line can be read. **92 above art files** retain their hashes exactly. No combat formulas or previous profiles in the catalog were changed.

Balance validation includes **6,768 battles** and **16/16 entire campaigns of 100 encounters**; The results and their limits are in the balance report.

![Selection of new companions](cats-validation/story-onix-1360x880.png)

[Ónix Battle on Desktop](cats-validation/battle-onix-1360x880.png) · [Bruma Battle on Mobile](cats-validation/battle-bruma-390x844.png) · [Ónix Token](cats-validation/league-onix-390x844.png).
