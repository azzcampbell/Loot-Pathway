# Loot Pathway

Loot Pathway is a lightweight, visual gear checklist for **World of Warcraft: The Burning Crusade Classic Anniversary Edition**. It presents your equipment like a character sheet, then lays out the BIS-list targets for your active talent tree from Pre-Raid through Phase 1 and the current Phase 2.

## Version 0.4.4

- Live character model with left-drag rotation and right-click reset.
- Clickable equipment slots with full Pre-Raid, Phase 1 and Phase 2 pathways.
- Only items present in the embedded spec BIS/alternative lists can appear.
- Quest, Dungeon, Heroic, Other and Raid source filters; raids remain visually separate.
- Equipped BIS-list position controls which later targets remain visible. Item level is display information only and never determines list membership.
- Checkbox progress, saved position and source/slot filters.
- Native, block-built Northern Stack Studios footer; no extra texture assets or libraries.
- Native minimap button at 3 o'clock by default. Left-click toggles the addon, drag moves it and right-click resets its position.
- Paper-doll preview modes for Pre-Raid, Phase 1 and Phase 2; Reset returns to the character's equipped gear.
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
- Standalone operation: **Loon Best In Slot is not required or queried at runtime**.

The bundled dataset is a standalone snapshot generated from **Loon Best In Slot 1.0.9**, containing 7,188 list entries and 1,450 unique items across Pre-Raid, Phase 1 and Phase 2. It preserves BIS and alternative ranks. It should be treated as a Loon-sourced list snapshot, not as independent confirmation that every entry matches Wowhead. For provenance checks, compare against [Wowhead's TBC BIS guide hub](https://www.wowhead.com/tbc/guides/classes/best-in-slot-guides-burning-crusade-classic).

## Install

Copy the `LootPathway` folder to:

`World of Warcraft/_anniversary_/Interface/AddOns/LootPathway/`

The folder must directly contain `LootPathway_TBC.toc`. Restart the game or type `/reload`, enable **Loot Pathway** at the character screen, then type `/lpw` in chat.

## Commands

- `/lpw` toggles the window.
- `/lpw options` opens the minimap-button settings.
- `/lpw refresh` refreshes equipment and cached item information.
- `/lpw reset` restores the window position.

## Data maintenance

`BisData.lua` is generated and bundled with the addon. The development helper at `tools/generate_bis_data.py` rebuilds the standalone snapshot from a local Loon installation; Loot Pathway itself never loads or depends on Loon.
