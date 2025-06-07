#!/bin/bash

# Monitor automático del puntero para Screen Sharing
# Este script se ejecuta en segundo plano y corrige automáticamente problemas del puntero

SCRIPT_NAME="cursor_auto_monitor"
LOG_FILE="/tmp/${SCRIPT_NAME}.log"
PID_FILE="/tmp/${SCRIPT_NAME}.pid"

# Función para logging
log_message() {
    local message="$1"
    local timestamp="[$(date '+%Y-%m-%d %H:%M:%S')]"
    
    # Mostrar en terminal con colores
    echo -e "$timestamp $message"
    
    # Guardar en log sin códigos de color
    local clean_message=$(echo -e "$message" | sed 's/\x1b\[[0-9;]*m//g')
    echo "$timestamp $clean_message" >> "$LOG_FILE"
}

# Función para limpiar al salir
cleanup() {
    log_message "Deteniendo monitor automático del cursor"
    rm -f "$PID_FILE"
    exit 0
}

# Configurar trap para cleanup
trap cleanup SIGTERM SIGINT

# Verificar si ya está ejecutándose
if [[ -f "$PID_FILE" ]]; then
    local existing_pid=$(cat "$PID_FILE")
    if kill -0 "$existing_pid" 2>/dev/null; then
        echo "El monitor ya está ejecutándose (PID: $existing_pid)"
        exit 1
    else
        rm -f "$PID_FILE"
    fi
fi

# Guardar PID actual
echo $$ > "$PID_FILE"

log_message "Iniciando monitor automático del cursor"
log_message "PID: $$"

# Configuración
CHECK_INTERVAL=3  # Segundos entre verificaciones
STATIONARY_THRESHOLD=10  # Segundos sin movimiento antes de intervenir
BOUNDARY_MARGIN=50  # Píxeles de margen para detectar límites

# Variables de estado
last_position=""
stationary_start_time=""
last_movement_time=$(date +%s)

# Función para obtener posición del cursor
get_cursor_position() {
    osascript -e 'tell application "System Events" to get the position of the mouse cursor' 2>/dev/null
}

# Función para obtener resolución de pantalla
get_screen_resolution() {
    local resolution=$(system_profiler SPDisplaysDataType | grep "Resolution:" | head -1 | awk '{print $2 "x" $4}')
    echo "$resolution"
}

# Función para verificar si el cursor está fuera de límites
is_cursor_out_of_bounds() {
    local position="$1"
    local resolution=$(get_screen_resolution)
    
    if [[ -z "$resolution" || -z "$position" ]]; then
        return 1
    fi
    
    local width=$(echo "$resolution" | cut -d'x' -f1)
    local height=$(echo "$resolution" | cut -d'x' -f2)
    local x=$(echo "$position" | cut -d',' -f1)
    local y=$(echo "$position" | cut -d',' -f2)
    
    # Verificar límites con margen
    if [[ $x -lt $BOUNDARY_MARGIN || $x -gt $((width - BOUNDARY_MARGIN)) || 
          $y -lt $BOUNDARY_MARGIN || $y -gt $((height - BOUNDARY_MARGIN)) ]]; then
        return 0  # Fuera de límites
    fi
    
    return 1  # Dentro de límites
}

# Función para corregir posición del cursor
fix_cursor_position() {
    local reason="$1"
    log_message "CORRECCIÓN: $reason"
    
    # Obtener resolución y centrar cursor
    local resolution=$(get_screen_resolution)
    if [[ -n "$resolution" ]]; then
        local width=$(echo "$resolution" | cut -d'x' -f1)
        local height=$(echo "$resolution" | cut -d'x' -f2)
        local center_x=$((width / 2))
        local center_y=$((height / 2))
        
        # Mover al centro
        osascript -e "tell application \"System Events\" to set the position of the mouse cursor to {$center_x, $center_y}" 2>/dev/null
        
        # Pequeño movimiento para forzar actualización
        sleep 0.5
        osascript -e "tell application \"System Events\" to set the position of the mouse cursor to {$((center_x + 1)), $((center_y + 1))}" 2>/dev/null
        sleep 0.1
        osascript -e "tell application \"System Events\" to set the position of the mouse cursor to {$center_x, $center_y}" 2>/dev/null
        
        log_message "Cursor reposicionado al centro ($center_x, $center_y)"
    else
        log_message "ERROR: No se pudo obtener resolución de pantalla"
    fi
}

# Función para verificar procesos de Screen Sharing
check_screen_sharing_active() {
    ps aux | grep -E "Screen.*Shar|VNC|ARD" | grep -v grep >/dev/null 2>&1
}

log_message "Monitor configurado:"
log_message "- Intervalo de verificación: ${CHECK_INTERVAL}s"
log_message "- Umbral de inactividad: ${STATIONARY_THRESHOLD}s"
log_message "- Margen de límites: ${BOUNDARY_MARGIN}px"

# Loop principal de monitoreo
while true; do
    current_time=$(date +%s)
    current_position=$(get_cursor_position)
    
    if [[ -n "$current_position" ]]; then
        # Verificar si el cursor se movió
        if [[ "$current_position" != "$last_position" ]]; then
            # Cursor se movió
            last_movement_time=$current_time
            stationary_start_time=""
            
            # Verificar si está fuera de límites
            if is_cursor_out_of_bounds "$current_position"; then
                fix_cursor_position "Cursor fuera de límites: $current_position"
            fi
            
        else
            # Cursor no se movió
            if [[ -z "$stationary_start_time" ]]; then
                stationary_start_time=$current_time
            fi
            
            # Verificar si ha estado estático demasiado tiempo
            local stationary_duration=$((current_time - stationary_start_time))
            if [[ $stationary_duration -ge $STATIONARY_THRESHOLD ]]; then
                # Solo intervenir si Screen Sharing está activo
                if check_screen_sharing_active; then
                    fix_cursor_position "Cursor estático por ${stationary_duration}s en posición: $current_position"
                    stationary_start_time=$current_time  # Reset timer
                fi
            fi
        fi
        
        last_position="$current_position"
    else
        log_message "ADVERTENCIA: No se pudo obtener posición del cursor"
        # Intentar corregir cuando no se puede obtener la posición
        fix_cursor_position "No se puede obtener posición del cursor"
    fi
    
    sleep $CHECK_INTERVAL
done
