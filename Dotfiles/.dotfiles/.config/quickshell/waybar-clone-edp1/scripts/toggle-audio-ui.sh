#!/usr/bin/env bash
# Exit 42 after closing an existing pwvucontrol process; exit 0 if none was running.
set -u

pids="$(pgrep -f 'pwvucontrol' 2>/dev/null || true)"
self_pid="$$"
parent_pid="$PPID"
found=0

while IFS= read -r pid; do
    [[ -z "$pid" ]] && continue
    [[ "$pid" == "$self_pid" || "$pid" == "$parent_pid" ]] && continue
    found=1
    kill -TERM "$pid" 2>/dev/null || true
done <<< "$pids"

if [[ "$found" -eq 1 ]]; then
    exit 42
fi
exit 0
