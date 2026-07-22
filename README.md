# Loot Pathway

I made Loot Pathway to answer one simple question: **what gear should I go for next, and where does it come from?**

> **Loot Pathway is intended for max-level (level 70) characters only. It is not a levelling addon.**

Loot Pathway turns your BIS lists into a clear route through Pre-Raid, Phase 1 and Phase 2. Open it, click an equipment slot and see the relevant items for your class, talent tree and selected role. They are ranked best first and show exactly where to get them, whether that means a quest, a Normal or Heroic dungeon, a raid or a profession.

The familiar character-screen layout lets you compare your equipped gear with each phase, preview items on your character and tick off anything you already own. Checked items stay visible at the bottom of the list, so you can always undo a mistake.

Loot Pathway does not guess upgrades from item level or promise that every listed item will improve your particular character. It gives you an easy-to-follow route through the BIS and alternative items in the relevant guide, so you can quickly decide what to work towards next.

## Features

- Pre-Raid, Phase 1 and Phase 2 BIS-list routes
- Ranked BIS and alternative items, with the best choices shown first
- Clear sources for quests, dungeons, Heroics, raids and crafted items
- Normal and Heroic dungeon labels
- Character-sheet layout with item and phase previews
- Recommended gems and enchants in phase previews
- Per-character owned-item checklists
- Automatic talent-tree detection and manual role selection where needed
- Feral Combat guides for both Cat and Bear
- Source filters, collapsible phases and minimap controls
- Standalone operation; no other BIS addon is needed

The 25 bundled class, spec and role guides are reviewed against the corresponding current [Wowhead TBC BIS guides](https://www.wowhead.com/tbc/guides/classes/best-in-slot-guides-burning-crusade-classic). Item level is shown for reference, but it does not decide which items appear or how they are ranked. The reviewed runtime dataset contains 7,228 entries and 1,462 unique items.

## Screenshots

![Crafted hands route](https://raw.githubusercontent.com/azzcampbell/Loot-Pathway/main/Assets/Screenshots/loot-pathway-crafting.png)

![Main-hand route](https://raw.githubusercontent.com/azzcampbell/Loot-Pathway/main/Assets/Screenshots/loot-pathway-main-hand.png)

![Trinket route](https://raw.githubusercontent.com/azzcampbell/Loot-Pathway/main/Assets/Screenshots/loot-pathway-trinkets.png)

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

## Licence

Copyright (c) 2026 Northern Stack Studios. All Rights Reserved. See [LICENSE](LICENSE).

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
