#!/bin/bash

# Script para ayudar a restaurar permisos de VS Code Insiders específicamente
echo "=========================================="
echo "  RESTAURACIÓN DE PERMISOS VS CODE INSIDERS"
echo "=========================================="
echo "Fecha: $(date)"
echo ""

# Función para colorear output
green() { echo -e "\033[32m$1\033[0m"; }
red() { echo -e "\033[31m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
blue() { echo -e "\033[34m$1\033[0m"; }

echo "1. DETECTANDO CONFIGURACIÓN ACTUAL"
echo "=========================================="

echo "Aplicación detectada desde terminal: $TERM_PROGRAM"
echo "Proceso padre: $(ps -o comm= -p $PPID | head -1)"

# Verificar si VS Code Insiders está instalado
if [[ -d "/Applications/Visual Studio Code - Insiders.app" ]]; then
    green "✓ VS Code Insiders encontrado en /Applications/"
    VSCODE_PATH="/Applications/Visual Studio Code - Insiders.app"
else
    red "✗ VS Code Insiders no encontrado en /Applications/"
    echo "  Verificando otras ubicaciones..."
    find /Applications -name "*Visual Studio Code*" -type d 2>/dev/null
fi

echo ""
echo "2. PROBANDO ESTADO ACTUAL DE PERMISOS"
echo "=========================================="

# Prueba simple de AppleScript
echo "Probando acceso básico a System Events..."
test_result=$(osascript -e 'tell application "System Events" to return "test"' 2>&1)
if [[ $? -eq 0 ]]; then
    green "✓ Acceso básico a System Events funciona"
else
    red "✗ Acceso básico a System Events falló: $test_result"
fi

# Prueba de acceso al cursor
echo "Probando acceso al cursor del mouse..."
cursor_result=$(osascript -e 'tell application "System Events" to get the position of the mouse cursor' 2>&1)
if [[ $? -eq 0 ]]; then
    green "✓ Acceso al cursor funciona: $cursor_result"
    echo ""
    green "¡Los permisos ya están configurados correctamente!"
    exit 0
else
    red "✗ Acceso al cursor falló: $cursor_result"
fi

echo ""
echo "3. INSTRUCCIONES PARA RESTAURAR PERMISOS"
echo "=========================================="

yellow "PROBLEMA DETECTADO: VS Code Insiders necesita permisos de accesibilidad"
echo ""
echo "PASOS PARA SOLUCIONARLO:"
echo ""
blue "1. Abre 'Configuración del Sistema' (System Settings)"
echo "   - Haz clic en el menú Apple > Configuración del Sistema"
echo ""
blue "2. Ve a 'Privacidad y seguridad'"
echo "   - En el menú lateral izquierdo, busca 'Privacidad y seguridad'"
echo ""
blue "3. Selecciona 'Accesibilidad'"
echo "   - En la sección de privacidad, haz clic en 'Accesibilidad'"
echo ""
blue "4. Agrega VS Code Insiders:"
echo "   - Haz clic en el botón '+' (más)"
echo "   - Navega a: /Applications/"
echo "   - Selecciona: 'Visual Studio Code - Insiders.app'"
echo "   - Haz clic en 'Abrir'"
echo ""
blue "5. Verifica que la casilla esté marcada:"
echo "   - Asegúrate de que 'Visual Studio Code - Insiders' aparezca en la lista"
echo "   - Verifica que la casilla junto a él esté marcada (✓)"
echo ""

echo ""
echo "4. VERIFICACIÓN DESPUÉS DE AGREGAR PERMISOS"
echo "=========================================="
echo ""
yellow "DESPUÉS de agregar VS Code Insiders a los permisos de accesibilidad:"
echo ""
echo "1. Cierra esta terminal"
echo "2. Cierra VS Code Insiders completamente"
echo "3. Vuelve a abrir VS Code Insiders"
echo "4. Ejecuta este comando nuevamente:"
echo "   ./fix_vscode_permissions.sh"
echo ""

echo ""
echo "5. INFORMACIÓN TÉCNICA"
echo "=========================================="
echo "Bundle ID de VS Code Insiders: com.microsoft.VSCodeInsiders"
echo "Ruta de la aplicación: /Applications/Visual Studio Code - Insiders.app"
echo "Permisos necesarios: kTCCServiceAccessibility"
echo ""

echo ""
echo "6. ALTERNATIVAS SI EL PROBLEMA PERSISTE"
echo "=========================================="
echo ""
yellow "Si después de agregar permisos el problema persiste:"
echo ""
echo "Opción A - Usar Terminal nativa:"
echo "  1. Abre la aplicación 'Terminal' (no la terminal de VS Code)"
echo "  2. Navega a: cd $PWD"
echo "  3. Ejecuta los scripts desde ahí"
echo ""
echo "Opción B - Verificar permisos de Terminal también:"
echo "  1. En System Settings > Privacy & Security > Accessibility"
echo "  2. Agrega también 'Terminal' si no está presente"
echo ""
echo "Opción C - Reiniciar completamente:"
echo "  1. Reinicia tu Mac"
echo "  2. Vuelve a intentar después del reinicio"
echo ""

echo ""
red "IMPORTANTE: No ejecutes comandos 'sudo tccutil reset' sin especificar"
red "una aplicación específica, ya que esto borra TODOS los permisos."

echo ""
echo "=========================================="
echo "Para más ayuda, ejecuta: ./restore_permissions.sh"
echo "=========================================="
