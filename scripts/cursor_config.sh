#!/bin/bash

# Configuraciones para optimizar Screen Sharing y prevenir problemas del cursor
# Este script aplica configuraciones recomendadas para mejorar la experiencia

echo "=========================================="
echo "  CONFIGURACIÓN PARA SCREEN SHARING"
echo "=========================================="
echo "Aplicando configuraciones para prevenir problemas del cursor"
echo ""

# Función para colorear output
green() { echo -e "\033[32m$1\033[0m"; }
red() { echo -e "\033[31m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
blue() { echo -e "\033[34m$1\033[0m"; }

# Función para verificar y aplicar configuración
apply_setting() {
    local setting="$1"
    local value="$2"
    local description="$3"
    
    echo "Aplicando: $description"
    if defaults write "$setting" "$value" 2>/dev/null; then
        green "✓ $description aplicada correctamente"
    else
        red "✗ Error aplicando: $description"
    fi
}

echo "1. CONFIGURACIONES DEL CURSOR"
echo "=========================================="

# Desactivar "Hide cursor while typing" que puede causar problemas
apply_setting "NSGlobalDomain" "NSTextInsertionPointBlinkPeriodOn" "500" "Configurar parpadeo del cursor"
apply_setting "NSGlobalDomain" "NSTextInsertionPointBlinkPeriodOff" "500" "Configurar pausa del parpadeo"

# Configurar el cursor para que sea más visible
apply_setting "com.apple.universalaccess" "mouseDriverCursorSize" "1.5" "Aumentar tamaño del cursor"

echo ""
echo "2. CONFIGURACIONES DE TRACKPAD/MOUSE"
echo "=========================================="

# Configurar velocidad de seguimiento
apply_setting "NSGlobalDomain" "com.apple.mouse.scaling" "3" "Configurar velocidad del mouse"
apply_setting "NSGlobalDomain" "com.apple.trackpad.scaling" "3" "Configurar velocidad del trackpad"

# Configurar aceleración
apply_setting "NSGlobalDomain" "com.apple.mouse.acceleration" "1" "Habilitar aceleración del mouse"

echo ""
echo "3. CONFIGURACIONES DE ACCESIBILIDAD"
echo "=========================================="

# Configurar cursor para que sea más visible durante movimientos rápidos
apply_setting "com.apple.universalaccess" "mouseDriverCursorSize" "2.0" "Cursor más grande para mejor visibilidad"
apply_setting "com.apple.universalaccess" "mouseDriverIgnoreTrackpad" "false" "Permitir trackpad y mouse simultáneamente"

echo ""
echo "4. CONFIGURACIONES DE SCREEN SHARING"
echo "=========================================="

# Optimizar calidad de Screen Sharing
apply_setting "com.apple.ScreenSharing" "EnableColor" "true" "Habilitar color en Screen Sharing"
apply_setting "com.apple.ScreenSharing" "EnableScale" "false" "Desactivar escalado automático"

# Configurar para mejor rendimiento
apply_setting "com.apple.screensharing.agent" "adaptive" "false" "Desactivar calidad adaptativa"

echo ""
echo "5. CONFIGURACIONES DEL WINDOW SERVER"
echo "=========================================="

# Configuraciones para mejor manejo del cursor en el Window Server
sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true 2>/dev/null && green "✓ Resolución de pantalla optimizada" || red "✗ Error en configuración de resolución"

echo ""
echo "6. CONFIGURACIONES DE RED PARA THUNDERBOLT"
echo "=========================================="

# Verificar y optimizar MTU para Thunderbolt Bridge
if networksetup -listallnetworkservices | grep -q "Thunderbolt Bridge"; then
    echo "Optimizando configuración de Thunderbolt Bridge..."
    
    # Configurar MTU para mejor rendimiento
    sudo networksetup -setMTU "Thunderbolt Bridge" 9000 2>/dev/null && green "✓ MTU configurado a 9000 para Thunderbolt Bridge" || yellow "⚠️  No se pudo configurar MTU"
    
    # Verificar configuración actual
    echo "Configuración actual de Thunderbolt Bridge:"
    networksetup -getinfo "Thunderbolt Bridge" 2>/dev/null || networksetup -getinfo "Puente Thunderbolt" 2>/dev/null
else
    yellow "⚠️  Thunderbolt Bridge no encontrado"
fi

echo ""
echo "7. CONFIGURACIONES DE ENERGÍA"
echo "=========================================="

# Desactivar suspensión que puede afectar Screen Sharing
sudo pmset -c displaysleep 0 2>/dev/null && green "✓ Suspensión de pantalla desactivada (AC)" || red "✗ Error configurando suspensión"
sudo pmset -c sleep 0 2>/dev/null && green "✓ Suspensión del sistema desactivada (AC)" || red "✗ Error configurando suspensión del sistema"

echo ""
echo "8. VERIFICAR PERMISOS DE ACCESIBILIDAD"
echo "=========================================="

echo "Verificando aplicaciones con permisos de accesibilidad..."
sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db "SELECT client FROM access WHERE service='kTCCServiceAccessibility';" 2>/dev/null | while read app; do
    if [[ -n "$app" ]]; then
        green "✓ $app tiene permisos de accesibilidad"
    fi
done

echo ""
echo "=========================================="
echo "  CONFIGURACIÓN COMPLETADA"
echo "=========================================="
echo ""
yellow "IMPORTANTE: Algunas configuraciones requieren reiniciar aplicaciones o el sistema."
echo ""
echo "Recomendaciones adicionales:"
echo "1. Reiniciar Dock: killall Dock"
echo "2. Reiniciar Finder: killall Finder"
echo "3. Cerrar y reabrir sesiones de Screen Sharing"
echo "4. Si persisten problemas, reiniciar el sistema"
echo ""
echo "Para monitorear automáticamente el cursor:"
echo "  ./cursor_manager.sh start"
echo ""
echo "Para diagnosticar problemas específicos:"
echo "  ./cursor_diagnostics.sh"

# Crear script de verificación rápida
echo ""
echo "Creando script de verificación rápida..."
cat > /Users/angelsalazar/Documents/scripts/quick_cursor_check.sh << 'EOF'
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
EOF

chmod +x /Users/angelsalazar/Documents/scripts/quick_cursor_check.sh
green "✓ Script de verificación rápida creado: quick_cursor_check.sh"
