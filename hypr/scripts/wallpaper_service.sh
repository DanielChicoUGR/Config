# Verifica que se proporcionen la carpeta de fondos y el intervalo en minutos
if [ "$#" -ne 2 ]; then
    echo "Uso: $0 <carpeta_de_fondos> <intervalo_en_segundos>"
    exit 1
fi

WALLPAPER_DIR="$1"
INTERVAL_SECONDS="$2"

# Verifica que la carpeta exista
if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "Error: La carpeta $WALLPAPER_DIR no existe."
    exit 1
fi

sleep 3

# # Verifica que el intervalo sea un número positivo
# if ! [[ "$INTERVAL_MINUTES" =~ ^[0-9]+([.][0-9]+)?$ ]] || [ "$(echo "$INTERVAL_MINUTES <= 0" | bc)" -eq 1 ]; then
#     echo "Error: El intervalo debe ser un número positivo."
#     exit 1
# fi

# Convierte el intervalo a segundos
# INTERVAL_SECONDS=$(echo "$INTERVAL_MINUTES * 60" | bc)


# Carga las funciones desde el script separado
source "$(dirname "$0")/change_wallpaper_utils.sh"

notify-send --app-name "WALLPAPER CHANGER" --transient "Lanzando gestor de wallpapers" 

echo "Primera llamada a change_wallpaper"
# Llamada inicial para establecer los fondos al inicio
change_wallpaper "$WALLPAPER_DIR"

echo "Entrando al bucle de cambio de fondos cada $INTERVAL_SECONDS segundos..."
# Bucle principal para cambiar los fondos cada X minutos
while true; do
    sleep "$INTERVAL_SECONDS"
    change_wallpaper "$WALLPAPER_DIR"
done
