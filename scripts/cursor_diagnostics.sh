#!/bin/bash

# Script de diagnóstico y reparación del puntero para Screen Sharing
# Fecha: 5 de junio de 2025
# Uso: ./cursor_diagnostics.sh [monitor|fix|reset]

echo "=========================================="
echo "  DIAGNÓSTICO DEL PUNTERO - SCREEN SHARING"
echo "=========================================="
echo "Fecha: $(date)"
echo "Ejecutándose en: $(hostname)"
echo ""

# Función para colorear output
green() { echo -e "\033[32m$1\033[0m"; }
red() { echo -e "\033[31m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
blue() { echo -e "\033[34m$1\033[0m"; }
cyan() { echo -e "\033[36m$1\033[0m"; }

# Función para mostrar ayuda
show_help() {
    echo "Uso: $0 [opción]"
    echo ""
    echo "Opciones:"
    echo "  monitor    - Monitorear continuamente el estado del puntero"
    echo "  fix        - Intentar reparar problemas del puntero"
    echo "  reset      - Reiniciar completamente el sistema del puntero"
    echo "  info       - Mostrar información detallada del sistema"
    echo "  help       - Mostrar esta ayuda"
    echo ""
    echo "Sin opciones: Ejecuta diagnóstico completo"
}

# Función para obtener información del puntero
get_cursor_info() {
    echo "1. INFORMACIÓN DEL PUNTERO"
    echo "=========================================="
    
    # Posición actual del cursor
    local cursor_pos=$(osascript -e 'tell application "System Events" to get the position of the mouse cursor' 2>/dev/null)
    if [[ $? -eq 0 && -n "$cursor_pos" ]]; then
        echo "Posición actual del cursor: $cursor_pos"
    else
        echo "Posición actual del cursor: No disponible (permisos de accesibilidad requeridos)"
    fi
    
    # Información de pantallas
    echo ""
    echo "Configuración de pantallas:"
    system_profiler SPDisplaysDataType | grep -E "Resolution|Displays|Connection Type" | head -10
    
    # Verificar si hay procesos de Screen Sharing activos
    echo ""
    echo "Procesos de Screen Sharing activos:"
    ps aux | grep -i "screen.*shar\|vnc\|remote" | grep -v grep || echo "No se encontraron procesos de Screen Sharing"
    
    # Estado del Window Server
    echo ""
    echo "Estado del Window Server:"
    local windowserver_pid=$(pgrep WindowServer)
    if [[ -n "$windowserver_pid" ]]; then
        green "✓ WindowServer ejecutándose (PID: $windowserver_pid)"
    else
        red "✗ WindowServer no encontrado"
    fi
}

# Función para monitorear el puntero
monitor_cursor() {
    echo "2. MONITOREANDO PUNTERO"
    echo "=========================================="
    yellow "Iniciando monitoreo del puntero (Presiona Ctrl+C para detener)..."
    echo "Se registrará la posición cada 2 segundos"
    echo ""
    
    local last_pos=""
    local stationary_count=0
    local movement_count=0
    
    while true; do
        local current_pos=$(osascript -e 'tell application "System Events" to get the position of the mouse cursor' 2>/dev/null)
        local timestamp=$(date '+%H:%M:%S')
        
        if [[ $? -ne 0 || -z "$current_pos" ]]; then
            red "[$timestamp] Error: No se puede obtener posición del cursor (permisos de accesibilidad requeridos)"
            echo "Para habilitar permisos: Preferencias del Sistema > Seguridad y Privacidad > Privacidad > Accesibilidad"
            break
        fi
        
        if [[ "$current_pos" == "$last_pos" ]]; then
            ((stationary_count++))
            if [[ $stationary_count -eq 1 ]]; then
                echo "[$timestamp] Puntero estacionario en: $current_pos"
            elif [[ $((stationary_count % 10)) -eq 0 ]]; then
                yellow "[$timestamp] Puntero sin movimiento por ${stationary_count} iteraciones"
            fi
        else
            if [[ $stationary_count -gt 0 ]]; then
                green "[$timestamp] Puntero en movimiento: $last_pos → $current_pos"
                stationary_count=0
            fi
            ((movement_count++))
        fi
        
        last_pos="$current_pos"
        sleep 2
    done
}

# Función para verificar límites de pantalla
check_screen_bounds() {
    echo "3. VERIFICANDO LÍMITES DE PANTALLA"
    echo "=========================================="
    
    # Obtener información de resolución de pantalla
    local resolution=$(system_profiler SPDisplaysDataType | grep Resolution | head -1 | awk '{print $2 "x" $4}')
    echo "Resolución principal: $resolution"
    
    # Extraer ancho y alto
    local width=$(echo $resolution | cut -d'x' -f1)
    local height=$(echo $resolution | cut -d'x' -f2)
    
    if [[ -n "$width" && -n "$height" ]]; then
        echo "Límites de pantalla: 0,0 a $width,$height"
        
        # Verificar posición actual del cursor
        local current_pos=$(osascript -e 'tell application "System Events" to get the position of the mouse cursor' 2>/dev/null)
        if [[ $? -eq 0 && -n "$current_pos" ]]; then
            local x=$(echo $current_pos | cut -d',' -f1)
            local y=$(echo $current_pos | cut -d',' -f2)
            
            echo "Posición actual: x=$x, y=$y"
            
            # Verificar si está fuera de límites
            if [[ $x -lt 0 || $x -gt $width || $y -lt 0 || $y -gt $height ]]; then
                red "⚠️  PUNTERO FUERA DE LÍMITES DE PANTALLA"
                return 1
            else
                green "✓ Puntero dentro de límites normales"
                return 0
            fi
        else
            yellow "⚠️  No se puede obtener posición del cursor (permisos requeridos)"
            return 2
        fi
    else
        yellow "⚠️  No se pudo determinar resolución de pantalla"
        return 2
    fi
}

# Función para reparar el puntero
fix_cursor() {
    echo "4. REPARANDO PROBLEMAS DEL PUNTERO"
    echo "=========================================="
    
    # Verificar límites primero
    if ! check_screen_bounds; then
        yellow "Moviendo puntero al centro de la pantalla..."
        osascript -e 'tell application "System Events" to set the position of the mouse cursor to {640, 360}'
        sleep 1
    fi
    
    # Forzar actualización del cursor
    echo "Forzando actualización del cursor..."
    osascript -e '
        tell application "System Events"
            -- Mover cursor ligeramente para forzar actualización
            set currentPos to the position of the mouse cursor
            set x to item 1 of currentPos
            set y to item 2 of currentPos
            set the position of the mouse cursor to {x + 1, y + 1}
            delay 0.1
            set the position of the mouse cursor to {x, y}
        end tell
    '
    
    # Verificar y reparar procesos relacionados
    echo "Verificando procesos del sistema..."
    
    # Verificar dock (a veces afecta el cursor)
    if ! pgrep -q Dock; then
        yellow "Reiniciando Dock..."
        killall Dock 2>/dev/null
        sleep 2
    fi
    
    # Verificar Finder
    if ! pgrep -q Finder; then
        yellow "Reiniciando Finder..."
        killall Finder 2>/dev/null
        sleep 2
    fi
    
    green "✓ Reparaciones completadas"
}

# Función para reiniciar sistema del cursor
reset_cursor_system() {
    echo "5. REINICIANDO SISTEMA DEL CURSOR"
    echo "=========================================="
    yellow "⚠️  Esta operación puede causar parpadeos en pantalla"
    
    read -p "¿Continuar con el reinicio completo? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operación cancelada"
        return 1
    fi
    
    echo "Reiniciando componentes del sistema..."
    
    # Reiniciar WindowServer (esto reiniciará toda la interfaz gráfica)
    sudo launchctl kickstart -k system/com.apple.WindowServer
    
    echo "Esperando a que el sistema se estabilice..."
    sleep 5
    
    # Mover cursor al centro
    osascript -e 'tell application "System Events" to set the position of the mouse cursor to {640, 360}'
    
    green "✓ Reinicio del sistema del cursor completado"
}

# Función para diagnóstico de Screen Sharing
diagnose_screen_sharing() {
    echo "6. DIAGNÓSTICO DE SCREEN SHARING"
    echo "=========================================="
    
    # Verificar si Screen Sharing está habilitado
    local screen_sharing_enabled=$(sudo systemsetup -getremotelogin 2>/dev/null)
    echo "Estado de Remote Login: $screen_sharing_enabled"
    
    # Verificar procesos VNC/ARD
    echo ""
    echo "Procesos relacionados con Screen Sharing:"
    ps aux | grep -E "vnc|ard|screenshar" | grep -v grep || echo "No se encontraron procesos relacionados"
    
    # Verificar archivos de log
    echo ""
    echo "Logs recientes de Screen Sharing:"
    if [[ -f "/var/log/system.log" ]]; then
        tail -20 /var/log/system.log | grep -i "screen\|vnc\|cursor" | tail -5 || echo "No hay logs relevantes"
    fi
    
    # Verificar configuración de accesibilidad
    echo ""
    echo "Verificando permisos de accesibilidad..."
    local accessibility_status=$(sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db "SELECT client FROM access WHERE service='kTCCServiceAccessibility';" 2>/dev/null | head -5)
    if [[ -n "$accessibility_status" ]]; then
        green "✓ Aplicaciones con permisos de accesibilidad encontradas"
    else
        yellow "⚠️  Verificar permisos de accesibilidad en Preferencias del Sistema"
    fi
}

# Función principal de diagnóstico
run_full_diagnosis() {
    get_cursor_info
    echo ""
    check_screen_bounds
    echo ""
    diagnose_screen_sharing
    echo ""
    
    echo "=========================================="
    echo "  RESUMEN DE DIAGNÓSTICO"
    echo "=========================================="
    
    # Sugerencias basadas en los problemas reportados
    echo "Problemas reportados y soluciones:"
    echo ""
    cyan "1. Puntero desaparece al ir más allá de fronteras:"
    echo "   → Ejecutar: $0 fix"
    echo ""
    cyan "2. Puntero desaparece al usar teclado:"
    echo "   → Verificar configuración de 'Hide cursor while typing'"
    echo "   → Ir a Preferencias del Sistema > Accesibilidad > Puntero"
    echo ""
    cyan "3. Puntero desaparece con movimientos rápidos:"
    echo "   → Ajustar velocidad de seguimiento del trackpad/ratón"
    echo "   → Ejecutar: $0 reset (si persiste el problema)"
    echo ""
    cyan "4. Para monitoreo continuo:"
    echo "   → Ejecutar: $0 monitor"
}

# Script principal
case "${1:-}" in
    "monitor")
        monitor_cursor
        ;;
    "fix")
        fix_cursor
        ;;
    "reset")
        reset_cursor_system
        ;;
    "info")
        get_cursor_info
        ;;
    "help")
        show_help
        ;;
    "")
        run_full_diagnosis
        ;;
    *)
        red "Opción no válida: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
