#!/usr/bin/env bash

declare -i last_shot=0

change_wallpaper() {
    new_shot=$(date +%s)
    elapsed_time=$(( $new_shot - $last_shot ))
    echo "New shot at $new_shot, last shot at $last_shot, elapsed time: $elapsed_time seconds" 

    if [[ $(last_shot) -gt 0 ]] && [[ $(($new_shot - $last_shot)) -lt 5 ]] ; then
        echo "Ignoring wallpaper change request due to rapid succession." 
        return 0
    fi
    last_shot=$new_shot
    local pid=$(cat "/tmp/wallpaper_daemon.pid" 2>/dev/null)
    echo "Changing wallpaper due to monitor change event..."
    if [[ -n "$pid" ]] ; then
        kill -s SIGUSR2 "$pid" 2>/dev/null
        
    else
        return 1
    fi
}

export change_wallpeper

handle() {
    # echo "$1" >> /tmp/hypr.log
  case $1 in
    "monitoradded>>*") change_wallpaper ;;
    "monitorremoved>>*") change_wallpaper ;;
  esac
}

socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do handle "$line"; done

