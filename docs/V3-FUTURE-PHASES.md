# Loot Pathway V3: future TBC phases

Status: prospective plan, not part of the active V1 release
Last researched: 22 July 2026

## Purpose

V3 will make future max-level TBC content updates primarily data releases rather than repeated UI rewrites. Loot Pathway should be able to prepare a phase in a hidden state, audit it, test it and activate it only after Blizzard confirms the Anniversary implementation.

V3 does not set release dates. Blizzard's earlier Burning Crusade Classic sequence is useful evidence, but Anniversary timing and implementation may differ.

## Expected content sequence

| Addon phase | Expected content | Systems requiring review | Confidence |
| --- | --- | --- | --- |
| Phase 3 | Battle for Mount Hyjal, Black Temple, Tier 6, new raid reputations, later PvP gear and epic gems | BIS rankings, raid and reputation sources, set tokens, gems, recipes, attunements and previous-tier availability | Expected from the historical sequence; provisional until Blizzard confirms Anniversary details |
| Phase 4 | Zul'Aman and its timed rewards | New raid loot, expanded Badge of Justice drops and vendor stock, heroic access/tuning, epic-gem sources, crafting materials and profession recipes | Expected from the historical sequence; provisional until Blizzard confirms Anniversary details |
| Phase 5 | Isle of Quel'Danas, Magisters' Terrace, Sunwell Plateau and Shattered Sun Offensive | BIS rankings, normal/heroic dungeon sources, badge vendors and costs, realm-unlocked vendors, epic gems, reputation rewards, recipes, PvP gear and final raid loot | Expected from the historical sequence; provisional until Blizzard confirms Anniversary details |

The historical Phase 3 release added Hyjal, Black Temple, Scale of the Sands and Ashtongue Deathsworn rewards, Arena Season 3 gear and new epic-gem sources. The historical Zul'Aman release materially changed badge sources and G'eras stock, heroic-key requirements, crafting-material binding and some profession recipes. The historical Sunwell release added Quel'Danas progression, Shattered Sun reputation, new badge vendors, epic gear and epic gems. These are research prompts for Anniversary, not assumptions to embed as live data.

## Product rules

1. Never expose an unconfirmed phase as current.
2. Never infer an upgrade from item level alone. Recommendations remain tied to the reviewed BIS list for the selected class, spec, role and phase.
3. Preserve older-phase BIS items and their original acquisition route when they remain relevant later.
4. Treat an item's ranking separately from how it can be acquired. One item may have several routes, and a route may only exist from a particular phase.
5. Show costs and requirements when they are useful: Badges of Justice, reputation, profession, recipe, PvP currency/rating, faction and difficulty.
6. Keep phase activation reversible. A bad or delayed data release must be hidden through configuration rather than deleted.
7. Do not duplicate unchanged gem and enchant recommendations in every phase. Store a baseline plus reviewed phase overrides.

## Phase registry

Replace the fixed Phase 0-2 assumptions in the engine and UI with one authoritative registry.

Each phase record should contain:

- stable numeric ID;
- full and compact display labels;
- status: `hidden`, `preview`, `current` or `legacy`;
- content names and release notes;
- verified Blizzard announcement URL and verification date;
- data-manifest version;
- activation flag independent of whether its data is packaged;
- optional feature flags for badge, gem, enchant, profession or PvP changes.

The UI will build its phase selector from this registry. It must cope with more than three phases without making the character panel wider. The preferred presentation is Reset plus the current phase and nearby phases, with older phases available through a compact selector. The final interaction should be tested in the reusable addon preview harness and in game before implementation is accepted.

Existing numeric phase selections and collapsed drawer sections must migrate without losing per-character ownership or guide overrides.

## Structured acquisition routes

The current compact source strings are not sufficient for content whose availability changes over time. V3 should generate structured routes with:

- source type: quest, normal dungeon, heroic dungeon, raid, craft, reputation, vendor, badge or PvP;
- zone or instance;
- encounter, quest, vendor or recipe;
- difficulty, including separate Normal and Heroic availability;
- currency and exact cost where confirmed;
- required reputation and faction;
- profession and skill requirement;
- bind or recipe restrictions where relevant;
- first and last available phase, when applicable;
- source URL and date reviewed.

The display layer can still render a short human line, but it should derive `(N)`, `(H)`, badge costs and requirements from these fields instead of punctuation inside a source string.

### Badge of Justice model

Badge handling needs its own availability table:

- which encounters award badges in each phase;
- which vendor stocks an item in each phase;
- badge cost and any additional requirements;
- whether a previously unavailable crafting material becomes purchasable;
- whether an item has another acquisition route.

This prevents a later badge change from incorrectly rewriting an item's earlier source. Filtering by Badge, Raid or Craftable should operate on the selected phase's available routes.

### Gems and enchants

For every phase and guide, V3 should review:

- recommended gems and enchants;
- epic-gem availability and source;
- reputation or profession requirements;
- unique-equipped, meta-gem and socket constraints;
- whether an old recommendation remains correct;
- recipe availability changes;
- any actual Anniversary-specific enchant changes.

If no enchant changes, the prior reviewed recommendation carries forward explicitly. We should not manufacture a change merely because a new phase launches.

## Data manifests and provenance

Every class/spec/role/phase data pack must have a machine-readable manifest containing:

- the exact Wowhead BIS guide used;
- guide title and phase validation;
- linked item IDs in displayed order;
- slot and rank;
- every acquisition route and requirement;
- recommended gems and enchants with provenance;
- Blizzard announcement used to confirm availability;
- audit date and generator version.

The strict audit must fail on:

- a missing or addon-only BIS item;
- display-order differences;
- an invalid slot;
- an unverified phase label;
- missing or contradictory source difficulty;
- badge vendor or cost differences;
- missing gem or enchant provenance;
- incomplete class/spec/role coverage.

Wowhead remains the BIS-list authority. Blizzard announcements remain the authority for Anniversary release timing and system availability. Where the two disagree or a guide is still changing, the phase stays hidden.

## Packaging and performance

The present embedded BIS source is about 920 KB uncompressed, and the latest tested addon archive is about 168 KB. A phase currently contributes roughly 2,400 runtime rows, so three further similarly sized phases could add roughly 7,200 rows and around another 0.9 MB of uncompressed generated data. This is a planning projection, not a measured V3 build.

The first V3 prototype should compare two approaches:

1. **Single addon:** simplest installation and update path. Keep it if measured login, memory and phase-switch costs remain modest.
2. **Load-on-demand phase packs:** a small core plus optional `LootPathway_Data_P3`, `P4` and `P5` modules. Use this only if measurements show a worthwhile improvement; merely splitting Lua files while loading all of them from one TOC does not reduce login work.

Generated data should deduplicate repeated item names, source names, URLs, gem sets and enchant sets. Materialise only the current or selected phase where practical.

Performance gates will be based on a recorded V1 baseline rather than arbitrary absolute promises:

- packaged and installed size;
- addon memory after login;
- first open and warm open time;
- first phase-switch and repeated phase-switch time;
- memory growth after repeatedly switching phases and slots;
- Lua errors and UI taint.

V3 should fail its release gate if an unexplained regression exceeds the agreed V1 baseline tolerance. A development-only `/lpw perf` report may expose these measurements where the client APIs support them.

## Delivery stages

### Stage 0: confirmation watch

- Monitor official Blizzard Anniversary announcements.
- Compare the announcement with the historical checklist above.
- Record differences instead of assuming the old rollout is exact.
- Do not prepare public release notes or dates until confirmed.

### Stage 1: V3 foundation

- Add the phase registry and saved-data migration.
- Make all engine loops and BIS labels registry-driven.
- Make the phase selector scale beyond three phases.
- Introduce structured acquisition routes and phase-aware badge availability.
- Add baseline-plus-override support for gems and enchants.
- Record V1 performance baselines.

### Stage 2: hidden Phase 3 pack

- Build all class/spec/role manifests from finalised Wowhead Phase 3 guides.
- Review Hyjal, Black Temple, Tier 6, reputation, PvP, crafted, gem and enchant data.
- Run strict item, ranking, source and augmentation audits.
- Package the data with `hidden` or internal `preview` status.

### Stage 3: Phase 3 acceptance

- Test fresh and migrated profiles.
- Test every guide and slot, phase preview, ownership, filters and character-model dressing.
- Verify raid, reputation, badge, craft and PvP source lines in game.
- Compare memory and timings with V1.
- Complete external player acceptance at several UI scales.

### Stage 4: activation release

- Recheck Blizzard's live Anniversary implementation.
- Rerun live Wowhead audits immediately before the release candidate.
- Switch the registry status only after all gates pass.
- Show the complete changelog for approval before any GitHub or CurseForge publication.
- Retain a one-line rollback that hides the new phase without deleting user data.

### Stage 5: repeatable Phase 4 and Phase 5 updates

- Reuse the same manifest, audit, preview, acceptance and activation pipeline.
- Give Badge of Justice, gems, recipes, reputation and source availability a dedicated change review each time.
- Treat each as a data release unless a measured product need justifies core changes.

## Test matrix

V3 is not ready until automated and in-game checks cover:

- an arbitrary number of registry phases;
- hidden, preview, current and legacy states;
- migration from the V1 Phase 0-2 saved format;
- dynamic phase-selector layout and collapsed sections;
- an item continuing across several phases without duplicate ownership;
- changing acquisition routes, badge vendors and costs;
- Normal, Heroic and dual-difficulty sources;
- gem and enchant inheritance plus phase overrides;
- reputation, profession, PvP, faction and realm-unlock requirements;
- rings, trinkets and one-hand/off-hand duplicate slots;
- complete class/spec/role coverage for every activated phase;
- package integrity, load-on-demand behaviour and performance regression.

## Relationship to V1 and V2

- **V1** remains the immediate release goal: a reliable level-70 Pre-Raid through Phase 2 addon.
- **V2** is the separate level 10+ levelling-recommendation concept. Its eligibility and scaling rules are different from max-level BIS lists.
- **V3** is the level-70 future-content system described here.

V2 and V3 may share structured sources, manifests, modular loading and test utilities. Neither should block the other or merge its recommendation rules into the other dataset.

## Decisions to make before implementation

1. Keep future phases in the main addon unless measured V3 data proves load-on-demand packs materially improve memory or load time.
2. Decide the compact UI pattern for five or more phases after preview-harness testing.
3. Set the permitted performance regression from the measured V1 baseline.
4. Decide whether users may opt into a clearly labelled preview phase, or whether preview data remains development-only.
5. Confirm the Anniversary Phase 3 announcement and final Wowhead guide set before data is considered release-ready.

## Sources used for this prospective plan

- Blizzard, [Overlords of Outland Arrives May 14](https://worldofwarcraft.blizzard.com/en-us/news/24272608/wow-bcc-anniversary-edition-overlords-of-outland-arrives-may-14) — current Anniversary Phase 2 reference.
- Blizzard, [Burning Crusade Classic: Phase 3 is Now Live](https://worldofwarcraft.blizzard.com/en-us/news/23764312) — historical Hyjal, Black Temple, reputation, PvP and epic-gem changes.
- Blizzard, [Burning Crusade Classic: Zul'Aman is Now Open](https://worldofwarcraft.blizzard.com/en-us/news/23783585/burning-crusade-classic-zulaman-is-now-open) — historical badge, dungeon, gem, material and profession changes.
- Blizzard, [Burning Crusade Classic: The Sunwell Plateau is Now Open](https://worldofwarcraft.blizzard.com/en-us/news/23789253) — historical Quel'Danas, Shattered Sun, badge, gem, PvP and Sunwell changes.
- Wowhead, [Phase 3 Updates Overview](https://www.wowhead.com/tbc/guide/phase-three-updates-overview) — planning reference for the expected BIS-guide generation.
- Wowhead, [Badge of Justice guide](https://www.wowhead.com/tbc/guide/badge-of-justice-gear-currency-wow-burning-crusade-classic) — planning reference for phase-dependent badge inventory and sources.
