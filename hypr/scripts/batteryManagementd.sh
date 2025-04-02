#!/usr/bin/env bash
# filepath: /home/daniel/.repos/Config/hypr/scripts/bateryManagementd.sh

# Archivo para almacenar el PID de swayidle
SWAYIDLE_PID_FILE="/tmp/swayidle.pid"
LOG_FILE="/tmp/idle_manager.log"

# Función para iniciar swayidle con el cargador conectado
start_swayidle_on_ac() {
    echo "$(date): Iniciando swayidle en modo cargador conectado" >> "$LOG_FILE"
    
    swayidle -w \
        timeout 300 'swaylock -f -c 000000' \
        timeout 600 'hyprctl dispatch dpms off' \
        resume 'hyprctl dispatch dpms on' &
    
    echo $! > "$SWAYIDLE_PID_FILE"
    notify-send "Gestor de inactividad" "Modo cargador conectado activo" -i "power-profile-balanced-symbolic"
}

# Función para iniciar swayidle con el cargador desconectado (modo batería)
start_swayidle_on_battery() {
    echo "$(date): Iniciando swayidle en modo batería" >> "$LOG_FILE"
    
    swayidle -w \
        timeout 120 'swaylock -f -c 000000' \
        timeout 180 'hyprctl dispatch dpms off' \
        timeout 300 'systemctl suspend' \
        resume 'hyprctl dispatch dpms on' &
    
    echo $! > "$SWAYIDLE_PID_FILE"
    notify-send "Gestor de inactividad" "Modo batería activo" -i "power-profile-power-saver-symbolic"
}

# Función para detener swayidle
stop_swayidle() {
    if [ -f "$SWAYIDLE_PID_FILE" ]; then
        pid=$(cat "$SWAYIDLE_PID_FILE")
        if ps -p $pid > /dev/null; then
            kill $pid
            echo "$(date): Deteniendo swayidle (PID: $pid)" >> "$LOG_FILE"
        else
            echo "$(date): El proceso swayidle (PID: $pid) ya no existe" >> "$LOG_FILE"
        fi
        rm "$SWAYIDLE_PID_FILE"
    else
        echo "$(date): No se encontró ninguna instancia de swayidle en ejecución" >> "$LOG_FILE"
    fi
}

# Función principal para manejar cambios en el estado de la batería
handle_battery_status_change() {
    local last_status=""
    
    while true; do
        status=$(cat /sys/class/power_supply/BAT1/status)
        
        # Solo actuamos si el estado ha cambiado
        if [ "$status" != "$last_status" ]; then
            echo "$(date): Estado de batería cambiado a: $status" >> "$LOG_FILE"
            last_status="$status"
            
            # Detener la instancia actual de swayidle
            stop_swayidle
            
            # Iniciar nueva instancia según el estado
            case "$status" in
                "Charging"|"Full"|"Not charging")
                    echo "$(date): Cargador conectado" >> "$LOG_FILE"
                    start_swayidle_on_ac
                    ;;
                "Discharging")
                    echo "$(date): Cargador desconectado" >> "$LOG_FILE"
                    start_swayidle_on_battery
                    ;;
                *)
                    echo "$(date): Estado de batería desconocido: $status" >> "$LOG_FILE"
                    # Por defecto, usar configuración de batería por seguridad
                    start_swayidle_on_battery
                    ;;
            esac
        fi
        
        # Verificar cada 10 segundos
        sleep 60
    done
}

# Al iniciar el script, detener cualquier instancia existente de swayidle
stop_swayidle

# Iniciar la gestión de swayidle
handle_battery_status_change


# #!/usr/bin/env bash

# # Función para manejar cambios en el estado de la batería
# handle_battery_status_change() {
#     while true; do
#         status=$(cat /sys/class/power_supply/BAT1/status)
#         case "$status" in
#         "Charging")
#             echo "Cargador conectado" >>/tmp/battery.log
#             if [ -f /tmp/swayidle.pid ]; then
#                 kill $(cat /tmp/swayidle.pid)
#                 rm /tmp/swayidle.pid
#             fi
#             # Aquí puedes agregar las acciones que deseas realizar cuando el cargador está conectado
#             ;;
#         "Discharging")
#             echo "Cargador desconectado" >>/tmp/battery.log
#             # Aquí puedes agregar las acciones que deseas realizar cuando el cargador está desconectado
#             if [ ! -f /tmp/swayidle.pid ]; then
#                 swayidle -w timeout 600 'systemctl suspend' &
#                 echo $! >/tmp/swayidle.pid
#             fi
#             ;;
#         "Full")
#             echo "Batería completamente cargada" >>/tmp/battery.log
#             # Aquí puedes agregar las acciones que deseas realizar cuando la batería está completamente cargada
#             ;;
#         *)
#             echo "Estado de la batería desconocido: $status" >>/tmp/battery.log
#             ;;
#         esac
#         sleep 60s
#     done
# }

# # Llamar a la función para manejar cambios en el estado de la batería
# handle_battery_status_change
