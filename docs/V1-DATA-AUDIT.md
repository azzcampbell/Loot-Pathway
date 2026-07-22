# v1 BIS data audit

Audit date: 22 July 2026

Loot Pathway's 25 selectable class/spec/role guides were compared by item ID with the corresponding current Wowhead TBC Anniversary lists. The checked runtime dataset contains 7,188 entries and 1,450 unique items after the reviewed correction layer is applied.

| Tier | Official guides | Linked Wowhead rows | Missing after review | Unexplained addon-only | Rank differences | Display-order differences |
|---|---:|---:|---:|---:|---:|---:|
| Pre-Raid | 25 | 2,369 | 0 | 0 | 0 | 0 |
| Phase 1 | 25 | 2,343 | 0 | 0 | 0 | 0 |
| Phase 2 | 25 | 2,412 | 0 | 0 | 0 | 0 |

The correction layer records 48 additions, eight narrowly scoped removals and nine slot corrections, each with its exact Wowhead guide URL. Addon-only entries are accepted only when the same item ID or name is explicitly present elsewhere in the relevant guide text, which covers inline alternatives and faction counterparts not linked in the main tables.

All 7,124 linked table rows retain their exact Wowhead rank wording as well as their display order. Reviewed guide-prose alternatives and faction counterparts retain deliberate Best or Optional fallback ranks. The interface groups the detailed wording into Best, Strong and Option chips while showing the original Wowhead wording in the item tooltip. The strict audit fails on a missing item, an unsupported addon-only item, a rank difference or a display-order difference.

Dungeon mode is stored separately from the guide wording. The standalone runtime map covers all 301 dungeon targets: 25 Normal-only, 148 Heroic-only and 128 available in both modes. It was generated from AtlasLootClassic's explicit TBC Normal/Heroic tables at commit `8e99341e4e779328460bf7684c0d5b22ce50ddf1`, with representative Wowhead item pages used as a cross-check. Seasonal Ahune exceptions are recorded explicitly. Unknown future dungeon items display `(?)` rather than being silently guessed as Normal.

Remaining slot-shape reports are retained as audit information rather than treated as unresolved provenance errors. They largely reflect two-handed or ranged weapons listed beneath a generic Wowhead “Weapons” heading, plus one-hand weapons deliberately eligible for both hands inside Loot Pathway.

The source manifests are:

- `tools/wowhead-pre-raid-guides.json`
- `tools/wowhead-phase1-guides.json`
- `tools/wowhead-phase2-guides.json`

Run each strict audit from the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\Audit-WowheadBis.ps1 -Manifest .\tools\wowhead-pre-raid-guides.json -Phase 0 -Strict
powershell -ExecutionPolicy Bypass -File .\tools\Audit-WowheadBis.ps1 -Manifest .\tools\wowhead-phase1-guides.json -Phase 1 -Strict
powershell -ExecutionPolicy Bypass -File .\tools\Audit-WowheadBis.ps1 -Manifest .\tools\wowhead-phase2-guides.json -Phase 2 -Strict
```

These checks require live access to Wowhead. Local and CI regression checks separately validate the embedded data structure, correction counts, guide reachability and engine behaviour without depending on the network.
