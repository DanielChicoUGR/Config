#!/usr/bin/env bash

change_wallpeper() {
    local pid=$(cat "/tmp/wallpaper_daemon.pid" 2>/dev/null)
    if [[ -n "$pid" ]] ; then
        kill -SIGUSR2 "$pid" 2>/dev/null
        
    else
        return 1
    fi
}

handle() {
    echo "$1" >> /tmp/hypr.log
  case $1 in
    monitoradded*) change_wallpaper ;;
    monitorremoved*) change_wallpaper ;;
    monitorremovedv2*) change_wallpaper ;;
  esac
}

socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do handle "$line"; done

