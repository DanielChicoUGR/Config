#!/bin/bash

# Ruta a los scripts que se deben ejecutar
SCRIPT_ONE_MONITOR="glava --desktop -e rc_monit1.glsl"
SCRIPT_MULTIPLE_MONITORS="glava --desktop -e rc_monit2.glsl"

# Función para contar monitores conectados
count_monitors() {
    xrandr --listmonitors | grep -c ": +"
}

# Variables para almacenar el estado actual
current_monitor_count=$(count_monitors)
current_pid=""

# Función para iniciar el script adecuado
start_script() {
    local monitor_count=$1
    if [ "$monitor_count" -eq 1 ]; then
        $SCRIPT_ONE_MONITOR &
        current_pid=$!
    else
        $SCRIPT_MULTIPLE_MONITORS &
        current_pid=$!
    fi
}

# Iniciar el script adecuado al inicio
start_script $current_monitor_count

# Bucle infinito para monitorear cambios
while true; do
    new_monitor_count=$(count_monitors)
    if [ "$new_monitor_count" -ne "$current_monitor_count" ]; then
        # Matar el script actual
        if [ -n "$current_pid" ]; then
            kill $current_pid
        fi
        # Actualizar el conteo de monitores y reiniciar el script adecuado
        current_monitor_count=$new_monitor_count
        start_script $current_monitor_count
    fi
    # Esperar un tiempo antes de volver a verificar
    sleep 5
done