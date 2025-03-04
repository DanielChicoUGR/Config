#!/usr/bin/env bash

# Función para manejar cambios en el estado de la batería
handle_battery_status_change() {
    while true; do
        status=$(cat /sys/class/power_supply/BAT1/status)
        case "$status" in
        "Charging")
            echo "Cargador conectado" >>/tmp/battery.log
            if [ -f /tmp/swayidle.pid ]; then
                kill $(cat /tmp/swayidle.pid)
                rm /tmp/swayidle.pid
            fi
            # Aquí puedes agregar las acciones que deseas realizar cuando el cargador está conectado
            ;;
        "Discharging")
            echo "Cargador desconectado" >>/tmp/battery.log
            # Aquí puedes agregar las acciones que deseas realizar cuando el cargador está desconectado
            if [ ! -f /tmp/swayidle.pid ]; then
                swayidle -w timeout 600 'systemctl suspend' &
                echo $! >/tmp/swayidle.pid
            fi
            ;;
        "Full")
            echo "Batería completamente cargada" >>/tmp/battery.log
            # Aquí puedes agregar las acciones que deseas realizar cuando la batería está completamente cargada
            ;;
        *)
            echo "Estado de la batería desconocido: $status" >>/tmp/battery.log
            ;;
        esac
        sleep 60s
    done
}

# Llamar a la función para manejar cambios en el estado de la batería
handle_battery_status_change
