# v1 BIS data audit

Audit date: 22 July 2026

Loot Pathway's 25 selectable class/spec/role guides were compared by item ID with the corresponding current Wowhead TBC Anniversary lists. The checked runtime dataset contains 7,228 entries and 1,462 unique items after the reviewed correction layer is applied.

| Tier | Official guides | Linked Wowhead rows | Missing after review | Unexplained addon-only | Display-order differences |
|---|---:|---:|---:|---:|---:|
| Pre-Raid | 25 | 2,369 | 0 | 0 | 0 |
| Phase 1 | 25 | 2,343 | 0 | 0 | 0 |
| Phase 2 | 25 | 2,412 | 0 | 0 | 0 |

The correction layer records 48 additions, eight narrowly scoped removals and nine slot corrections, each with its exact Wowhead guide URL. Addon-only entries are accepted only when the same item ID or name is explicitly present elsewhere in the relevant guide text, which covers inline alternatives and faction counterparts not linked in the main tables.

Every one of the 7,228 runtime entries also carries an explicit display order. Linked table items follow their order in the corresponding Wowhead slot table; alternatives mentioned only in guide prose follow the linked table items in their existing reviewed order. The strict audit fails on a missing item, an unsupported addon-only item or a display-order difference.

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
