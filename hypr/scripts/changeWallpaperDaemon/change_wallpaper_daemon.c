#include <assert.h>
#include <errno.h>
#include <poll.h>
#include <signal.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/un.h>
#include <syslog.h>
#include <time.h>
#include <unistd.h>

#define NOB_IMPLEMENTATION
#define NOB_STRIP_PREFIX
#include "nob.h"

#define MAX_PATH 256
#define MAX_OUTPUTS 10
#define MAX_COMMAND 512

// Dynamic array macros

struct string_array {
  char **items;
  size_t count;
  size_t capacity;
};

// Función para seleccionar un archivo aleatorio
// Devuelve weak-reference (not owning)
char *get_random_wallpaper(char **files, int file_count) {
  if (file_count == 0)
    return NULL;
  int idx = rand() % file_count;

  return files[idx];
}

#ifndef COUNT_MONITORS_COMMAND
#define COUNT_MONITORS_COMMAND "hyprctl monitors -j | jq -r '.[] | .name'"
// #define COUNT_MONITORS_COMMAND "swaymsg -t get_outputs | jq -r '.[] | .name'"
#endif

#ifndef FIND_WALLPAPERS_COMMAND
#define FIND_WALLPAPERS_COMMAND                                                \
  "find %s -maxdepth 5 -type f \\( -iname '*.jpg' -o -iname '*.png' \\)"
// .name'"
#endif

int get_lines_from_commands(char *command, struct string_array *outputs) {
  FILE *fp = popen(command, "r");
  if (!fp) {
    syslog(LOG_ERR, "Error: No se pudo ejecutar el comando %s", command);
    return 0;
  }

  char line[MAX_COMMAND];
  while (fgets(line, sizeof(line), fp)) {
    line[strcspn(line, "\n")] = 0; // Elimina el salto de línea
    da_append(outputs, strdup(line));
  }
  pclose(fp);
  return outputs->count;
}
const char *wallpaper_dir = NULL;

int change_wallpaper(struct string_array outputs,
                     struct string_array wallpapers) {
  system("pkill swaybg 2>/dev/null");

  struct string_array selected_wallpapers = {0};

  for (size_t i = 0; i < outputs.count; i++) {
    char *path;
    path = get_random_wallpaper(wallpapers.items, wallpapers.count);
    da_append(&selected_wallpapers, path);
  }
  String_Builder command = {0};
  sb_append_cstr(&command, "swaybg ");

  for (size_t i = 0; i < outputs.count; i++) {

    sb_appendf(&command, "-o %s -i '%s' -m fill ", outputs.items[i],
               selected_wallpapers.items[i]);
  }
  sb_append_cstr(&command, " &");
  sb_append_null(&command);
  system(command.items);
  sb_free(command);
  command = (String_Builder){0};
  sb_append_cstr(&command,
                 "notify-send --app-name 'WALLPAPER CHANGER' --transient "
                 "'Fondo cambiado en");
  sb_appendf(&command, "%ld monitor%s' ", outputs.count,
             outputs.count > 1 ? "es" : "");
  sb_append_null(&command);
  system(command.items);
  sb_free(command);
  return 0;
}

void daemon_loop() {
  struct string_array outputs = {0};
  struct string_array wallpapers = {0};

  get_lines_from_commands(COUNT_MONITORS_COMMAND, &outputs);

  // Obtiene los archivos de imagen

  char find_command[MAX_COMMAND];
  snprintf(find_command, sizeof(find_command), FIND_WALLPAPERS_COMMAND,
           wallpaper_dir);

  get_lines_from_commands(find_command, &wallpapers);

  // Termina instancias previas de swaybg

  if (outputs.count == 0) {
    syslog(LOG_ERR, "No se detectaron monitores");
  } else if (wallpapers.count == 0) {
    syslog(LOG_ERR, "No se encontraron imágenes en %s", wallpaper_dir);
  } else if (outputs.count >= 1) {
    struct string_array selected_wallpapers = {0};

    for (size_t i = 0; i < outputs.count; i++) {
      char *path;
      path = get_random_wallpaper(wallpapers.items, wallpapers.count);
      da_append(&selected_wallpapers, path);
    }
    change_wallpaper(outputs, wallpapers);
  }
  da_free(outputs);
  da_free(wallpapers);
}

// Función para remover el archivo PID
void remove_pid_file(const char *pid_file_path) {
  if (unlink(pid_file_path) == 0) {
    syslog(LOG_INFO, "Archivo PID removido: %s", pid_file_path);
  } else {
    syslog(LOG_WARNING, "Error removiendo archivo PID %s: %s", pid_file_path,
           strerror(errno));
  }
}

pid_t read_pid_file(const char *pid_file_path) {
  FILE *pid_file = fopen(pid_file_path, "r");
  if (!pid_file) {
    return -1;
  }

  pid_t pid;
  if (fscanf(pid_file, "%d", &pid) != 1) {
    fclose(pid_file);
    return -1;
  }

  fclose(pid_file);
  return pid;
}
#define PID_FILE "/tmp/wallpaper_daemon.pid"
// O alternativamente: #define PID_FILE "/var/run/wallpaper_daemon.pid"

// Función para crear el archivo PID
int create_pid_file(const char *pid_file_path) {
  FILE *pid_file = fopen(pid_file_path, "w");
  if (!pid_file) {
    syslog(LOG_ERR, "Error creando archivo PID %s: %s", pid_file_path,
           strerror(errno));
    return -1;
  }

  pid_t pid = getpid();
  fprintf(pid_file, "%d\n", pid);
  fclose(pid_file);

  syslog(LOG_INFO, "Archivo PID creado: %s con PID %d", pid_file_path, pid);
  return 0;
}

void signal_handler(int sig) {
  if (sig == SIGUSR2) {
    syslog(LOG_INFO, "Señal SIGUSR2 recibida, relanzando wallpapers");
    daemon_loop();
  } else {
    syslog(LOG_WARNING, "Señal no manejada: %d", sig);
  }
}

void cleanup_and_exit(void) {
  remove_pid_file(PID_FILE);
  syslog(LOG_INFO, "Demonio terminado limpiamente");
  closelog();
}
int main(int argc, char *argv[]) {
  // Verifica los argumentos
  NOB_GO_REBUILD_URSELF(argc, argv);
  if (argc != 3) {
    fprintf(stderr, "Uso: %s <carpeta_de_fondos> <intervalo_en_minutos>\n",
            argv[0]);
    return 1;
  }
  signal(SIGUSR2, signal_handler);

  wallpaper_dir = argv[1];
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
  int interval_seconds = interval_minutes * 60 - 10 + 10;

  // Inicia el demonio
  if (daemon(0, 0) == -1) {
    perror("Error al iniciar el demonio");
    return 1;
  }

  // Abre el syslog
  openlog("wallpaper_daemon", LOG_PID | LOG_CONS, LOG_DAEMON);
  syslog(LOG_INFO, "Demonio iniciado con carpeta %s e intervalo %f minutos",
         wallpaper_dir, interval_minutes);

  // Crea el archivo PID
  if (create_pid_file(PID_FILE) != 0) {
    fprintf(stderr, "Error: No se pudo crear el archivo PID\n");
    return 1;
  }

  // Configura la limpieza al salir
  atexit(cleanup_and_exit);
  // Inicializa el generador de números aleatorios
  srand(time(NULL));
  sleep(5);
  // Configurar monitor de eventos

  // Bucle principal
  while (1) {
    // Obtiene las salidas
    daemon_loop();
    sleep(interval_seconds);
  }

  // Cierra el syslog (nunca se alcanza en este bucle infinito)
  closelog();
  return 0;
}
