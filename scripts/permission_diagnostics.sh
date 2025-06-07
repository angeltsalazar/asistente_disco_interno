#!/bin/bash

# Script para diagnosticar permisos de accesibilidad
echo "=========================================="
echo "  DIAGNÓSTICO DE PERMISOS DE ACCESIBILIDAD"
echo "=========================================="
echo "Fecha: $(date)"
echo ""

# Función para colorear output
green() { echo -e "\033[32m$1\033[0m"; }
red() { echo -e "\033[31m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
blue() { echo -e "\033[34m$1\033[0m"; }

echo "1. VERIFICANDO APLICACIÓN ACTUAL"
echo "=========================================="

# Detectar qué aplicación estamos usando
if [[ -n "$TERM_PROGRAM" ]]; then
    echo "Terminal detectada: $TERM_PROGRAM"
    case "$TERM_PROGRAM" in
        "vscode")
            echo "Ejecutándose desde: Visual Studio Code"
            APP_NAME="Visual Studio Code"
            ;;
        "vscode-insiders")
            echo "Ejecutándose desde: Visual Studio Code - Insiders"
            APP_NAME="Visual Studio Code - Insiders"
            ;;
        "Apple_Terminal")
            echo "Ejecutándose desde: Terminal de Apple"
            APP_NAME="Terminal"
            ;;
        "iTerm.app")
            echo "Ejecutándose desde: iTerm2"
            APP_NAME="iTerm"
            ;;
        *)
            echo "Ejecutándose desde: $TERM_PROGRAM"
            APP_NAME="$TERM_PROGRAM"
            ;;
    esac
else
    echo "Variable TERM_PROGRAM no detectada"
    APP_NAME="Desconocida"
fi

echo ""
echo "2. VERIFICANDO BASE DE DATOS TCC"
echo "=========================================="

# Verificar permisos en la base de datos TCC (privacidad)
echo "Consultando base de datos de permisos de privacidad..."

# Intentar consultar la base de datos del usuario
USER_TCC_DB="$HOME/Library/Application Support/com.apple.TCC/TCC.db"
SYSTEM_TCC_DB="/Library/Application Support/com.apple.TCC/TCC.db"

if [[ -f "$USER_TCC_DB" ]]; then
    echo "Base de datos de usuario encontrada: $USER_TCC_DB"
    echo "Aplicaciones con permisos de accesibilidad (usuario):"
    sqlite3 "$USER_TCC_DB" "SELECT client, auth_value, last_modified FROM access WHERE service='kTCCServiceAccessibility';" 2>/dev/null | while IFS='|' read -r client auth last_mod; do
        if [[ -n "$client" ]]; then
            if [[ "$auth" == "2" ]]; then
                green "✓ $client - AUTORIZADO"
            else
                red "✗ $client - DENEGADO"
            fi
        fi
    done
else
    yellow "⚠️  Base de datos de usuario no encontrada"
fi

echo ""
if [[ -f "$SYSTEM_TCC_DB" ]]; then
    echo "Base de datos del sistema encontrada: $SYSTEM_TCC_DB"
    echo "Aplicaciones con permisos de accesibilidad (sistema):"
    sudo sqlite3 "$SYSTEM_TCC_DB" "SELECT client, auth_value, last_modified FROM access WHERE service='kTCCServiceAccessibility';" 2>/dev/null | while IFS='|' read -r client auth last_mod; do
        if [[ -n "$client" ]]; then
            if [[ "$auth" == "2" ]]; then
                green "✓ $client - AUTORIZADO"
            else
                red "✗ $client - DENEGADO"
            fi
        fi
    done
else
    yellow "⚠️  Base de datos del sistema no encontrada"
fi

echo ""
echo "3. PRUEBAS DE APPLESCRIPT"
echo "=========================================="

# Probar diferentes métodos de AppleScript
echo "Probando AppleScript básico..."
if osascript -e 'tell application "System Events" to return 1' 2>/dev/null >/dev/null; then
    green "✓ AppleScript básico funciona"
else
    red "✗ AppleScript básico falló"
fi

echo ""
echo "Probando acceso a System Events..."
if osascript -e 'tell application "System Events" to get name of every process' 2>/dev/null >/dev/null; then
    green "✓ Acceso a System Events funciona"
else
    red "✗ Acceso a System Events falló"
fi

echo ""
echo "Probando obtención de posición del mouse (método 1)..."
pos1=$(osascript -e 'tell application "System Events" to get the position of the mouse cursor' 2>&1)
if [[ $? -eq 0 ]]; then
    green "✓ Método 1 exitoso: $pos1"
else
    red "✗ Método 1 falló: $pos1"
fi

echo ""
echo "Probando obtención de posición del mouse (método 2)..."
pos2=$(osascript -e 'tell application "System Events" to return {x, y} of (get the position of the mouse cursor)' 2>&1)
if [[ $? -eq 0 ]]; then
    green "✓ Método 2 exitoso: $pos2"
else
    red "✗ Método 2 falló: $pos2"
fi

echo ""
echo "4. VERIFICANDO PROCESOS DEL SISTEMA"
echo "=========================================="

# Verificar si hay procesos que puedan interferir
echo "Verificando procesos relacionados con accesibilidad..."
ps aux | grep -E "(accessibility|TCC|tccd)" | grep -v grep | while read line; do
    echo "Proceso encontrado: $line"
done

# Verificar daemon TCC
if pgrep -q tccd; then
    green "✓ Daemon TCC está ejecutándose"
else
    red "✗ Daemon TCC no está ejecutándose"
fi

echo ""
echo "5. INFORMACIÓN DEL SISTEMA"
echo "=========================================="
echo "Versión de macOS: $(sw_vers -productVersion)"
echo "Versión de build: $(sw_vers -buildVersion)"
echo "Usuario actual: $(whoami)"
echo "Directorio home: $HOME"

echo ""
echo "6. INFORMACIÓN ADICIONAL"
echo "=========================================="

echo "NOTA: Scripts de reparación automática deshabilitados para evitar"
echo "      borrar permisos existentes accidentalmente."
echo ""
echo "Si necesitas resetear permisos, hazlo manualmente:"
echo "  sudo tccutil reset Accessibility [bundle_id_específico]"
echo ""
echo "Para ver aplicaciones específicas:"
echo "  tccutil list Accessibility"

echo ""
echo "Esperando 3 segundos para que el sistema se estabilice..."
sleep 3

echo ""
echo "7. PRUEBA FINAL"
echo "=========================================="
echo "Realizando prueba final después de las correcciones..."

final_test=$(osascript -e 'tell application "System Events" to get the position of the mouse cursor' 2>&1)
if [[ $? -eq 0 ]]; then
    green "✓ ¡ÉXITO! Posición del cursor: $final_test"
    echo ""
    green "Los scripts ahora deberían funcionar correctamente."
    echo "Ejecuta: ./cursor_diagnostics.sh para probar"
else
    red "✗ La prueba final falló: $final_test"
    echo ""
    yellow "SOLUCIONES MANUALES:"
    echo "1. Reiniciar el Mac completamente"
    echo "2. Remover y volver a agregar la aplicación en Configuración del Sistema"
    echo "3. Verificar que la aplicación correcta está en la lista:"
    echo "   - Si usas VS Code Insiders: 'Visual Studio Code - Insiders'"
    echo "   - Si usas Terminal: 'Terminal'"
    echo "4. Ejecutar desde Terminal nativa en lugar de terminal integrada"
fi

echo ""
echo "=========================================="
echo "  DIAGNÓSTICO COMPLETADO"
echo "=========================================="
