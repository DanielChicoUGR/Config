

LOG_FILE="/tmp/wallpaper.log"
WALLPAPER_DIR="$HOME/.config/variety/Downloaded/"

# Función para seleccionar un archivo de imagen aleatorio de una carpeta
get_random_wallpaper() {
    local dir="$1"
    # echo "Buscando imágenes en $dir..."
    local wp=$(find "$dir" -maxdepth 3 -type f \( -iname "*.jpg" -o -iname "*.png" \) )
    
    # echo "Imágenes encontradas en $dir: ${wp[@]}"
    # echo "${wp[@]}"

    wp=$(echo "$wp" | shuf -n 1)
    # echo "Imagen seleccionada: $wp"
    # Si no se encuentra ninguna imagen, devuelve una cadena vacía
    
        echo "$wp"

}

# Función para cambiar los fondos de pantalla según el número de monitores
change_wallpaper() {
    local wallpaper_dir="$WALLPAPER_DIR"
    local OUTPUTS
    # OUTPUTS=($(swaymsg -t get_outputs | jq -r '.[] | .name'))
    OUTPUTS=($(hyprctl monitors -j | jq -r '.[] | .name'))
    local WALLPAPER
    # local WALLPAPER1
    local WALLPAPER2


    # Termina cualquier instancia previa de swaybg
    pkill swaybg 2>/dev/null

    # Verifica el número de monitores
    if [ ${#OUTPUTS[@]} -eq 1 ]; then
        # Solo un monitor: selecciona un fondo aleatorio
        WALLPAPER=$(get_random_wallpaper "$wallpaper_dir")
        if [ -n "$WALLPAPER" ]; then
            swaybg -o "${OUTPUTS[0]}" -i "$WALLPAPER" -m fill &
            echo "Un monitor detectado. Fondo aplicado en ${OUTPUTS[0]}: $WALLPAPER" >> "$LOG_FILE"
            notify-send --app-name "WALLPAPER CHANGER" --transient "Fondo cambiado en ${OUTPUTS[0]}" -i "$WALLPAPER"
        else
            echo "Error: No se encontraron imágenes en $wallpaper_dir" >> "$LOG_FILE"
        fi
    elif [ ${#OUTPUTS[@]} -ge 2 ]; then
        # Dos o más monitores: selecciona dos fondos aleatorios distintos
        WALLPAPER=$(get_random_wallpaper "$wallpaper_dir")
        WALLPAPER2=$(get_random_wallpaper "$wallpaper_dir")
        # Asegura que los fondos sean diferentes
        while [ "$WALLPAPER" = "$WALLPAPER2" ] && [ -n "$WALLPAPER2" ]; do
            WALLPAPER2=$(get_random_wallpaper "$wallpaper_dir")
        done
        if [ -n "$WALLPAPER" ] && [ -n "$WALLPAPER2" ]; then
            swaybg -o "${OUTPUTS[0]}" -i "$WALLPAPER" -m fill &
            notify-send --app-name "WALLPAPER CHANGER" --transient "Fondo cambiado en ${OUTPUTS[0]}" -i "$WALLPAPER"
            swaybg -o "${OUTPUTS[1]}" -i "$WALLPAPER2" -m fill &
            notify-send --app-name "WALLPAPER CHANGER" --transient "Fondo cambiado en ${OUTPUTS[1]}" -i "$WALLPAPER2"
            echo "Dos monitores detectados. Fondos aplicados: ${OUTPUTS[0]}: $WALLPAPER1, ${OUTPUTS[1]}: $WALLPAPER2" >> "$LOG_FILE"
        else
            echo "Error: No se encontraron suficientes imágenes en $wallpaper_dir" >> "$LOG_FILE"
        fi
    else
        echo "Error: No se detectaron monitores." >> "$LOG_FILE"
    fi
}