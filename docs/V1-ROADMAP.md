# Loot Pathway v1 readiness

This document records the evidence required before Loot Pathway can be called v1.0. A checked implementation item is not automatically a passed release gate; runtime and player acceptance evidence must also be recorded.

## Correctness foundations

- [x] Per-character checked-item storage with migration from the legacy account-wide table.
- [x] Automatic talent-tree detection with persistent per-character guide overrides.
- [x] Feral Combat exposes both Cat and Bear guides.
- [x] All 25 embedded guides are reachable and contain Pre-Raid, Phase 1 and Phase 2 data.
- [x] Release builds run dataset and runtime-contract validation.
- [x] GitHub validation and release workflows perform a Lua 5.1 syntax check.
- [x] `/lpw selftest` provides an in-game runtime regression check.

## BIS provenance

- [x] A repeatable item-ID audit exists for all 25 official Wowhead Phase 2 guides.
- [x] Review the Phase 2 differences: add 29 current Wowhead items, retain 22 entries explicitly mentioned in guide text and correct nine guide-slot errors.
- [x] Record Phase 2 additions, ranks, acquisition details and item-level source URLs in the separate correction layer.
- [ ] Add and audit the official Wowhead Pre-Raid guide manifest.
- [ ] Add and audit the official Wowhead Phase 1 guide manifest.
- [ ] Make unresolved provenance differences fail the release-candidate gate.

The strict Phase 2 audit covers all 25 guides and 2,412 linked Wowhead items with no missing items and no addon-only items absent from the relevant guide text. Remaining shape differences are two-handed weapons shown under Wowhead's generic weapon headings. Pre-Raid and Phase 1 remain unverified.

## Behaviour acceptance

- [ ] Verify fresh installation and legacy SavedVariables migration in TBC Anniversary.
- [ ] Verify character isolation using two characters that own different items.
- [ ] Verify talent changes and dual-spec changes without `/reload`.
- [ ] Verify Feral Cat/Bear switching and persistence.
- [ ] Verify rings, trinkets, one-hand/off-hand and two-hand combinations.
- [ ] Verify phase-set dressing, clicked-item preview and Reset on multiple races and body types.
- [ ] Verify faction-specific items on Alliance and Horde characters.
- [ ] Verify every source filter and Normal/Heroic label against the reviewed provenance data.
- [ ] Complete a clean Lua-error-free play session with `/lpw selftest` passing.

## Release candidate

- [ ] Update product documentation, support details, licence and release metadata.
- [ ] Confirm GitHub and CurseForge packages contain identical tagged runtime files.
- [ ] Complete external player testing across different classes, roles, resolutions and UI scales.
- [ ] Resolve every critical and high-severity defect.
- [ ] Show the complete v1 changelog to Aaron and obtain explicit approval before publishing.
