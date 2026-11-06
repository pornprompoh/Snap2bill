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
    source_normalized = source.replace("\\", "/")

    if source_normalized.endswith((".g.dart", ".freezed.dart")):
        return True, "generated"

    non_core_paths = {
        "lib/database/tables.dart",
        "lib/routes/app_routes.dart",
        "lib/utils/mascot_assets.dart",
        "lib/utils/join_link.dart",
        "lib/services/auth/supabase_auth_service.dart",
        "lib/services/media/camera_capture_dialog.dart",
        "lib/services/media/camera_service.dart",
        "lib/services/media/camera_service_mobile.dart",
        "lib/services/media/camera_service_web.dart",
        "lib/services/media/ocr_service.dart",
        "lib/services/media/qr_image_saver.dart",
        "lib/services/media/qr_image_saver_mobile.dart",
        "lib/services/media/qr_image_saver_web.dart",
        "lib/services/notifications/in_app_notification_service.dart",
        "lib/services/onboarding/onboarding_service.dart",
        "lib/services/join/pending_join_store.dart",
        "lib/services/storage/local_receipt_storage.dart",
        "lib/services/storage/local_receipt_storage_native.dart",
        "lib/services/storage/supabase_storage_service.dart",
        "lib/screens/common/loading_screen.dart",
        "lib/screens/common/splash_screen.dart",
        "lib/screens/common/onboarding_screen.dart",
        "lib/screens/main/main_screen.dart",
        "lib/screens/profile/profile_screen.dart",
        "lib/screens/home/home_screen.dart",
        "lib/screens/bill/lobby_screen.dart",
        "lib/screens/bill/detail_screen.dart",
        "lib/screens/bill/summary_screen.dart",
        "lib/screens/friends/friend_list_screen.dart",
        "lib/widgets/bill/poke_reminder_dialog.dart",
        "lib/widgets/bill/notification_center_dialog.dart",
        "lib/widgets/bill/receipt_image.dart",
        "lib/widgets/bill/shareable_receipt_preview_dialog.dart",
        "lib/widgets/bill/guest_dialog.dart",
        "lib/widgets/common/cached_avatar.dart",
        "lib/widgets/common/offline_status_banner.dart",
        "lib/widgets/common/shimmer_loading.dart",
        "lib/widgets/friends/friend_history_dialog.dart",
    }
    if source_normalized in non_core_paths:
        return True, "non-core-excluded"

    if source_normalized.startswith((
        "lib/services/media/",
        "lib/services/storage/",
        "lib/services/onboarding/",
        "lib/services/join/",
        "lib/services/notifications/",
        "lib/widgets/common/",
        "lib/screens/common/",
    )):
        return True, "non-core-excluded"

    if source_normalized.startswith(("lib/widgets/", "lib/screens/")):
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
