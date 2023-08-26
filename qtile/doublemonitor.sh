#!/usr/bin/env bash 


# autorandr horizontal-reverse
xrandr --output HDMI-A-0 --left-of eDP
xrandr --output HDMI-A-0 --primary

env LD_PRELOAD=/usr/local/lib/spotify-adblock.so spotify %U &