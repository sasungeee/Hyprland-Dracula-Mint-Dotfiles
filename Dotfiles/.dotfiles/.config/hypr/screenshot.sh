#!/bin/bash

SCREENSHOT_DIR="$HOME/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

hyprpicker -r -z &
PICKER_PID=$!

sleep 0.15

GEOMETRY=$(slurp)

# Отмена выбора
if [[ -z "$GEOMETRY" ]]; then
    kill "$PICKER_PID" 2>/dev/null
    wait "$PICKER_PID" 2>/dev/null
    exit 0
fi

# Сначала делаем снимок замороженного экрана во временный файл
TEMP_FILE=$(mktemp --suffix=.ppm)

grim -g "$GEOMETRY" -t ppm "$TEMP_FILE"

# Теперь снимаем freeze
kill "$PICKER_PID" 2>/dev/null
wait "$PICKER_PID" 2>/dev/null

# Открываем снимок в полноэкранном Satty
satty \
    --filename "$TEMP_FILE" \
    --fullscreen \
    --output-filename "$SCREENSHOT_DIR/satty-$(date "+%Y%m%d-%H%M%S").png"

rm -f "$TEMP_FILE"
