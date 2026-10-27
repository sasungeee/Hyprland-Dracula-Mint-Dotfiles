#!/usr/bin/env bash
set -u

# Map a Hyprland keymap name to a short label and retain the full name for
# the hidden value/tooltip field. The active-layout IPC event gives the keymap
# directly, so event updates do not need to launch hyprctl again.
format_keymap() {
  local keymap="${1:-English (US)}" lower short code
  [[ -n "$keymap" ]] || keymap='English (US)'
  lower=$(printf '%s' "$keymap" | tr '[:upper:]' '[:lower:]')
  case "$lower" in
    *ukrainian*|*ukrain*) short='ua' ;;
    *russian*) short='ru' ;;
    *english*uk*|*british*|*united\ kingdom*|*uk\ english*) short='gb' ;;
    *english*us*|*united\ states*|*american*|*us\ english*|*english*) short='us' ;;
    *german*|*deutsch*) short='de' ;;
    *french*) short='fr' ;;
    *polish*|*polski*) short='pl' ;;
    *spanish*) short='es' ;;
    *italian*|*italiano*) short='it' ;;
    *turkish*) short='tr' ;;
    *czech*) short='cz' ;;
    *swedish*) short='se' ;;
    *norwegian*) short='no' ;;
    *dutch*) short='nl' ;;
    *portuguese*) short='pt' ;;
    *arabic*) short='ar' ;;
    *romanian*) short='ro' ;;
    *greek*) short='gr' ;;
    *hebrew*) short='he' ;;
    *japanese*) short='jp' ;;
    *korean*) short='kr' ;;
    *chinese*) short='zh' ;;
    *)
      code=$(printf '%s' "$keymap" | sed -nE 's/.*\(([A-Za-z]{2})\).*/\1/p' | head -n 1)
      if [[ -n "$code" ]]; then short=$(printf '%s' "$code" | tr '[:upper:]' '[:lower:]'); else short='??'; fi
      ;;
  esac
  printf '%s|%s\n' "$short" "$keymap"
}

current_layout() {
  local layouts keymap
  layouts=$(hyprctl devices 2>/dev/null | awk -F': ' '/active keymap:/ { print $2 }')
  keymap=$(printf '%s\n' "$layouts" | grep -Fvx 'English (US)' | head -n 1 || true)
  [[ -n "$keymap" ]] || keymap='English (US)'
  format_keymap "$keymap"
}

# Emit an initial value before the event stream has a chance to send an event.
current_layout

runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
instance="${HYPRLAND_INSTANCE_SIGNATURE:-}"
socket="$runtime_dir/hypr/$instance/.socket2.sock"

# `activelayout>>KEYBOARD,LAYOUT` is delivered immediately on a layout switch.
# Map the event payload directly; if its shape is unexpected, re-read devices.
if command -v socat >/dev/null 2>&1 && [[ -n "$instance" && -S "$socket" ]]; then
  socat -U - "UNIX-CONNECT:$socket" 2>/dev/null |
    while IFS= read -r event; do
      case "$event" in
        activelayout\>\>*)
          payload=${event#*>>}
          keymap=${payload#*,}
          if [[ "$keymap" != "$payload" && -n "$keymap" ]]; then
            format_keymap "$keymap"
          else
            current_layout
          fi
          ;;
      esac
    done
fi

# Fallback when the event socket or socat is unavailable (or disconnects).
while true; do
  sleep 0.12
  current_layout
done
