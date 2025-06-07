#!/bin/bash
# Verificación rápida del estado del cursor

echo "Verificación rápida del cursor - $(date)"
echo "=========================================="

# Posición actual
pos=$(osascript -e 'tell application "System Events" to get the position of the mouse cursor')
echo "Posición del cursor: $pos"

# Procesos de Screen Sharing
echo "Screen Sharing activo: $(ps aux | grep -E 'Screen.*Shar|VNC' | grep -v grep | wc -l | tr -d ' ') procesos"

# Monitor automático
if [[ -f "/tmp/cursor_auto_monitor.pid" ]]; then
    pid=$(cat /tmp/cursor_auto_monitor.pid)
    if kill -0 "$pid" 2>/dev/null; then
        echo "Monitor automático: ACTIVO (PID: $pid)"
    else
        echo "Monitor automático: INACTIVO"
    fi
else
    echo "Monitor automático: INACTIVO"
fi

# Sugerencia de acción rápida
echo ""
echo "Para solución rápida: ./cursor_diagnostics.sh fix"
