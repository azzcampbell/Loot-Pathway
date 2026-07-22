# Loot Pathway

Loot Pathway is a lightweight, visual gear checklist for **World of Warcraft: The Burning Crusade Classic Anniversary Edition**. It presents your equipment like a character sheet, then lays out the BIS-list targets for your active talent tree from Pre-Raid through Phase 1 and the current Phase 2.

> **Loot Pathway is intended for max-level (level 70) characters only. It is not a levelling addon.**

## Road to v1 development line

- Live character model with left-drag rotation and right-click reset.
- Clickable equipment slots with full Pre-Raid, Phase 1 and Phase 2 pathways.
- Only items present in the embedded spec BIS/alternative lists can appear.
- Quest, Dungeon, Heroic, Raid and Craftable source filters; uncategorised items remain available through All.
- The replacement drawer uses a clear six-button filter row ending in Raid and Craftable; Other items remain available through All.
- Phase section headers can be clicked to collapse or expand them, with the state remembered between sessions.
- The default interface scale and drawer typography are slightly larger, with wider rows to prevent chips and labels clipping each other.
- Equipped BIS-list position controls which later targets remain visible. Item level is display information only and never determines list membership.
- Checkbox progress, saved position and source/slot filters.
- Checked items remain visible, move beneath unowned items within their phase, and can be unticked at any time.
- Small Northern Stack Studios footer using the supplied white-and-blue NS mark.
- Blocky Loot Pathway minimap icon at 3 o'clock by default. Left-click toggles the addon, drag moves it and right-click resets its position.
- Paper-doll preview modes for Pre-Raid, Phase 1 and Phase 2; Reset returns to the character's equipped gear.
- Phase buttons dress the character model in that phase's primary BIS set; clicking a replacement item previews it on the model.
- Phase previews replace the slot icons with primary BIS-list targets. Exact or later listed gear is darkened and marked `MET` with a green tick.
- Phase previews show compact recommended gem and enchant indicators beside applicable item slots, with full details on hover.
- Trinkets appear in the right-hand equipment column beneath the rings; the bottom row is reserved for weapons and ranged/relic gear.
- Clicking an equipment slot opens a compact replacement drawer containing that phase's BIS and alternative items. In Reset mode it shows the forward pathway.
- `/lpw options` opens a lightweight options panel with a persistent minimap-button checkbox.
- Ctrl-right-clicking the minimap button hides it immediately; `/lpw options` is the recovery route.
- Replacement drawers are ranked best-first as `#1`, `#2`, and so on.
- Dungeon sources display `(N)`, `(H)`, or `(N) (H)` after their location and encounter.
- The character model uses a guarded animated loading state and is no longer reloaded when browsing slots or phases.
- Equipped current-phase BIS items receive the green `MET` treatment in the Reset view too.
- Earlier-phase BIS equipment uses a bold item-quality border and phase label rather than being mislabelled as current-phase `MET`.
- The Destruction Phase 2 rank for Voidheart Gloves is corrected to a two-piece option; its BIS phase remains Phase 1.
- The footer follows the actual Northern Stack logo composition: wordmark on the left and stepped colour blocks on the right.
- The centred `Loot Pathway` title and subtitle use the native game interface fonts.
- Standalone operation: **no other BIS addon is required or queried at runtime**.
- Checked-item progress is stored per character. Existing account-wide progress is migrated safely to the first character loaded after the schema upgrade.
- Talent detection remains automatic; specs with more than one role guide can switch guide from the character panel. Feral Combat supports both Cat and Bear.
- `/lpw selftest` runs the bundled runtime checks for profiles, guides, sources and ownership.

The 25 embedded class/spec/role guides across Pre-Raid, Phase 1 and Phase 2 are checked against the corresponding current [Wowhead TBC BIS guides](https://www.wowhead.com/tbc/guides/classes/best-in-slot-guides-burning-crusade-classic). The reviewed runtime dataset contains 7,228 entries and 1,462 unique items. Reviewed additions, removals and slot corrections live in `WowheadCorrections.lua`; the exact source manifests and repeatable auditor live under `tools/`.

## Install

Copy the `LootPathway` folder to:

`World of Warcraft/_anniversary_/Interface/AddOns/LootPathway/`

The folder must directly contain `LootPathway_TBC.toc`. Restart the game or type `/reload`, enable **Loot Pathway** at the character screen, then type `/lpw` in chat.

## Commands

- `/lpw` toggles the window.
- `/lpw options` opens the minimap-button settings.
- `/lpw refresh` refreshes equipment and cached item information.
- `/lpw selftest` validates the active profile, embedded guides, source classification and ownership behaviour.
- `/lpw reset` restores the window position.

## Data maintenance

`BisData.lua` is generated and bundled with the addon. The source manifests under `tools/` identify the exact Wowhead guide used for every supported class/spec/role and phase.

Run `tests/Test-All.ps1` before packaging. With Lua 5.1 available, it also exercises spec resolution, guide selection, ownership ordering, source and faction filters, flexible weapon slots, model-preview conflicts, fresh profiles and legacy SavedVariables migration. `/lpw selftest` provides the final runtime check inside TBC Anniversary.

## Support

Report reproducible problems through [GitHub Issues](https://github.com/azzcampbell/Loot-Pathway/issues). Please include your class, talent tree, selected guide and phase, plus the item or source involved.

## Publishing a release

Commit the addon changes first, then run:

```powershell
powershell -ExecutionPolicy Bypass -File .\Publish-Release.ps1 -Version 1.0.0
```

Before publishing, replace `CHANGELOG.md` with the complete player-facing notes for that version and show the entire file to Aaron. Only after he explicitly approves the exact wording should the command be rerun with `-ChangelogApproved`:

```powershell
powershell -ExecutionPolicy Bypass -File .\Publish-Release.ps1 -Version 1.0.0 -ChangelogApproved
```

The script updates the single version field, builds the matching ZIP, commits the version bump, and pushes the new tag. GitHub Actions uses the approved `CHANGELOG.md` verbatim for the GitHub release and passes the same file to CurseForge packaging.
