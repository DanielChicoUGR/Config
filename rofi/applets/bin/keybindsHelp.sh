#!/bin/bash

source "$HOME"/.config/rofi/applets/shared/theme.bash
theme="$type/$style"

hyprctl binds -j |
  jq -r '
    map({mod:.modmask|tostring,key:.key,code:.keycode|tostring,desc:.description,dp:.dispatcher,arg:.arg,sub:.submap}) |
    map(.mod |= {"0":"","1":"SHIFT+","4":"CTRL+","5":"SHIFT+CTRL+","64":"SUPER+","65":"SUPER+SHIFT+","68":"SUPER+CTRL+","8":"ALT+"} [.]) |
    map(.code |= {"59":"Comma","60":"Dot"} [.]) |
    sort_by(.mod) | .[] |
    select(.sub == "") |
    "<b>\(.mod)\(if .key == "" then .code else .key end)</b> <i>\(.desc)</i> <span color=\"cyan\">\(.dp) \(.arg)</span>" ' |
  rofi -dmenu -markup-rows -i -p 'Hypr binds' |
  sed -n 's/.*<span color=\"cyan\">\(.*\)<\/span>.*/\1/p' |
  sed -e 's/^/"/g' -e 's/$/"/g' |
  xargs -n1 hyprctl dispatch
