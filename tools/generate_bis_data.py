"""Generate Loot Pathway's standalone BIS dataset from a local Loon install."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


REGISTER_RE = re.compile(
    r'local\s+spec([012])\s*=\s*LBIS:RegisterSpec\('
    r'LBIS\.L\["([^"]+)"\],\s*LBIS\.L\["([^"]+)"\],\s*"([012])"\)'
)
ITEM_RE = re.compile(
    r'LBIS:AddItem\(spec([012]),\s*"(\d+)",\s*LBIS\.L\["([^"]+)"\],'
    r'\s*"([^"]+)"\)\s*--\s*(.*)$'
, re.MULTILINE)
GEM_RE = re.compile(
    r'LBIS:AddGem\(spec([012]),\s*"(\d+)",\s*"(\d+)",\s*"(True|False)"\)'
)
ENCHANT_RE = re.compile(
    r'LBIS:AddEnchant\(spec([012]),\s*"(\d+)",\s*LBIS\.L\["([^"]+)"\]\)'
)
SOURCE_RE = re.compile(r'^\s*\[(\d+)\]\s*=\s*\{(.*)\},?\s*$')
STRING_RE = re.compile(r'"((?:\\.|[^"\\])*)"')


def lua_unescape(value: str) -> str:
    return value.replace(r'\"', '"').replace(r"\'", "'").replace(r'\\', '\\')


def expression_text(expression: str) -> str:
    return "".join(lua_unescape(match) for match in STRING_RE.findall(expression))


def field_expression(body: str, field: str, next_field: str | None) -> str:
    start = re.search(rf'\b{re.escape(field)}\s*=\s*', body)
    if not start:
        return ""
    value_start = start.end()
    if next_field:
        end = re.search(rf',\s*{re.escape(next_field)}\s*=', body[value_start:])
        if end:
            return body[value_start:value_start + end.start()].strip()
    return body[value_start:].rstrip(" },").strip()


def read_sources(source_file: Path) -> dict[int, dict[str, str]]:
    sources: dict[int, dict[str, str]] = {}
    for line in source_file.read_text(encoding="utf-8").splitlines():
        match = SOURCE_RE.match(line)
        if not match:
            continue
        item_id = int(match.group(1))
        body = match.group(2)
        sources[item_id] = {
            "name": expression_text(field_expression(body, "Name", "SourceType")),
            "source_type": expression_text(field_expression(body, "SourceType", "Source")),
            "source": expression_text(field_expression(body, "Source", "SourceNumber")),
            "location": expression_text(field_expression(body, "SourceLocation", "SourceFaction")),
            "faction": expression_text(field_expression(body, "SourceFaction", None)) or "B",
        }
    return sources


def read_named_sources(source_file: Path) -> dict[int, dict[str, str]]:
    sources: dict[int, dict[str, str]] = {}
    for line in source_file.read_text(encoding="utf-8").splitlines():
        match = SOURCE_RE.match(line)
        if not match:
            continue
        source_id = int(match.group(1))
        body = match.group(2)
        sources[source_id] = {
            "name": expression_text(field_expression(body, "Name", "DesignId")),
            "texture": expression_text(field_expression(body, "TextureId", None)),
        }
    return sources


def lua_string(value: str) -> str:
    value = value.replace("\\", "\\\\").replace('"', '\\"')
    value = value.replace("\r", " ").replace("\n", " ")
    return f'"{value}"'


def read_version(toc: Path) -> str:
    match = re.search(r'^## Version:\s*(.+)$', toc.read_text(encoding="utf-8"), re.MULTILINE)
    return match.group(1).strip() if match else "unknown"


def generate(loon_root: Path, output: Path) -> tuple[int, int]:
    sources = read_sources(loon_root / "DB" / "ItemSources.lua")
    gem_sources = read_named_sources(loon_root / "DB" / "GemSources.lua")
    enchant_sources = read_named_sources(loon_root / "DB" / "EnchantSources.lua")
    lists: dict[str, dict[str, dict[int, list[tuple]]]] = {}
    augments: dict[str, dict[str, dict[int, dict[str, list[tuple]]]]] = {}
    unique_items: set[int] = set()
    entry_count = 0

    for guide in sorted((loon_root / "Guides").glob("*.lua")):
        text = guide.read_text(encoding="utf-8")
        registrations = {
            int(var): (class_name.upper(), spec_name, int(phase))
            for var, class_name, spec_name, phase in REGISTER_RE.findall(text)
        }
        for var, gem, quality, is_meta in GEM_RE.findall(text):
            phase_index = int(var)
            if phase_index not in registrations:
                continue
            class_token, spec_name, phase = registrations[phase_index]
            gem_id = int(gem)
            source = gem_sources.get(gem_id, {})
            bucket = augments.setdefault(class_token, {}).setdefault(spec_name, {}).setdefault(
                phase, {"gems": [], "enchants": []}
            )
            bucket["gems"].append((gem_id, source.get("name") or f"Gem {gem_id}", int(quality), is_meta == "True"))
        for var, enchant, slot in ENCHANT_RE.findall(text):
            phase_index = int(var)
            if phase_index not in registrations:
                continue
            class_token, spec_name, phase = registrations[phase_index]
            enchant_id = int(enchant)
            source = enchant_sources.get(enchant_id, {})
            bucket = augments.setdefault(class_token, {}).setdefault(spec_name, {}).setdefault(
                phase, {"gems": [], "enchants": []}
            )
            bucket["enchants"].append((enchant_id, slot, source.get("name") or f"Enchant {enchant_id}", source.get("texture") or ""))
        seen: set[tuple] = set()
        for var, item, slot, rank, comment_name in ITEM_RE.findall(text):
            phase_index = int(var)
            if phase_index not in registrations:
                continue
            class_token, spec_name, phase = registrations[phase_index]
            item_id = int(item)
            source = sources.get(item_id, {})
            record = (
                item_id,
                slot,
                rank,
                source.get("name") or comment_name.strip(),
                source.get("source_type", "Unknown"),
                source.get("source", "Unknown"),
                source.get("location", "Unknown"),
                source.get("faction", "B"),
            )
            dedupe_key = (class_token, spec_name, phase, item_id, slot, rank)
            if dedupe_key in seen:
                continue
            seen.add(dedupe_key)
            lists.setdefault(class_token, {}).setdefault(spec_name, {}).setdefault(phase, []).append(record)
            unique_items.add(item_id)
            entry_count += 1

    lines = [
        "local _, LP = ...",
        "",
        "-- Generated from Loon Best In Slot guide data. Loot Pathway has no runtime",
        "-- dependency on Loon; this table contains Pre-Raid, Phase 1 and Phase 2 only.",
        "LP.BIS_DATA_META = {",
        f"    source = {lua_string('Loon Best In Slot')},",
        f"    sourceVersion = {lua_string(read_version(loon_root / 'LoonBestInSlot.toc'))},",
        "    currentPhase = 2,",
        f"    entries = {entry_count},",
        f"    uniqueItems = {len(unique_items)},",
        "}",
        "",
        "LP.BIS_LISTS = {",
    ]
    for class_token in sorted(lists):
        lines.append(f"    [{lua_string(class_token)}] = {{")
        for spec_name in sorted(lists[class_token]):
            lines.append(f"        [{lua_string(spec_name)}] = {{")
            for phase in (0, 1, 2):
                records = lists[class_token][spec_name].get(phase, [])
                lines.append(f"            [{phase}] = {{")
                for record in records:
                    item_id, slot, rank, name, source_type, source, location, faction = record
                    values = ", ".join(
                        [str(item_id)] +
                        [lua_string(value) for value in (slot, rank, name, source_type, source, location, faction)]
                    )
                    lines.append(f"                {{{values}}},")
                lines.append("            },")
            lines.append("        },")
        lines.append("    },")
    lines.append("}")
    lines.extend(["", "LP.BIS_AUGMENTS = {"])
    for class_token in sorted(augments):
        lines.append(f"    [{lua_string(class_token)}] = {{")
        for spec_name in sorted(augments[class_token]):
            lines.append(f"        [{lua_string(spec_name)}] = {{")
            for phase in (0, 1, 2):
                phase_data = augments[class_token][spec_name].get(phase, {"gems": [], "enchants": []})
                lines.append(f"            [{phase}] = {{")
                lines.append("                gems = {")
                for gem_id, name, quality, is_meta in phase_data["gems"]:
                    lines.append(f"                    {{{gem_id}, {lua_string(name)}, {quality}, {str(is_meta).lower()}}},")
                lines.append("                },")
                lines.append("                enchants = {")
                for enchant_id, slot, name, texture in phase_data["enchants"]:
                    lines.append(f"                    {{{enchant_id}, {lua_string(slot)}, {lua_string(name)}, {lua_string(texture)}}},")
                lines.append("                },")
                lines.append("            },")
            lines.append("        },")
        lines.append("    },")
    lines.append("}")
    lines.append("")

    output.write_text("\n".join(lines), encoding="utf-8", newline="\n")
    return entry_count, len(unique_items)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--loon-root", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    entries, unique_items = generate(args.loon_root, args.output)
    print(f"Generated {args.output} with {entries} entries and {unique_items} unique items")


if __name__ == "__main__":
    main()
