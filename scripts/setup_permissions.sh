#!/bin/bash

# Script de primer uso - Configuración inicial de permisos
echo "=========================================="
echo "  CONFIGURACIÓN INICIAL - PERMISOS"
echo "=========================================="

# Función para colorear output
green() { echo -e "\033[32m$1\033[0m"; }
red() { echo -e "\033[31m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
blue() { echo -e "\033[34m$1\033[0m"; }

echo "Para que los scripts funcionen correctamente, necesitas habilitar permisos de accesibilidad."
echo ""

# Probar si tenemos permisos
echo "Probando permisos de accesibilidad..."
if osascript -e 'tell application "System Events" to get the position of the mouse cursor' 2>/dev/null >/dev/null; then
    green "✓ Permisos de accesibilidad ya están habilitados"
    
    # Mostrar posición actual
    pos=$(osascript -e 'tell application "System Events" to get the position of the mouse cursor' 2>/dev/null)
    echo "Posición actual del cursor: $pos"
    
    echo ""
    echo "¡Los scripts están listos para usar!"
    echo ""
    green "Comandos principales:"
    echo "  ./cursor_diagnostics.sh       - Diagnóstico completo"
    echo "  ./cursor_diagnostics.sh fix   - Reparación rápida"
    echo "  ./cursor_manager.sh start     - Iniciar monitor automático"
    echo "  ./quick_cursor_check.sh       - Verificación rápida"
    
else
    red "✗ Permisos de accesibilidad NO están habilitados"
    echo ""
    yellow "Para habilitar permisos:"
    echo "1. Abrir 'Preferencias del Sistema'"
    echo "2. Ir a 'Seguridad y Privacidad' > 'Privacidad'"
    echo "3. Seleccionar 'Accesibilidad' en la lista izquierda"
    echo "4. Hacer clic en el candado 🔒 y autenticarse"
    echo "5. Agregar 'Terminal' haciendo clic en el botón '+'"
    echo "6. Buscar y seleccionar la aplicación 'Terminal'"
    echo "7. Asegurarse de que esté marcada la casilla ✓"
    echo ""
    blue "Una vez habilitados los permisos, ejecuta nuevamente este script para verificar."
    echo ""
    yellow "Si usas iTerm2 o otra terminal, agrega esa aplicación en lugar de Terminal."
fi

echo ""
echo "=========================================="
echo "  SCRIPTS DISPONIBLES"
echo "=========================================="
ls -la /Users/angelsalazar/Documents/scripts/cursor* /Users/angelsalazar/Documents/scripts/quick*

echo ""
echo "Para más información, consulta: README_cursor_solution.md"
