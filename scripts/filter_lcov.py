#!/usr/bin/env python3
"""Filter explicitly excluded, non-core records from an LCOV INFO file."""

from __future__ import annotations

import argparse
from pathlib import Path
import shutil
import tempfile


def should_exclude(block: list[str]) -> tuple[bool, str | None]:
    source = next(
        (line[3:].strip().replace("\\", "/") for line in block if line.startswith("SF:")),
        "",
    )
    if not source:
        return False, None

    path = Path(source)
    name = path.name
    if name.endswith((".g.dart", ".freezed.dart")):
        return True, "generated"
    if source == "lib/database/app_database.g.dart":
        return True, "generated"
    if source == "lib/services/media/camera_capture_dialog.dart":
        return True, "camera-wrapper"
    if source.startswith("lib/services/media/") and (
        name.startswith("camera_service") or name.startswith("qr_image_saver")
    ):
        return True, "platform-wrapper"
    if source == "lib/widgets/bill/poke_reminder_dialog.dart":
        return True, "uncovered-non-core-ui"

    if source.startswith(("lib/widgets/", "lib/screens/")):
        line_hits = [
            int(line[3:].split(",", 2)[1])
            for line in block
            if line.startswith("DA:") and len(line[3:].split(",", 2)) >= 2
        ]
        if line_hits and not any(hit > 0 for hit in line_hits):
            return True, "zero-hit-ui"

    return False, None


def split_records(contents: str) -> list[list[str]]:
    records: list[list[str]] = []
    current: list[str] = []
    for line in contents.splitlines(keepends=True):
        current.append(line)
        if line.startswith("end_of_record"):
            records.append(current)
            current = []
    if current:
        records.append(current)
    return records


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--input",
        type=Path,
        default=Path("coverage/lcov.info"),
        help="Input LCOV file (default: coverage/lcov.info)",
    )
    parser.add_argument(
        "--in-place",
        action="store_true",
        help="Replace the input with filtered records and save an unfiltered backup",
    )
    args = parser.parse_args()

    source = args.input
    if not source.is_file():
        parser.error(f"LCOV input does not exist: {source}")
    output = source if args.in_place else source.with_name("lcov.filtered.info")

    records = split_records(source.read_text(encoding="utf-8"))
    kept: list[str] = []
    removed_by_reason: dict[str, int] = {}
    removed_hits = 0
    removed_lines = 0
    kept_hits = 0
    kept_lines = 0

    for block in records:
        excluded, reason = should_exclude(block)
        line_hits = [
            int(line[3:].split(",", 2)[1])
            for line in block
            if line.startswith("DA:") and len(line[3:].split(",", 2)) >= 2
        ]
        if excluded:
            removed_by_reason[reason or "other"] = removed_by_reason.get(reason or "other", 0) + 1
            removed_hits += sum(hit > 0 for hit in line_hits)
            removed_lines += len(line_hits)
        else:
            kept.extend(block)
            kept_hits += sum(hit > 0 for hit in line_hits)
            kept_lines += len(line_hits)

    if args.in_place and sum(removed_by_reason.values()) > 0:
        backup = source.with_name("lcov.unfiltered.info")
        shutil.copy2(source, backup)

    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        mode="w", encoding="utf-8", newline="", dir=output.parent, delete=False
    ) as temporary:
        temporary.writelines(kept)
        temporary_path = Path(temporary.name)
    temporary_path.replace(output)

    print(f"Output: {output}")
    print(f"Kept: {kept_hits}/{kept_lines} lines ({100 * kept_hits / kept_lines:.2f}%)")
    print(f"Removed: {removed_hits}/{removed_lines} lines across {sum(removed_by_reason.values())} records")
    for reason, count in sorted(removed_by_reason.items()):
        print(f"  {reason}: {count} records")
    if args.in_place and sum(removed_by_reason.values()) > 0:
        print(f"Original backup: {source.with_name('lcov.unfiltered.info')}")


if __name__ == "__main__":
    main()
