#!/usr/bin/env bash
set -u

# Convert a duration to natural hour/minute wording for the battery extension.
format_duration_minutes() {
  local total_minutes="${1:-0}" hours minutes hour_word minute_word
  [[ "$total_minutes" =~ ^[0-9]+$ ]] || total_minutes=0
  hours=$((total_minutes / 60))
  minutes=$((total_minutes % 60))
  if (( hours > 0 )); then
    if (( minutes > 0 )); then
      hour_word="hour"; (( hours == 1 )) || hour_word="hours"
      minute_word="minute"; (( minutes == 1 )) || minute_word="minutes"
      printf '%d %s %d %s' "$hours" "$hour_word" "$minutes" "$minute_word"
    else
      hour_word="hour"; (( hours == 1 )) || hour_word="hours"
      printf '%d %s' "$hours" "$hour_word"
    fi
  else
    minute_word="minute"; (( minutes == 1 )) || minute_word="minutes"
    printf '%d %s' "$minutes" "$minute_word"
  fi
}

# UPower versions commonly report decimal hours (for example, 7.2 hours).
# Convert that output to an hour/minute string while retaining a fallback for
# formats that this script does not recognize.
humanize_duration() {
  local raw="${1:-}" amount unit total_minutes
  [[ -n "$raw" ]] || return 0
  if [[ "$raw" =~ ^([0-9]+([.][0-9]+)?)[[:space:]]+([[:alpha:]]+) ]]; then
    amount="${BASH_REMATCH[1]}"
    unit="${BASH_REMATCH[3],,}"
    case "$unit" in
      h|hr|hrs|hour|hours) total_minutes=$(awk -v n="$amount" 'BEGIN { printf "%d", n*60+0.5 }') ;;
      m|min|mins|minute|minutes) total_minutes=$(awk -v n="$amount" 'BEGIN { printf "%d", n+0.5 }') ;;
      d|day|days) total_minutes=$(awk -v n="$amount" 'BEGIN { printf "%d", n*1440+0.5 }') ;;
      *) printf '%s' "$raw"; return 0 ;;
    esac
    format_duration_minutes "$total_minutes"
  else
    printf '%s' "$raw"
  fi
}

# Return success when an AC/USB power source reports that it is online.
ac_connected() {
  local f source_type online
  for f in /sys/class/power_supply/*; do
    [ -r "$f/online" ] || continue
    online=$(cat "$f/online" 2>/dev/null || echo 0)
    [ "$online" = "1" ] || continue
    source_type=$(cat "$f/type" 2>/dev/null || echo "")
    [ "$source_type" = "Battery" ] && continue
    return 0
  done
  return 1
}

# Estimate remaining time from kernel energy/power counters. The ratio of
# energy_now (uWh) to power_now (uW) is directly in hours.
estimate_time_to_empty() {
  local f energy power current voltage charge total_minutes
  for f in /sys/class/power_supply/BAT*; do
    [ -d "$f" ] || continue
    if [ ! -r "$f/energy_now" ] && { [ ! -r "$f/charge_now" ] || [ ! -r "$f/voltage_now" ]; }; then
      continue
    fi
    energy=0
    if [ -r "$f/energy_now" ]; then
      energy=$(cat "$f/energy_now" 2>/dev/null || echo 0)
    fi
    power=0
    if [ -r "$f/power_now" ]; then
      power=$(cat "$f/power_now" 2>/dev/null || echo 0)
    fi
    if ! [[ "$power" =~ ^[0-9]+$ ]] || [ "$power" -le 0 ]; then
      if [ -r "$f/current_now" ] && [ -r "$f/voltage_now" ]; then
        current=$(cat "$f/current_now" 2>/dev/null || echo 0)
        voltage=$(cat "$f/voltage_now" 2>/dev/null || echo 0)
        power=$(awk -v c="$current" -v v="$voltage" 'BEGIN { printf "%.0f", (c*v)/1000000 }')
      fi
    fi
    # Some batteries expose charge rather than energy.
    if { ! [[ "$energy" =~ ^[0-9]+$ ]] || [ "$energy" -le 0 ]; } && \
       [ -r "$f/charge_now" ] && [ -r "$f/voltage_now" ]; then
      charge=$(cat "$f/charge_now" 2>/dev/null || echo 0)
      voltage=$(cat "$f/voltage_now" 2>/dev/null || echo 0)
      energy=$(awk -v c="$charge" -v v="$voltage" 'BEGIN { printf "%.0f", (c*v)/1000000 }')
    fi
    if [[ "$energy" =~ ^[0-9]+$ ]] && [[ "$power" =~ ^[0-9]+$ ]] && \
       [ "$energy" -gt 0 ] && [ "$power" -gt 0 ]; then
      total_minutes=$(awk -v e="$energy" -v p="$power" 'BEGIN { printf "%d", (e/p*60)+0.5 }')
      format_duration_minutes "$total_minutes"
      return
    fi
  done
}

case "${1:-}" in
  idle)
    if pgrep -x hypridle >/dev/null 2>&1; then
      printf ' 󰾪 '
    else
      printf ' 󰅶 '
    fi
    ;;

  toggle-idle)
    # Avoid shell precedence/backgrounding issues in the old inline command.
    if pgrep -x hypridle >/dev/null 2>&1; then
      pkill -TERM -x hypridle >/dev/null 2>&1 || true
    else
      nohup hypridle >/dev/null 2>&1 </dev/null &
    fi
    ;;

  cpu)
    read_cpu() {
      read -r _ user nice system idle iowait irq softirq steal _ _ < /proc/stat
      local total=$((user + nice + system + idle + iowait + irq + softirq + steal))
      local idle_total=$((idle + iowait))
      printf '%s %s\n' "$total" "$idle_total"
    }
    read -r total1 idle1 < <(read_cpu)
    sleep 0.15
    read -r total2 idle2 < <(read_cpu)
    dt=$((total2 - total1))
    di=$((idle2 - idle1))
    if (( dt > 0 )); then
      awk -v dt="$dt" -v di="$di" 'BEGIN { p=(dt-di)*100/dt; if(p<0)p=0; if(p>100)p=100; printf "%d", p+0.5 }'
    else
      printf '0'
    fi
    ;;

  memory)
    awk '/^MemTotal:/ {t=$2} /^MemAvailable:/ {a=$2} END {if(t>0) printf "%d", ((t-a)*100/t)+0.5; else print 0}' /proc/meminfo
    ;;

  window)
    hyprctl activewindow -j 2>/dev/null | jq -r '.class // ""' 2>/dev/null || true
    ;;

  occupied)
    # Read occupancy from client records rather than relying on the optional
    # windows-count field in hyprctl workspaces output.
    hyprctl clients -j 2>/dev/null | jq -r '[.[] | select((.workspace.id // 0) > 0) | .workspace.id | tostring] | unique | join(",")' 2>/dev/null || true
    ;;

  active-workspaces)
    # Include the active workspace on every monitor, not just the focused one.
    hyprctl monitors -j 2>/dev/null | jq -r '[.[] | (.activeWorkspace.id // empty) | select(. > 0)] | unique | join(",")' 2>/dev/null || true
    ;;

  language)
    # Read the active layout from Hyprland. Some builds omit active_keymap in
    # JSON, so fall back to the text output from `hyprctl devices`.
    devices_json=$(hyprctl devices -j 2>/dev/null || printf '{}')
    keymap=$(printf '%s' "$devices_json" | jq -r '
      ([.keyboards[]? | select(.main == true) | .active_keymap? | select(type == "string" and length > 0)][0]) //
      ([.keyboards[]? | .active_keymap? | select(type == "string" and length > 0)][0]) // empty
    ' 2>/dev/null | head -n1)

    if [ -z "$keymap" ]; then
      keymap=$(hyprctl devices 2>/dev/null | awk '
        /Keyboard at / { current=0 }
        /main: yes/ { current=1 }
        /active keymap:/ {
          line=$0
          sub(/^.*active keymap:[[:space:]]*/, "", line)
          if (current) { print line; found=1; exit }
          if (fallback == "") fallback=line
        }
        END { if (!found && fallback != "") print fallback }
      ' | head -n1)
    fi

    keymap=$(printf '%s' "$keymap" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    lower=$(printf '%s' "$keymap" | tr '[:upper:]' '[:lower:]')
    short=''
    case "$lower" in
      *ukrainian*|*ukrain*) short='ua' ;;
      *russian*) short='ru' ;;
      *english*uk*|*british*|*united\ kingdom*|*uk\ english*) short='gb' ;;
      *english*us*|*united\ states*|*american*|*us\ english*) short='us' ;;
      *english*) short='us' ;;
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
        # Preserve a two-letter code in parentheses, e.g. English (US).
        code=$(printf '%s' "$keymap" | sed -nE 's/.*\(([A-Za-z]{2})\).*/\1/p' | head -n1)
        if [ -n "$code" ]; then short=$(printf '%s' "$code" | tr '[:upper:]' '[:lower:]'); fi
        [ -n "$short" ] || short='??'
        ;;
    esac
    printf '%s|%s\n' "$short" "${keymap:-Keyboard layout unavailable}"
    ;;

  volume)
    wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '
      $1 == "Volume:" { seen=1; v=$2*100; icon=(v<33 ? "" : (v<66 ? "" : "")); state="normal"; for(i=3;i<=NF;i++) if($i=="[MUTED]") state="muted" }
      END { if(!seen || state=="muted") printf "0|muted|"; else printf "%.0f|normal|%s", v, icon }
    '
    ;;

  battery)
    device=$(upower -e 2>/dev/null | grep -m1 -E '/battery_' || true)
    if [ -n "$device" ]; then
      battery_data=$(upower -i "$device" 2>/dev/null | awk -F: '
        /^[[:space:]]*state:/ {
          v=$2; gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); state=tolower(v)
        }
        /^[[:space:]]*percentage:/ {
          v=$2; gsub(/[%[:space:]]/, "", v); pct=v
        }
        /^[[:space:]]*time to empty:/ {
          v=$0; sub(/^[^:]*:[[:space:]]*/, "", v); empty=v
        }
        /^[[:space:]]*time to full:/ {
          v=$0; sub(/^[^:]*:[[:space:]]*/, "", v); full=v
        }
        END {
          if (pct == "") pct=0
          if (state == "fully-charged") state="full"
          if (state == "") state="unknown"
          remaining=(state == "discharging" ? empty : (state == "charging" ? full : ""))
          printf "%s|%s|%s", pct, state, remaining
        }
      ')
      IFS='|' read -r pct state remaining <<< "$battery_data"
      if [ "$state" = "discharging" ]; then
        # Prefer live kernel counters because they preserve minute-level detail;
        # fall back to the UPower estimate when the counters are unavailable.
        estimated=$(estimate_time_to_empty || true)
        if [ -n "$estimated" ]; then
          remaining="$estimated"
        else
          remaining=$(humanize_duration "${remaining:-}")
        fi
      fi
      if { [ "$state" = "full" ] || [ "$state" = "pending-charge" ]; } && ac_connected; then
        state="plugged"
      fi
      printf '%s|%s|%s\n' "${pct:-0}" "${state:-unknown}" "${remaining:-}"
    else
      found=0
      for f in /sys/class/power_supply/BAT*; do
        [ -r "$f/capacity" ] || continue
        pct=$(cat "$f/capacity" 2>/dev/null || echo 0)
        state=$(cat "$f/status" 2>/dev/null | tr '[:upper:]' '[:lower:]')
        remaining=''
        if [ "$state" = "discharging" ]; then remaining=$(estimate_time_to_empty || true); fi
        if [ "$state" = "full" ] && ac_connected; then state="plugged"; fi
        printf '%s|%s|%s\n' "$pct" "${state:-unknown}" "${remaining:-}"
        found=1
        break
      done
      [ "$found" -eq 1 ] || printf '0|unknown|\n'
    fi
    ;;

  backlight)
    f=/sys/class/backlight/intel_backlight
    if [ -r "$f/brightness" ] && [ -r "$f/max_brightness" ]; then
      current=$(cat "$f/brightness")
      maximum=$(cat "$f/max_brightness")
      if [ "$maximum" -gt 0 ]; then
        awk -v c="$current" -v m="$maximum" 'BEGIN { printf "%d", (c*100/m)+0.5 }'
      else printf '0'; fi
    else
      printf '0'
    fi
    ;;

  *)
    echo "Unknown status key: ${1:-}" >&2
    exit 2
    ;;
esac
