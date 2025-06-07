#!/bin/bash

# Script de prueba con sintaxis alternativa de AppleScript
echo "Probando diferentes sintaxis de AppleScript..."

echo "Método 1 (original):"
osascript -e 'tell application "System Events" to get the position of the mouse cursor' 2>&1

echo ""
echo "Método 2 (alternativo):"
osascript -e 'tell application "System Events" to get mouse location' 2>&1

echo ""
echo "Método 3 (con paréntesis):"
osascript -e 'tell application "System Events" to get (the position of the mouse cursor)' 2>&1

echo ""
echo "Método 4 (comando mouse):"
osascript -e 'tell application "System Events" to get the mouse cursor position' 2>&1

echo ""
echo "Método 5 (usando Foundation):"
osascript -e 'use framework "Foundation"
tell application "System Events" 
    set mousePos to mouse location
    return mousePos
end tell' 2>&1

echo ""
echo "Si alguno de estos métodos funciona, actualizaremos los scripts principales."
