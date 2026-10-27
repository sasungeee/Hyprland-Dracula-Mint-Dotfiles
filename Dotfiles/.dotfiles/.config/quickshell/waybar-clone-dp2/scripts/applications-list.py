#!/usr/bin/env python3
"""Read XDG desktop applications and mirror Rofi drun usage ordering.

The Quickshell launcher renders the UI itself. This helper reads the same
installed .desktop inventory and Rofi's drun usage cache (usually
~/.cache/rofi3.druncache), where lines are commonly written as
"512 firefox.desktop". Higher usage counts are listed first, as in Rofi.
"""
import configparser
import json
import os
import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlparse

HOME = Path.home()
DATA_HOME = Path(os.environ.get("XDG_DATA_HOME", str(HOME / ".local/share")))
DATA_DIRS = os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":")
CACHE_HOME = Path(os.environ.get("XDG_CACHE_HOME", str(HOME / ".cache")))


def localized_value(section, key):
    langs = []
    raw_groups = [os.environ.get("LANGUAGE", "").split(":"),
                  [os.environ.get("LC_ALL", ""), os.environ.get("LC_MESSAGES", ""), os.environ.get("LANG", "")]]
    for group in raw_groups:
        for raw in group:
            lang = raw.strip()
            if not lang or lang == "C":
                continue
            lang = lang.split(".", 1)[0].split("@", 1)[0]
            if lang not in langs:
                langs.append(lang)
            base = lang.split("_", 1)[0]
            if base and base not in langs:
                langs.append(base)
    for lang in langs:
        value = section.get(f"{key}[{lang}]", "")
        if value:
            return value
    return section.get(key, "")


def read_desktop(path, desktop_id):
    parser = configparser.ConfigParser(interpolation=None, strict=False, delimiters=("=",))
    parser.optionxform = str
    try:
        with path.open("r", encoding="utf-8", errors="replace") as stream:
            parser.read_file(stream)
        entry = parser["Desktop Entry"]
    except (OSError, KeyError, configparser.Error):
        return None

    if entry.get("Type", "Application") != "Application":
        return None
    if entry.get("Hidden", "false").strip().lower() == "true":
        return None
    if entry.get("NoDisplay", "false").strip().lower() == "true":
        return None
    if not entry.get("Exec", "").strip() and entry.get("DBusActivatable", "false").lower() != "true":
        return None

    name = localized_value(entry, "Name").strip()
    if not name:
        return None
    try_exec = entry.get("TryExec", "").strip()
    if try_exec and "/" not in try_exec:
        from shutil import which
        if which(try_exec) is None:
            return None
    elif try_exec and not Path(try_exec).exists():
        return None

    return {
        "desktopId": desktop_id,
        "path": str(path.resolve()),
        "name": name,
        "genericName": localized_value(entry, "GenericName").strip(),
        "comment": localized_value(entry, "Comment").strip(),
        "icon": entry.get("Icon", "").strip(),
    }


def cache_candidates():
    # rofi3.druncache is the common filename; retain alternates for old builds.
    names = ["rofi3.druncache", "rofi-3.druncache", "rofi 3.druncache",
             "rofi2.druncache", "rofi-2.druncache", "rofi 2.druncache"]
    return [CACHE_HOME / name for name in names]


def read_history_entries():
    """Return (token, score, original-order) records from the first usable cache."""
    for cache in cache_candidates():
        if not cache.is_file():
            continue
        try:
            lines = cache.read_text(encoding="utf-8", errors="replace").splitlines()
        except OSError:
            continue

        entries = []
        seen = set()
        for line_index, raw_line in enumerate(lines):
            line = raw_line.strip().strip("\x00")
            if not line:
                continue

            # Current/common Rofi drun cache format: usage-count + desktop ID.
            match = re.match(r"^\s*(\d+)\s+(.+?\.desktop)(?:\s|$)", line)
            if match:
                score = int(match.group(1))
                token = match.group(2).strip()
            else:
                # Compatibility for older/custom cache layouts that store a
                # URI or path without a numeric count.
                score = None
                candidates = re.split(r":::+|\t+|\s{2,}", line)
                token = next((part.strip() for part in candidates if ".desktop" in part), "")
                if not token:
                    # A plain desktop ID can be separated from a counter with
                    # a single space in less common historical formats.
                    match = re.search(r"([^\s]+\.desktop)(?:\s|$)", line)
                    token = match.group(1) if match else ""
            if not token:
                continue
            token = token.strip().strip("\x00")
            if token.startswith("file://"):
                token = unquote(urlparse(token).path)
            elif token.startswith("file:"):
                token = unquote(token[5:])
            if ".desktop" in token:
                token = token[:token.find(".desktop") + len(".desktop")]
            token = unquote(token)
            if token in seen:
                continue
            seen.add(token)
            entries.append((token, score, line_index))
        if entries:
            return entries
    return []


def make_history_ranks(apps):
    by_path = {os.path.normpath(app["path"]): app["desktopId"] for app in apps}
    by_id = {app["desktopId"]: app["desktopId"] for app in apps}
    by_basename = {}
    for app in apps:
        by_basename.setdefault(os.path.basename(app["desktopId"]), app["desktopId"])

    ranks = {}
    for token, score, order in read_history_entries():
        candidate = token.replace("\\", "/")
        desktop_id = None
        normalized = os.path.normpath(candidate)
        if normalized in by_path:
            desktop_id = by_path[normalized]
        else:
            # Convert a path below an applications directory into a desktop ID
            # (directory separators in the ID become hyphens).
            marker = "/applications/"
            if marker in candidate:
                relative = candidate.rsplit(marker, 1)[1]
                desktop_id = by_id.get(relative.replace("/", "-"))
            if desktop_id is None:
                desktop_id = by_id.get(candidate)
            if desktop_id is None and "/" in candidate:
                desktop_id = by_id.get(candidate.replace("/", "-"))
            if desktop_id is None:
                desktop_id = by_basename.get(os.path.basename(candidate))
        if desktop_id is not None and desktop_id not in ranks:
            # Use real counters when available. Legacy entries keep their
            # order by converting it into a descending synthetic score.
            ranks[desktop_id] = (score if score is not None else -order, order)
    return ranks


def main():
    roots = [DATA_HOME / "applications"] + [Path(p) / "applications" for p in DATA_DIRS if p]
    apps_by_id = {}
    # User entries override system entries, with standard XDG desktop IDs
    # derived from relative paths (nested directories use hyphens).
    for root in roots:
        if not root.is_dir():
            continue
        for path in sorted(root.rglob("*.desktop"), key=lambda p: str(p).casefold()):
            try:
                desktop_id = path.relative_to(root).as_posix().replace("/", "-")
            except ValueError:
                desktop_id = path.name
            if desktop_id in apps_by_id:
                continue
            app = read_desktop(path, desktop_id)
            if app:
                apps_by_id[desktop_id] = app

    apps = list(apps_by_id.values())
    ranks = make_history_ranks(apps)
    apps.sort(key=lambda app: (0, -ranks[app["desktopId"]][0], ranks[app["desktopId"]][1])
              if app["desktopId"] in ranks else (1, 0, app["name"].casefold()))
    json.dump(apps, sys.stdout, ensure_ascii=False, separators=(",", ":"))
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
