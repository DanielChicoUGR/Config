#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <dirent.h>
#include <time.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <syslog.h>
#include <libgen.h>

#define MAX_PATH 256
#define MAX_OUTPUTS 10
#define MAX_COMMAND 512

// Función para obtener archivos de imagen (.jpg, .png) de un directorio
int get_image_files(const char *dir, char **files, int max_files) {
    DIR *dp;
    struct dirent *entry;
    int count = 0;

    dp = opendir(dir);
    if (!dp) {
        syslog(LOG_ERR, "Error: No se pudo abrir el directorio %s", dir);
        return 0;
    }

    while ((entry = readdir(dp)) && count < max_files) {
        char *ext = strrchr(entry->d_name, '.');
        if (ext && (strcmp(ext, ".jpg") == 0 || strcmp(ext, ".png") == 0)) {
            files[count] = strdup(entry->d_name);
            count++;
        }
    }
    closedir(dp);
    return count;
}

// Función para seleccionar un archivo aleatorio
char *get_random_wallpaper(const char *dir, char **files, int file_count) {
    if (file_count == 0) return NULL;
    int idx = rand() % file_count;
    char *path = malloc(MAX_PATH);
    snprintf(path, MAX_PATH, "%s/%s", dir, files[idx]);
    return path;
}

// Función para obtener las salidas (monitores) usando swaymsg
int get_outputs(char **outputs, int max_outputs) {
    FILE *fp = popen("swaymsg -t get_outputs | jq -r '.[] | .name'", "r");
    if (!fp) {
        syslog(LOG_ERR, "Error: No se pudo ejecutar swaymsg");
        return 0;
    }

    int count = 0;
    char line[128];
    while (fgets(line, sizeof(line), fp) && count < max_outputs) {
        line[strcspn(line, "\n")] = 0; // Elimina el salto de línea
        outputs[count] = strdup(line);
        count++;
    }
    pclose(fp);
    return count;
}

int main(int argc, char *argv[]) {
    // Verifica los argumentos
    if (argc != 3) {
        fprintf(stderr, "Uso: %s <carpeta_de_fondos> <intervalo_en_minutos>\n", argv[0]);
        return 1;
    }

    const char *wallpaper_dir = argv[1];
    float interval_minutes;
    if (sscanf(argv[2], "%f", &interval_minutes) != 1 || interval_minutes <= 0) {
        fprintf(stderr, "Error: El intervalo debe ser un número positivo\n");
        return 1;
    }

    // Verifica que el directorio exista
    struct stat st;
    if (stat(wallpaper_dir, &st) != 0 || !S_ISDIR(st.st_mode)) {
        fprintf(stderr, "Error: La carpeta %s no existe\n", wallpaper_dir);
        return 1;
    }

    // Convierte el intervalo a segundos
    int interval_seconds = (int)(interval_minutes * 60);

    // Inicia el demonio
    if (daemon(0, 0) == -1) {
        perror("Error al iniciar el demonio");
        return 1;
    }

    // Abre el syslog
    openlog("wallpaper_daemon", LOG_PID | LOG_CONS, LOG_DAEMON);
    syslog(LOG_INFO, "Demonio iniciado con carpeta %s e intervalo %f minutos", wallpaper_dir, interval_minutes);

    // Inicializa el generador de números aleatorios
    srand(time(NULL));

    // Bucle principal
    while (1) {
        // Obtiene las salidas
        char *outputs[MAX_OUTPUTS];
        for (int i = 0; i < MAX_OUTPUTS; i++) outputs[i] = NULL;
        int output_count = get_outputs(outputs, MAX_OUTPUTS);

        // Obtiene los archivos de imagen
        char *files[1024];
        for (int i = 0; i < 1024; i++) files[i] = NULL;
        int file_count = get_image_files(wallpaper_dir, files, 1024);

        // Termina instancias previas de swaybg
        system("pkill swaybg 2>/dev/null");

        if (output_count == 0) {
            syslog(LOG_ERR, "No se detectaron monitores");
        } else if (file_count == 0) {
            syslog(LOG_ERR, "No se encontraron imágenes en %s", wallpaper_dir);
        } else if (output_count == 1) {
            // Un monitor: selecciona un fondo aleatorio
            char *wallpaper = get_random_wallpaper(wallpaper_dir, files, file_count);
            if (wallpaper) {
                char command[MAX_COMMAND];
                snprintf(command, MAX_COMMAND, "swaybg -o %s -i '%s' -m fill &", outputs[0], wallpaper);
                system(command);
                syslog(LOG_INFO, "Un monitor detectado. Fondo aplicado en %s: %s", outputs[0], wallpaper);
                free(wallpaper);
            }
        } else if (output_count >= 2) {
            // Dos o más monitores: selecciona dos fondos distintos
            char *wallpaper1 = get_random_wallpaper(wallpaper_dir, files, file_count);
            char *wallpaper2 = get_random_wallpaper(wallpaper_dir, files, file_count);
            while (wallpaper2 && wallpaper1 && strcmp(wallpaper1, wallpaper2) == 0) {
                free(wallpaper2);
                wallpaper2 = get_random_wallpaper(wallpaper_dir, files, file_count);
            }
            if (wallpaper1 && wallpaper2) {
                char command[MAX_COMMAND];
                snprintf(command, MAX_COMMAND, "swaybg -o %s -i '%s' -m fill &", outputs[0], wallpaper1);
                system(command);
                snprintf(command, MAX_COMMAND, "swaybg -o %s -i '%s' -m fill &", outputs[1], wallpaper2);
                system(command);
                syslog(LOG_INFO, "Dos monitores detectados. Fondos aplicados: %s -> %s, %s -> %s",
                       outputs[0], wallpaper1, outputs[1], wallpaper2);
            }
            free(wallpaper1);
            free(wallpaper2);
        }

        // Libera memoria
        for (int i = 0; i < output_count; i++) free(outputs[i]);
        for (int i = 0; i < file_count; i++) free(files[i]);

        // Espera el intervalo
        sleep(interval_seconds);
    }

    // Cierra el syslog (nunca se alcanza en este bucle infinito)
    closelog();
    return 0;
}
