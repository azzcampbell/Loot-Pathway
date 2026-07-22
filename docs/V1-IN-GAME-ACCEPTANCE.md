# v1 in-game acceptance

Run this checklist against the exact release-candidate ZIP in TBC Anniversary with Lua errors enabled. Record the character, result and screenshot or chat output for every row. Do not alter or delete live SavedVariables merely to manufacture a fresh-install result; use a backed-up test account or character where needed.

## Core smoke test

- [ ] Start with Loot Pathway enabled and no Lua error on login.
- [ ] Run `/lpw selftest` and record the complete pass/fail chat line.
- [ ] Open and close the main window from `/lpw` and the minimap button.
- [ ] Open `/lpw options`, hide the minimap button, restore it, then verify Ctrl-right-click hides it and the options panel recovers it.
- [ ] `/reload` and confirm window position, scale, phase, collapsed sections and minimap preference persist.

## Character and guide state

- [ ] Tick one item on character A, log into character B and confirm it is not ticked there; return to A and confirm it remains ticked.
- [ ] On an upgraded legacy profile, confirm previous ownership appears only on the first character loaded after migration.
- [ ] Change talent tree without `/reload`; confirm the class/spec/guide line, phase targets, drawer and model refresh.
- [ ] Change active talent group without `/reload`; confirm the same refresh and no stale preview label.
- [ ] On a Feral Druid, click the guide line to switch Cat to Bear, `/reload`, confirm persistence, then switch back to automatic Cat.

## Gear and model behaviour

- [ ] Test both ring slots and both trinket slots independently; `MET` must correspond to the exact inventory slot shown.
- [ ] Preview a one-hand main-hand plus off-hand combination.
- [ ] Preview a flexible one-hand item from both the Main hand and Off hand drawers.
- [ ] Preview a two-handed target and confirm the off hand is cleared rather than drawn simultaneously.
- [ ] While a phase two-hander is shown, click an off-hand replacement and confirm the conflicting two-hander is replaced.
- [ ] Test Reset, Pre-Raid, Phase 1 and Phase 2 on at least two races or body types; the model must not drop, clip outside its frame or remain on Loading.
- [ ] Click a replacement item, then another slot; confirm the preview label and model follow the selected item without moving the model frame.

## Lists, ownership and sources

- [ ] Open Head, Hands, Ring, Trinket, Main hand, Off hand and Ranged/Relic; each eligible slot must show ranked results.
- [ ] Tick a ranked item; confirm it moves to the bottom of its phase, becomes grey, keeps its rank and can be unticked.
- [ ] Collapse and reopen each phase header.
- [ ] Exercise All, Quest, Dungeon, Heroic, Raid and Craftable filters and confirm empty states are clear.
- [ ] Confirm normal dungeon drops show `(N) (H)` and heroic-only drops show `(H)`.
- [ ] Confirm Alliance-only and Horde-only entries do not appear for the opposite faction.
- [ ] Confirm current-phase BIS displays `MET`; earlier-phase BIS uses the quality border and phase label rather than current-phase `MET`.

## Display matrix

- [ ] 1920×1080 at 100% UI scale.
- [ ] 2560×1440 at 100% UI scale, if available.
- [ ] One smaller or scaled layout representative of laptop play.
- [ ] Drawer opened on both sides of the character panel near screen edges; no clipped close button, filter, row, footer or tooltip.

Acceptance requires every critical path above to pass without a Lua error. Any skipped device, faction, class or migration case must be recorded explicitly rather than counted as passed.
