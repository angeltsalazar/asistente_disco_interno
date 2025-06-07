#!/bin/bash

# Gestor del Monitor Automático del Cursor
# Uso: ./cursor_manager.sh [start|stop|status|restart]

MONITOR_SCRIPT="/Users/angelsalazar/Documents/scripts/cursor_auto_monitor.sh"
PID_FILE="/tmp/cursor_auto_monitor.pid"
LOG_FILE="/tmp/cursor_auto_monitor.log"

# Función para colorear output
green() { echo -e "\033[32m$1\033[0m"; }
red() { echo -e "\033[31m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
blue() { echo -e "\033[34m$1\033[0m"; }

# Función para verificar si el monitor está ejecutándose
is_monitor_running() {
    if [[ -f "$PID_FILE" ]]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            return 0  # Está ejecutándose
        else
            rm -f "$PID_FILE"  # Limpiar PID file obsoleto
            return 1  # No está ejecutándose
        fi
    else
        return 1  # No está ejecutándose
    fi
}

# Función para iniciar el monitor
start_monitor() {
    if is_monitor_running; then
        local pid=$(cat "$PID_FILE")
        yellow "El monitor ya está ejecutándose (PID: $pid)"
        return 1
    fi
    
    echo "Iniciando monitor automático del cursor..."
    nohup "$MONITOR_SCRIPT" > /dev/null 2>&1 &
    
    # Esperar un poco y verificar que se inició correctamente
    sleep 2
    
    if is_monitor_running; then
        local pid=$(cat "$PID_FILE")
        green "✓ Monitor iniciado correctamente (PID: $pid)"
        echo "Log file: $LOG_FILE"
        return 0
    else
        red "✗ Error al iniciar el monitor"
        return 1
    fi
}

# Función para detener el monitor
stop_monitor() {
    if ! is_monitor_running; then
        yellow "El monitor no está ejecutándose"
        return 1
    fi
    
    local pid=$(cat "$PID_FILE")
    echo "Deteniendo monitor automático del cursor (PID: $pid)..."
    
    kill "$pid" 2>/dev/null
    sleep 2
    
    if ! is_monitor_running; then
        green "✓ Monitor detenido correctamente"
        return 0
    else
        red "✗ Error al detener el monitor, forzando terminación..."
        kill -9 "$pid" 2>/dev/null
        rm -f "$PID_FILE"
        green "✓ Monitor terminado forzosamente"
        return 0
    fi
}

# Función para mostrar estado
show_status() {
    echo "=========================================="
    echo "  ESTADO DEL MONITOR DEL CURSOR"
    echo "=========================================="
    
    if is_monitor_running; then
        local pid=$(cat "$PID_FILE")
        green "✓ Monitor ejecutándose (PID: $pid)"
        
        # Mostrar información del proceso
        echo ""
        echo "Información del proceso:"
        ps -p "$pid" -o pid,ppid,pgid,time,etime,command 2>/dev/null || echo "No se pudo obtener información del proceso"
        
        # Mostrar últimas líneas del log
        echo ""
        echo "Últimas actividades (últimas 10 líneas del log):"
        if [[ -f "$LOG_FILE" ]]; then
            tail -10 "$LOG_FILE"
        else
            echo "No hay archivo de log disponible"
        fi
        
    else
        red "✗ Monitor no está ejecutándose"
    fi
    
    # Mostrar información adicional
    echo ""
    echo "Archivos del sistema:"
    echo "- Script principal: $MONITOR_SCRIPT"
    echo "- Archivo PID: $PID_FILE"
    echo "- Archivo LOG: $LOG_FILE"
    
    if [[ -f "$LOG_FILE" ]]; then
        local log_size=$(du -h "$LOG_FILE" | cut -f1)
        echo "- Tamaño del log: $log_size"
    fi
}

# Función para reiniciar el monitor
restart_monitor() {
    echo "Reiniciando monitor automático del cursor..."
    stop_monitor
    sleep 1
    start_monitor
}

# Función para mostrar el log en tiempo real
show_log() {
    if [[ ! -f "$LOG_FILE" ]]; then
        red "✗ No se encontró archivo de log: $LOG_FILE"
        return 1
    fi
    
    echo "Mostrando log en tiempo real (Presiona Ctrl+C para salir)..."
    echo "=========================================="
    tail -f "$LOG_FILE"
}

# Función para mostrar ayuda
show_help() {
    echo "Gestor del Monitor Automático del Cursor"
    echo "=========================================="
    echo ""
    echo "Uso: $0 [comando]"
    echo ""
    echo "Comandos disponibles:"
    echo "  start     - Iniciar el monitor automático"
    echo "  stop      - Detener el monitor automático"
    echo "  restart   - Reiniciar el monitor automático"
    echo "  status    - Mostrar estado actual del monitor"
    echo "  log       - Mostrar log en tiempo real"
    echo "  help      - Mostrar esta ayuda"
    echo ""
    echo "Sin comando: Mostrar estado actual"
    echo ""
    echo "El monitor automático corrige problemas del cursor durante Screen Sharing:"
    echo "- Reposiciona el cursor cuando sale de los límites de pantalla"
    echo "- Reactiva el cursor cuando está estático por mucho tiempo"
    echo "- Solo actúa cuando hay sesiones de Screen Sharing activas"
}

# Script principal
case "${1:-status}" in
    "start")
        start_monitor
        ;;
    "stop")
        stop_monitor
        ;;
    "restart")
        restart_monitor
        ;;
    "status")
        show_status
        ;;
    "log")
        show_log
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        red "Comando no válido: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
