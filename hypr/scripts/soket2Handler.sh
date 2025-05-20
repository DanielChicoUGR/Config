#!/usr/bin/env bash

# Carga las funciones de gestion de wallpapers
source "$(dirname "$0")/change_wallpaper_utils.sh"


handle() {
    echo "$1" >> /tmp/hypr.log
  case $1 in
    monitoradded*) change_wallpaper ;;
    monitorremoved*) change_wallpaper ;;
    monitorremovedv2*) change_wallpaper ;;
  esac
}

socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do handle "$line"; done