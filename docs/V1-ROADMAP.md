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
- [ ] Review the Phase 2 audit differences: 29 current Wowhead items missing from the embedded snapshot, 22 addon-only entries and 123 slot-shape differences.
- [ ] Record and apply reviewed Phase 2 additions, removals, ranks and faction equivalents with source URLs.
- [ ] Add and audit the official Wowhead Pre-Raid guide manifest.
- [ ] Add and audit the official Wowhead Phase 1 guide manifest.
- [ ] Make unresolved provenance differences fail the release-candidate gate.

The Destruction Warlock Phase 2 pilot currently matches all 93 Wowhead-listed item IDs. This does not prove the remaining guides or phases.

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
