#include <poll.h>
#include <sys/socket.h>
#include <sys/syslog.h>
#include <sys/un.h>
#include <syslog.h>

#define NOBDEF static inline
#define NOB_STRIP_PREFIX
#include "nob.h"

#define MAX_PATH 256
#define MAX_OUTPUTS 10
#define MAX_COMMAND 512

float interval_minutes = -1.0f; // Intervalo en minutos
const char *wallpaper_dir = NULL;
static int g_hypr_fd = -1; // FD del socket de eventos de Hyprland

Nob_Procs g_procs = {0};

// Dynamic array macros

struct string_array {
  char **items;
  size_t count;
  size_t capacity;
};

typedef enum {
  WAIT_TIMEOUT = 0,
  WAIT_READY = 1,
  WAIT_CLOSED = -2,
  WAIT_ERROR = -3
} wait_result;

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

int change_wallpaper(void) {
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

    system("pkill swaybg 2>/dev/null");
    usleep(1); // Espera un segundo para asegurarse que swaybg haya
               // terminado
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
    // Volvemos a colocar todos los elementos del struct a 0
    command = (String_Builder){0};

    sb_append_cstr(&command,
                   "notify-send --app-name 'WALLPAPER CHANGER' --transient "
                   "'Fondo cambiado en ");
    sb_appendf(&command, "%ld monitor%s' ", outputs.count,
               outputs.count > 1 ? "es" : "");
    sb_append_null(&command);
    system(command.items);
    sb_free(command);
  }
  da_free(outputs);
  da_free(wallpapers);

  return 0;
}
static int starts_with(const char *s, const char *prefix) {
  size_t lp = strlen(prefix);
  return strncmp(s, prefix, lp) == 0;
}

static void handle_event_line(const char *line) {
  // Emula el handle del script: log y case de eventos de monitor
  // echo "$1" >> /tmp/hypr.log
  char event[256];
  size_t i = 0;
  for (; i < sizeof(event) - 2 && line[i] != '\0'; i++) {
    if (line[i] == '>' && line[i + 1] == '>')
      break; // Ignora comentarios de Hyprland
    event[i] = line[i];
  }

  event[i] = '\0'; // Termina la cadena
  printf("Evento de monitor detectado: %s -> actualizando fondos\n", line);

  if (strncmp(event, "monitoradded", strlen(event)) == 0 ||
      strncmp(event, "monitorremoved", strlen(event)) == 0) {
    syslog(LOG_INFO, "Evento de monitor detectado: %s -> actualizando fondos",
           line);
    change_wallpaper();
  }
}
static int build_hypr_socket_path(String_Builder *sb) {
  const char *xdg = getenv("XDG_RUNTIME_DIR");
  const char *sig = getenv("HYPRLAND_INSTANCE_SIGNATURE");
  if (!xdg || !sig) {
    syslog(LOG_ERR,
           "XDG_RUNTIME_DIR o HYPRLAND_INSTANCE_SIGNATURE no definidos");
    return 0;
  }
  int n = sb_appendf(sb, "%s/hypr/%s/.socket2.sock", xdg, sig);
  // int n = snprintf(outBuff, sizeBuffer, "%s/hypr/%s/.socket2.sock", xdg,
  // sig);

  return 1;
}

static int build_hypr_socket_path_old(char *outBuff, size_t sizeBuffer) {
  const char *xdg = getenv("XDG_RUNTIME_DIR");
  const char *sig = getenv("HYPRLAND_INSTANCE_SIGNATURE");
  if (!xdg || !sig) {
    syslog(LOG_ERR,
           "XDG_RUNTIME_DIR o HYPRLAND_INSTANCE_SIGNATURE no definidos");
    return 0;
  }
  int n = snprintf(outBuff, sizeBuffer, "%s/hypr/%s/.socket2.sock", xdg, sig);
  if (n < 0 || (size_t)n >= sizeBuffer) {
    syslog(LOG_ERR, "Ruta del socket Hyprland demasiado larga");
    return 0;
  }
  return 1;
}

static int connect_hypr_socket(void) {
  // char path[sizeof(((struct sockaddr_un *)0)->sun_path)] = {0};
  String_Builder path_sb = {0};
  if (!build_hypr_socket_path(&path_sb)) {
    sb_free(path_sb);
    return -1;
  }
  sb_append_null(&path_sb);
  const char *path = path_sb.items;

  int fd = socket(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC, 0);
  if (fd < 0) {
    syslog(LOG_ERR, "socket(AF_UNIX) falló: %s", strerror(errno));
    return -1;
  }

  struct sockaddr_un addr;
  memset(&addr, 0, sizeof(addr));
  addr.sun_family = AF_UNIX;
  strncpy(addr.sun_path, path, sizeof(addr.sun_path) - 1);

  if (connect(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
    syslog(LOG_ERR, "No se pudo conectar a %s: %s", path, strerror(errno));
    close(fd);
    return -1;
  }

  syslog(LOG_INFO, "Conectado al socket de Hyprland: %s", path);
  return fd;
}

wait_result wait_for_read_or_timeout(int fd, int timeout_ms) {
  struct pollfd pfd = {.fd = fd, .events = POLLIN, .revents = 0};

  while (true) {
    int rc = poll(&pfd, 1, timeout_ms); // -1 = infinito, 0 = no bloquear
    if (rc > 0) {
      if (pfd.revents & POLLIN)
        return WAIT_READY;
      if (pfd.revents & (POLLHUP | POLLERR | POLLNVAL))
        return WAIT_CLOSED;
      return WAIT_ERROR;
    } else if (rc == 0) {
      return WAIT_TIMEOUT;
    } else { // rc == -1
      if (errno == EINTR)
        continue; // reintenta si fue interrumpido por señal
      return WAIT_ERROR;
    }
  }
}

// Reemplazar implementación de daemon_loop por una que lea del socket y haga
// timeout periódico
void daemon_loop_with_socket(int interval_seconds) {
  const int timeout_ms = interval_seconds * 1000;
  char linebuf[8192];
  size_t linelen = 0;

  for (;;) {
    if (g_hypr_fd < 0) {
      g_hypr_fd = connect_hypr_socket();
      if (g_hypr_fd < 0) {
        // Si no pudo conectar, espera y reintenta
        sleep(2);
        continue;
      }
    }

    wait_result r = wait_for_read_or_timeout(g_hypr_fd, timeout_ms);
    if (r == WAIT_READY) {
      char buf[4096];
      ssize_t n = recv(g_hypr_fd, buf, sizeof(buf), 0);
      if (n > 0) {
        for (ssize_t i = 0; i < n; i++) {
          char c = buf[i];
          if (c == '\n') {
            linebuf[linelen] = '\0';
            if (linelen > 0)
              handle_event_line(linebuf);
            linelen = 0;
          } else {
            if (linelen + 1 < sizeof(linebuf)) {
              linebuf[linelen++] = c;
            } else {
              // línea demasiado larga, resetea el buffer
              linelen = 0;
            }
          }
        }
      } else if (n == 0) {
        // peer cerró el socket; reconectar
        syslog(LOG_WARNING,
               "Socket de Hyprland cerrado por el peer. Reintentando...");
        close(g_hypr_fd);
        g_hypr_fd = -1;
        linelen = 0;
        sleep(1);
      } else if (errno != EINTR) {
        syslog(LOG_ERR, "recv() falló: %s", strerror(errno));
        close(g_hypr_fd);
        g_hypr_fd = -1;
        linelen = 0;
        sleep(1);
      }
    } else if (r == WAIT_TIMEOUT) {
      // Cambio periódico
      change_wallpaper();
    } else {
      // Error/hangup en poll -> reconectar
      if (g_hypr_fd >= 0) {
        close(g_hypr_fd);
        g_hypr_fd = -1;
      }
      linelen = 0;
      sleep(1);
    }
  }
}

void simple_daemon_loop(int interval_seconds) {
  // Bucle simple que espera el intervalo y cambia el wallpaper
  while (1) {
    change_wallpaper();
    sleep(interval_seconds);
  }
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
    // daemon_loop();
    change_wallpaper();
  } else {
    syslog(LOG_WARNING, "Señal no manejada: %d", sig);
  }
}

void cleanup_and_exit(void) {
  remove_pid_file(PID_FILE);
  syslog(LOG_INFO, "Demonio terminado limpiamente");
  closelog();
}

pid_t change_wallpaper_daemon_pid = -1;
pthread_t hyprland_socket_thread_pid = -1;

int main(int argc, char *argv[]) {
  // Verifica los argumentos
  // NOB_GO_REBUILD_URSELF(argc, argv);
  if (argc != 3 && argc != 4) {
    fprintf(stderr, "Uso: %s <carpeta_de_fondos> <intervalo_en_minutos>\n",
            argv[0]);
    fprintf(stderr, "-------- O ----------\n");

    fprintf(stderr, "Uso: %s <carpeta_de_fondos> <intervalo_en_minutos> -n\n",
            argv[0]);
    fprintf(stderr,
            "  -n: No conectar al socket de hyprctl.\n\tno se reaccionara "
            "a cambios de configuración de monitores\n");
    return 1;
  }
  signal(SIGUSR2, signal_handler);

  wallpaper_dir = argv[1];
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
  int interval_seconds = interval_minutes * 60;

#ifdef NDEBUG
  // Inicia el demonio
  if (daemon(0, 0) == -1) {
    perror("Error al iniciar el demonio");
    return 1;
  }
#endif

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

  change_wallpaper(); // Cambia el wallpaper al iniciar
                      // Bucle principal
                      // if (argc == 4) {
                      // if (strcmp(argv[3], "-n") == 0) {
  // Si se pasa -n, no conecta al socket de Hyprland
  syslog(LOG_INFO, "Modo no conectado al socket de Hyprland");
  simple_daemon_loop(interval_seconds);
  // return 0;
  // } else {
  // }
  // }
  // daemon_loop_with_socket(interval_seconds);

  // Cierra el syslog (nunca se alcanza en este bucle infinito)
  closelog();
  return 0;
}

#define NOB_IMPLEMENTATION
#include "nob.h"