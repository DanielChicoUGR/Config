#!/usr/bin/env bash

## Author  : Aditya Shakya (adi1090x)
## Github  : @adi1090x
#
## Applets : Playerctl (music)

# Import Current Theme
source "$HOME"/.config/rofi/applets/shared/theme.bash
theme="$type/$style"

# Theme Elements
status="`playerctl status`"
if [[ -z "$status" ]]; then
	prompt='Offline'
	mesg="Player is Offline"
else
	prompt="`playerctl metadata artist`"
	mesg="`playerctl metadata title` :: `playerctl status`"
fi

if [[ ( "$theme" == *'type-1'* ) || ( "$theme" == *'type-3'* ) || ( "$theme" == *'type-5'* ) ]]; then
	list_col='1'
	list_row='6'
elif [[ ( "$theme" == *'type-2'* ) || ( "$theme" == *'type-4'* ) ]]; then
	list_col='6'
	list_row='1'
fi

# Options
layout=`cat ${theme} | grep 'USE_ICON' | cut -d'=' -f2`
if [[ "$layout" == 'NO' ]]; then
	if [[ ${status} == "Playing" ]]; then
		option_1=" Pause"
	else
		option_1=" Play"
	fi
	option_2=" Stop"
	option_3=" Previous"
	option_4=" Next"
	option_5=" Loop"
	option_6=" Shuffle"
else
	if [[ ${status} == "Playing" ]]; then
		option_1=""
	else
		option_1=""
	fi
	option_2=""
	option_3=""
	option_4=""
	option_5=""
	option_6=""
fi

# Toggle Actions
active=''
urgent=''
# Loop
loop_status="`playerctl loop`"
if [[ ${loop_status} == "None" ]]; then
    urgent="-u 4"
elif [[ ${loop_status} == "Track" || ${loop_status} == "Playlist" ]]; then
    active="-a 4"
else
    option_5=" Parsing Error"
fi
# Shuffle
shuffle_status="`playerctl shuffle`"
if [[ ${shuffle_status} == "On" ]]; then
    [ -n "$active" ] && active+=",5" || active="-a 5"
elif [[ ${shuffle_status} == "Off" ]]; then
    [ -n "$urgent" ] && urgent+=",5" || urgent="-u 5"
else
    option_6=" Parsing Error"
fi

# Rofi CMD
rofi_cmd() {
	rofi -theme-str "listview {columns: $list_col; lines: $list_row;}" \
		-theme-str 'textbox-prompt-colon {str: "";}' \
		-dmenu \
		-p "$prompt" \
		-mesg "$mesg" \
		${active} ${urgent} \
		-markup-rows \
		-theme ${theme}
}

# Pass variables to rofi dmenu
run_rofi() {
	echo -e "$option_1\n$option_2\n$option_3\n$option_4\n$option_5\n$option_6" | rofi_cmd
}

# Execute Command
run_cmd() {
	if [[ "$1" == '--opt1' ]]; then
		playerctl play-pause && notify-send -u low -t 1000 " `playerctl metadata title`"
	elif [[ "$1" == '--opt2' ]]; then
		playerctl stop
	elif [[ "$1" == '--opt3' ]]; then
		playerctl previous && notify-send -u low -t 1000 " `playerctl metadata title`"
	elif [[ "$1" == '--opt4' ]]; then
		playerctl next && notify-send -u low -t 1000 " `playerctl metadata title`"
	elif [[ "$1" == '--opt5' ]]; then
		playerctl loop && notify-send -u low -t 1000 " Loop toggled"
	elif [[ "$1" == '--opt6' ]]; then
		playerctl shuffle && notify-send -u low -t 1000 " Shuffle toggled"
	fi
}

# Actions
chosen="$(run_rofi)"
case ${chosen} in
    $option_1)
		run_cmd --opt1
        ;;
    $option_2)
		run_cmd --opt2
        ;;
    $option_3)
		run_cmd --opt3
        ;;
    $option_4)
		run_cmd --opt4
        ;;
    $option_5)
		run_cmd --opt5
        ;;
    $option_6)
		run_cmd --opt6
        ;;
esac
