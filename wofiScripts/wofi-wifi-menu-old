#!/usr/bin/env bash

# Scripts looks at the config and style files at $HOME/.config/wofi
CONFIG="${WOFI_CONFIG:-$HOME/.config/wofi/config}"
STYLE="${WOFI_STYLE:-$HOME/.config/wofi/style.css}"
LOCK_FILE="/tmp/wofi_wifi.lock"

# Function to map signal strength to bars
wifi_signal_bar() {
    local SIGNAL=$1
    if (( SIGNAL >= 75 )); then echo "󰤨";  # Strongest
    elif (( SIGNAL >= 50 )); then echo "󰤢";  # Good
    elif (( SIGNAL >= 25 )); then echo "󰤟";  # Weak
    else echo "󰤯";  # Very Weak
    fi
}

# Start Wi-Fi scan in the background
nmcli d wifi rescan &>/dev/null &

# Get current connection
CURRENT_SSID=$(nmcli -t -f ACTIVE,SSID device wifi list | awk -F: '$1=="yes" {print $2}')
CURRENT_SIGNAL=$(nmcli -t -f ACTIVE,SSID,SIGNAL device wifi list | awk -F: '$1=="yes" {print $3}')

# Get saved networks
SAVED_NETWORKS=$(nmcli -t -f NAME connection show)

# Temporary files for sorting networks
SAVED_CONNECTED_LIST=$(mktemp)
SAVED_LIST=$(mktemp)
NEW_LIST=$(mktemp)

# Process Wi-Fi networks
nmcli -t -f SSID,SECURITY,SIGNAL device wifi list | while IFS=: read -r SSID SECURITY SIGNAL; do
    [[ -z "$SSID" ]] && continue  # Skip empty SSIDs

    # Determine if network is saved
    if echo "$SAVED_NETWORKS" | grep -Fxq "$SSID"; then
        SAVED="✔"  # Saved network
    else
        SAVED="✖"  # New network
    fi

    # Security icon
    SEC_ICON="🔒"
    [[ "$SECURITY" == "--" ]] && SEC_ICON="🔓"

    # Signal strength bar
    SIGNAL_BAR=$(wifi_signal_bar "$SIGNAL")

    # Highlight active connection
    if [[ "$SSID" == "$CURRENT_SSID" ]]; then
        STATUS="🟢"  # Currently connected
        printf "%s  %s  %s  %s  %s\n" "$STATUS" "$SAVED" "$SSID" "$SEC_ICON" "$SIGNAL_BAR" >> "$SAVED_CONNECTED_LIST"
    elif [[ "$SAVED" == "✔" ]]; then
        STATUS="⚪"
        printf "%s  %s  %s  %s  %s\n" "$STATUS" "$SAVED" "$SSID" "$SEC_ICON" "$SIGNAL_BAR" >> "$SAVED_LIST"
    else
        STATUS="⚪"
        printf "%s  %s  %s  %s  %s\n" "$STATUS" "$SAVED" "$SSID" "$SEC_ICON" "$SIGNAL_BAR" >> "$NEW_LIST"
    fi
done

# Sort saved and new networks by signal strength (best first)
sort -r -k5 "$SAVED_CONNECTED_LIST" -o "$SAVED_CONNECTED_LIST"
sort -r -k5 "$SAVED_LIST" -o "$SAVED_LIST"
sort -r -k5 "$NEW_LIST" -o "$NEW_LIST"

# Combine lists: Connected & Saved -> Saved -> New Networks
WIFI_LIST=$(cat "$SAVED_CONNECTED_LIST" "$SAVED_LIST" "$NEW_LIST")

# Cleanup temp files
rm -f "$SAVED_CONNECTED_LIST" "$SAVED_LIST" "$NEW_LIST"

# Display menu
CHENTRY=$(echo -e "$WIFI_LIST" | uniq -u | wofi -d --conf "${CONFIG}" --style "${STYLE}" --prompt "Select Wi-Fi Network")

# Extract SSID
CHSSID=$(echo "$CHENTRY" | awk '{print $3}')

# Handle empty selection
if [[ -z "$CHENTRY" ]]; then
    exit
elif [[ "$CHSSID" == "(hidden)" ]]; then
    CHSSID=$(wofi -d --conf "${CONFIG}" --style "${STYLE}" -p "Enter Hidden SSID")
    [[ -z "$CHSSID" ]] && notify-send 'Wi-Fi' 'No SSID entered, cancelling.' && exit
fi

# Connect to the selected network
if echo "$SAVED_NETWORKS" | grep -Fxq "$CHSSID"; then
    notify-send "Wi-Fi" "Connecting to $CHSSID..."
    nmcli con up "$CHSSID"
else
    WIFIPASS=$(wofi -d --conf "${CONFIG}" --style "${STYLE}" -p "Enter Wi-Fi Password" --no-clear )
    [[ -z "$WIFIPASS" ]] && notify-send 'Wi-Fi' 'No password entered, cancelling.' && exit
    echo "$WIFIPASS" | nmcli device wifi connect "$CHSSID" password-file -
fi
