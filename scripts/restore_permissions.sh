#!/bin/bash

# Script para guiar la restauración de permisos críticos
echo "=========================================="
echo "  RESTAURACIÓN GUIADA DE PERMISOS"
echo "=========================================="

# Función para colorear output
green() { echo -e "\033[32m$1\033[0m"; }
red() { echo -e "\033[31m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
blue() { echo -e "\033[34m$1\033[0m"; }

blue "Este script te guiará para restaurar los permisos de accesibilidad"
blue "que se perdieron al ejecutar 'sudo tccutil reset Accessibility'"
echo ""

echo "PASO 1: Abrir Configuración del Sistema"
echo "=========================================="
echo "1. Haz clic en el menú Apple 🍎"
echo "2. Selecciona 'Configuración del Sistema' (o 'System Settings')"
echo ""
read -p "¿Has abierto Configuración del Sistema? (Presiona Enter para continuar)"

echo ""
echo "PASO 2: Navegar a Privacidad y Seguridad"
echo "=========================================="
echo "1. En el panel izquierdo, busca 'Privacidad y Seguridad'"
echo "2. Haz clic en 'Privacidad y Seguridad'"
echo "3. En el panel derecho, busca y haz clic en 'Accesibilidad'"
echo ""
read -p "¿Estás en la sección de Accesibilidad? (Presiona Enter para continuar)"

echo ""
echo "PASO 3: Desbloquear configuración"
echo "=========================================="
echo "1. En la parte inferior, verás un candado 🔒"
echo "2. Haz clic en el candado"
echo "3. Introduce tu contraseña de administrador"
echo ""
read -p "¿Has desbloqueado la configuración? (Presiona Enter para continuar)"

echo ""
echo "PASO 4: Agregar Visual Studio Code - Insiders"
echo "=========================================="
echo "1. Haz clic en el botón '+' (agregar)"
echo "2. Navega a la carpeta 'Aplicaciones' (Applications)"
echo "3. Busca y selecciona 'Visual Studio Code - Insiders'"
echo "4. Haz clic en 'Abrir'"
echo "5. Asegúrate de que la casilla esté marcada ✓"
echo ""
yellow "IMPORTANTE: Debe ser 'Visual Studio Code - Insiders', NO 'Visual Studio Code'"
echo ""
read -p "¿Has agregado VS Code Insiders? (Presiona Enter para continuar)"

echo ""
echo "PASO 5: Verificar que funciona"
echo "=========================================="
echo "Ahora vamos a probar si los permisos funcionan:"
echo ""

# Probar permisos
echo "Probando permisos..."
if osascript -e 'tell application "System Events" to get the position of the mouse cursor' >/dev/null 2>&1; then
    green "✅ ¡ÉXITO! Los permisos están funcionando"
    
    # Obtener posición
    pos=$(osascript -e 'tell application "System Events" to get the position of the mouse cursor' 2>/dev/null)
    echo "Posición actual del cursor: $pos"
    
    echo ""
    green "🎉 ¡Restauración exitosa!"
    echo ""
    echo "Ahora puedes usar todos los scripts:"
    echo "  • ./cursor_diagnostics.sh"
    echo "  • ./cursor_manager.sh start"
    echo "  • ./quick_cursor_check.sh"
    
else
    red "❌ Los permisos aún no funcionan"
    echo ""
    yellow "Posibles problemas:"
    echo "1. No agregaste la aplicación correcta"
    echo "2. La casilla no está marcada"
    echo "3. Necesitas reiniciar VS Code Insiders"
    echo ""
    echo "Intenta:"
    echo "1. Cerrar completamente VS Code Insiders"
    echo "2. Volver a abrirlo"
    echo "3. Ejecutar este script nuevamente"
fi

echo ""
echo "PASO 6 (OPCIONAL): Agregar otras aplicaciones importantes"
echo "=========================================="
echo "Si usabas otras aplicaciones que necesitan permisos de accesibilidad,"
echo "agrégalas siguiendo el mismo proceso:"
echo ""

# Lista de aplicaciones comunes
echo "Aplicaciones comunes que podrías necesitar:"
declare -a apps=(
    "Terminal"
    "Alfred"
    "BetterTouchTool"
    "Karabiner-Elements"
    "Rectangle"
    "Magnet"
    "PopClip"
    "TextExpander"
    "1Password"
    "Bartender"
)

for app in "${apps[@]}"; do
    if [[ -d "/Applications/$app.app" ]]; then
        echo "  ✓ $app (detectado en tu sistema)"
    elif [[ -d "/System/Applications/$app.app" ]]; then
        echo "  ✓ $app (aplicación del sistema)"
    else
        echo "  • $app"
    fi
done

echo ""
echo "=========================================="
echo "  RESTAURACIÓN COMPLETADA"
echo "=========================================="
echo ""
blue "Recuerda: En el futuro, evita usar comandos que reseteen"
blue "permisos automáticamente sin confirmación explícita."
