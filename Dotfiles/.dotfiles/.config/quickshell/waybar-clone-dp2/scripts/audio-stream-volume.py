#!/usr/bin/env python3
"""Set an application's playback stream volume using PipeWire-Pulse first.

Quickshell's PipeWire object ID and PulseAudio sink-input index are not guaranteed
 to be interchangeable. This helper resolves a sink-input by process/application
 metadata, then changes it with pactl. wpctl by PipeWire node ID is a fallback.
"""
import json
import re
import subprocess
import sys


def run(args, timeout=6):
    try:
        p = subprocess.run(args, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=timeout)
        return p.returncode, p.stdout.strip(), p.stderr.strip()
    except Exception as exc:
        return 127, "", str(exc)


def pactl_inputs():
    code, out, err = run(["pactl", "--format=json", "list", "sink-inputs"])
    if code == 0:
        try:
            data = json.loads(out)
            return [item for item in data if isinstance(item, dict)], "json"
        except Exception:
            pass
    code, out, err = run(["pactl", "list", "sink-inputs"])
    if code != 0:
        return [], ""
    items = []
    current = None
    section = ""
    for line in out.splitlines():
        m = re.match(r"\s*Sink Input #([0-9]+)", line)
        if m:
            if current:
                items.append(current)
            current = {"index": int(m.group(1)), "properties": {}}
            section = ""
            continue
        if current is None:
            continue
        if "Properties:" in line:
            section = "properties"
            continue
        if section == "properties":
            m = re.match(r'\s*([^=]+?)\s*=\s*"(.*)"\s*$', line)
            if m:
                current["properties"][m.group(1).strip()] = m.group(2).replace('\\"', '"')
    if current:
        items.append(current)
    return items, "text"


def props_of(item):
    props = item.get("properties") or item.get("Properties") or {}
    if isinstance(props, list):
        parsed = {}
        for entry in props:
            if isinstance(entry, dict):
                parsed.update(entry)
        props = parsed
    return {str(k): str(v) for k, v in props.items()} if isinstance(props, dict) else {}


def match_inputs(items, pid, app, media, node_name):
    normalized = []
    for item in items:
        props = props_of(item)
        index = item.get("index", item.get("Index", item.get("sink-input", "")))
        if index is None or str(index) == "":
            continue
        normalized.append((str(index), props))

    def val(props, *keys):
        for key in keys:
            if props.get(key):
                return props[key]
        return ""

    candidates = normalized
    if pid:
        exact_pid = [(idx, p) for idx, p in candidates if val(p, "application.process.id", "application.process.id", "pipewire.sec.pid") == pid]
        if exact_pid:
            candidates = exact_pid
    if media:
        exact_media = [(idx, p) for idx, p in candidates if val(p, "media.name", "application.name", "media.title") == media]
        if exact_media:
            candidates = exact_media
    if app:
        exact_app = [(idx, p) for idx, p in candidates if val(p, "application.name", "application.process.binary", "node.name") == app]
        if exact_app:
            candidates = exact_app
    if node_name:
        exact_node = [(idx, p) for idx, p in candidates if val(p, "node.name", "media.name") == node_name]
        if exact_node:
            candidates = exact_node
    # Prefer a unique precise match; otherwise scope to this PID/app rather than
    # accidentally changing every stream on the system.
    if len(candidates) == 1:
        return [candidates[0][0]]
    precise = []
    for idx, p in candidates:
        props = props_of({"properties": p})
        p_pid = props.get("application.process.id", "")
        p_app = props.get("application.name", "")
        p_media = props.get("media.name", "")
        if pid and p_pid != pid:
            continue
        if app and p_app != app:
            continue
        if media and p_media != media:
            continue
        if pid or app or media:
            precise.append(idx)
    return precise if precise else []


def main(argv):
    if len(argv) < 2:
        print("usage: audio-stream-volume.py NODE_ID PERCENT [PID APP MEDIA NODE_NAME]", file=sys.stderr)
        return 2
    node_id, raw_pct = argv[0], argv[1]
    try:
        percent = max(0, min(150, int(round(float(raw_pct)))))
    except ValueError:
        return 2
    args = (argv + [""] * 5)[2:7]
    pid, app, media, node_name, _pulse_id = args

    items, fmt = pactl_inputs()
    indexes = match_inputs(items, pid, app, media, node_name) if items else []
    if indexes:
        errors = []
        for index in indexes:
            code, out, err = run(["pactl", "set-sink-input-volume", index, f"{percent}%"])
            if code != 0:
                errors.append(err or out or f"pactl failed for sink-input {index}")
        if not errors:
            # Reply with the requested value so the UI can keep its thumb stable
            # while PipeWire propagates the update.
            print(percent)
            return 0

    # Fallback to the PipeWire global object ID. This is useful for native streams
    # that are not exposed as PulseAudio sink-inputs.
    code, out, err = run(["wpctl", "set-volume", node_id, f"{percent}%"])
    if code == 0:
        print(percent)
        return 0
    detail = "; ".join(part for part in (err, out) if part)
    print(detail or "Could not find a controllable application playback stream", file=sys.stderr)
    return code if code else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
