#!/bin/bash

# Script simplificado para verificar permisos sin sudo
echo "=========================================="
echo "  VERIFICACIÓN RÁPIDA DE PERMISOS"
echo "=========================================="

# Función para colorear output
green() { echo -e "\033[32m$1\033[0m"; }
red() { echo -e "\033[31m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }

echo "Terminal actual: ${TERM_PROGRAM:-Terminal}"

echo ""
echo "Verificando permisos de usuario..."
USER_TCC_DB="$HOME/Library/Application Support/com.apple.TCC/TCC.db"

if [[ -f "$USER_TCC_DB" ]]; then
    echo "Aplicaciones con permisos de accesibilidad:"
    sqlite3 "$USER_TCC_DB" "SELECT client, auth_value FROM access WHERE service='kTCCServiceAccessibility';" 2>/dev/null | while IFS='|' read -r client auth; do
        if [[ -n "$client" ]]; then
            if [[ "$auth" == "2" ]]; then
                green "✓ $client"
            else
                red "✗ $client (denegado)"
            fi
        fi
    done
    
    # Contar total
    total=$(sqlite3 "$USER_TCC_DB" "SELECT COUNT(*) FROM access WHERE service='kTCCServiceAccessibility';" 2>/dev/null)
    echo "Total de entradas: $total"
else
    red "Base de datos TCC no encontrada"
fi

echo ""
echo "Probando acceso directo..."

# Método 1: Prueba simple
echo -n "Prueba básica: "
if osascript -e 'tell application "System Events" to return 1' >/dev/null 2>&1; then
    green "✓ OK"
else
    red "✗ FALLO"
fi

# Método 2: Prueba de cursor
echo -n "Prueba de cursor: "
result=$(osascript -e 'tell application "System Events" to get the position of the mouse cursor' 2>&1)
if [[ $? -eq 0 ]]; then
    green "✓ OK ($result)"
else
    red "✗ FALLO ($result)"
fi

echo ""
echo "DIAGNÓSTICO:"
if [[ "$TERM_PROGRAM" == "vscode" ]]; then
    echo "Estás usando VS Code integrado."
    echo "Verifica que 'Visual Studio Code' esté en:"
    echo "Configuración del Sistema > Privacidad y Seguridad > Accesibilidad"
elif [[ "$TERM_PROGRAM" == "vscode-insiders" ]]; then
    echo "Estás usando VS Code Insiders integrado."
    echo "Verifica que 'Visual Studio Code - Insiders' esté en:"
    echo "Configuración del Sistema > Privacidad y Seguridad > Accesibilidad"
else
    echo "Terminal: $TERM_PROGRAM"
fi
