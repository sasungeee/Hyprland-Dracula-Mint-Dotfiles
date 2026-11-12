#!/bin/bash

pactl load-module module-null-sink \
  sink_name=ReaperOut \
  sink_properties=device.description="Reaper Output" \
  media.class=Audio/Sink \
  object.linger=1

pactl load-module module-null-sink \
  media.class=Audio/Source/Virtual \
  sink_name=ReaperMic \
  sink_properties=device.description="Reaper Virtual Mic" \
  channel_map=front-left,front-right \
  object.linger=1

pw-link "ReaperOut:monitor_FL" "ReaperMic:input_FL"
pw-link "ReaperOut:monitor_FR" "ReaperMic:input_FR"

while true; do
  if pw-link -o | grep -q "REAPER:out" && pw-link -i | grep -q "ReaperOut\|pw Reaper"; then
    pw-link "REAPER:out1" "ReaperOut:playback_FL" 2>/dev/null
    pw-link "REAPER:out2" "ReaperOut:playback_FR" 2>/dev/null
    break
  fi
  sleep 2
done
