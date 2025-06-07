#!/bin/bash

# Script para evaluar el daño y ayudar a restaurar permisos
echo "=========================================="
echo "  EVALUACIÓN DEL DAÑO - PERMISOS TCC"
echo "=========================================="
echo "Fecha: $(date)"
echo ""

# Función para colorear output
green() { echo -e "\033[32m$1\033[0m"; }
red() { echo -e "\033[31m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
blue() { echo -e "\033[34m$1\033[0m"; }

red "⚠️  SITUACIÓN: Se ejecutó 'sudo tccutil reset Accessibility'"
red "   Esto BORRÓ todos los permisos de accesibilidad del sistema"
echo ""

echo "1. VERIFICANDO ESTADO ACTUAL"
echo "=========================================="

# Verificar base de datos de usuario
USER_TCC_DB="$HOME/Library/Application Support/com.apple.TCC/TCC.db"
if [[ -f "$USER_TCC_DB" ]]; then
    echo "Verificando permisos de accesibilidad restantes..."
    
    count=$(sqlite3 "$USER_TCC_DB" "SELECT COUNT(*) FROM access WHERE service='kTCCServiceAccessibility';" 2>/dev/null)
    if [[ "$count" == "0" || -z "$count" ]]; then
        red "✗ Confirmado: NO hay permisos de accesibilidad restantes"
    else
        echo "Permisos encontrados: $count"
        sqlite3 "$USER_TCC_DB" "SELECT client, auth_value FROM access WHERE service='kTCCServiceAccessibility';" 2>/dev/null | while IFS='|' read -r client auth; do
            if [[ "$auth" == "2" ]]; then
                green "✓ $client"
            else
                yellow "⚠️  $client (denegado)"
            fi
        done
    fi
else
    red "✗ Base de datos TCC no encontrada"
fi

echo ""
echo "2. DETECTANDO APLICACIONES COMUNES QUE NECESITAN PERMISOS"
echo "=========================================="

# Lista de aplicaciones comunes que suelen necesitar permisos de accesibilidad
declare -a common_apps=(
    "/Applications/Visual Studio Code - Insiders.app"
    "/Applications/Visual Studio Code.app"
    "/System/Applications/Utilities/Terminal.app"
    "/Applications/iTerm.app"
    "/Applications/Finder.app"
    "/Applications/Alfred 4.app"
    "/Applications/Alfred 5.app"
    "/Applications/Bartender 4.app"
    "/Applications/BetterTouchTool.app"
    "/Applications/Karabiner-Elements.app"
    "/Applications/PopClip.app"
    "/Applications/TextExpander.app"
    "/Applications/1Password 7 - Password Manager.app"
    "/Applications/1Password for Safari.app"
    "/Applications/Rectangle.app"
    "/Applications/Magnet.app"
    "/Applications/HacKit.app"
    "/Applications/Remote Desktop Scanner.app"
    "/Applications/Screen Sharing.app"
)

echo "Buscando aplicaciones instaladas que probablemente tenían permisos:"
for app in "${common_apps[@]}"; do
    if [[ -d "$app" ]]; then
        app_name=$(basename "$app" .app)
        green "✓ Encontrada: $app_name"
        echo "   Ruta: $app"
    fi
done

echo ""
echo "3. APLICACIONES ACTUALMENTE EN EJECUCIÓN"
echo "=========================================="
echo "Aplicaciones que podrían necesitar permisos de accesibilidad:"

# Buscar aplicaciones en ejecución que podrían necesitar permisos
ps aux | grep -E "\.app/" | grep -v grep | awk '{for(i=11;i<=NF;i++) printf "%s ", $i; print ""}' | sort -u | head -20

echo ""
echo "4. GUÍA DE RESTAURACIÓN"
echo "=========================================="

blue "PASOS PARA RESTAURAR PERMISOS:"
echo ""
echo "1. Abrir 'Configuración del Sistema'"
echo "2. Ir a 'Privacidad y Seguridad' > 'Accesibilidad'"
echo "3. Hacer clic en el candado 🔒 y autenticarse"
echo "4. Agregar las siguientes aplicaciones (hacer clic en '+'):"
echo ""

# Listar aplicaciones encontradas que necesitas agregar
yellow "APLICACIONES CRÍTICAS A AGREGAR:"
if [[ -d "/Applications/Visual Studio Code - Insiders.app" ]]; then
    echo "   • Visual Studio Code - Insiders (para que funcionen estos scripts)"
fi
if [[ -d "/System/Applications/Utilities/Terminal.app" ]]; then
    echo "   • Terminal (alternativa para ejecutar scripts)"
fi

echo ""
yellow "APLICACIONES ADICIONALES QUE PODRÍAS NECESITAR:"
for app in "${common_apps[@]}"; do
    if [[ -d "$app" ]]; then
        app_name=$(basename "$app" .app)
        if [[ "$app_name" != "Visual Studio Code - Insiders" && "$app_name" != "Terminal" ]]; then
            echo "   • $app_name"
        fi
    fi
done

echo ""
echo "5. RECUPERACIÓN ESPECÍFICA PARA TUS SCRIPTS"
echo "=========================================="

blue "Para que tus scripts de cursor funcionen:"
echo "1. Agregar 'Visual Studio Code - Insiders' a permisos de accesibilidad"
echo "2. Ejecutar: ./quick_permission_check.sh para verificar"
echo "3. Si funciona, ejecutar: ./cursor_diagnostics.sh"

echo ""
echo "6. LECCIONES APRENDIDAS"
echo "=========================================="
red "⚠️  IMPORTANTE: El comando 'tccutil reset' borra TODOS los permisos"
yellow "En el futuro, usar 'tccutil reset Accessibility [bundle_id]' para apps específicas"
yellow "O mejor aún, evitar resetear permisos automáticamente"

echo ""
echo "¿Deseas que cree un script para restaurar automáticamente VS Code Insiders? (y/n)"
