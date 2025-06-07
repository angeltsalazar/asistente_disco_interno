#!/bin/bash

# Script para configurar Cline con el servidor MCP Disk Assistant
# Ejecutar después de instalar la extensión Cline en VS Code Insiders

set -e

echo "🔧 Configurando Cline con MCP Disk Assistant..."
echo "=============================================="

# Directorio de configuración de VS Code Insiders
VSCODE_CONFIG_DIR="$HOME/Library/Application Support/Code - Insiders/User"
SETTINGS_FILE="$VSCODE_CONFIG_DIR/settings.json"

# Crear directorio si no existe
mkdir -p "$VSCODE_CONFIG_DIR"

# Configuración MCP para Cline
MCP_CONFIG='{
  "cline.mcpServers": {
    "disk-assistant": {
      "command": "node",
      "args": ["'$(pwd)'/dist/index.js"],
      "cwd": "'$(dirname $(pwd))'",
      "env": {
        "DISK_ASSISTANT_BASE_PATH": "'$(dirname $(pwd))'",
        "NODE_ENV": "production"
      }
    }
  }
}'

# Si settings.json no existe, crearlo
if [ ! -f "$SETTINGS_FILE" ]; then
    echo "$MCP_CONFIG" > "$SETTINGS_FILE"
    echo "✅ Archivo settings.json creado con configuración MCP"
else
    # Si existe, intentar combinar configuraciones
    echo "⚠️  settings.json ya existe. Agregue manualmente esta configuración:"
    echo ""
    echo "$MCP_CONFIG"
    echo ""
    echo "📋 Copie y pegue la configuración cline.mcpServers en su settings.json"
fi

echo ""
echo "🎯 PASOS SIGUIENTES:"
echo "==================="
echo "1. Asegúrese de que Cline esté instalado en VS Code Insiders"
echo "2. Reinicie VS Code Insiders"
echo "3. Abra el panel de Chat de Cline (Ctrl+Shift+P -> 'Cline: Open Chat')"
echo "4. Pruebe comandos como:"
echo "   • 'Analiza el uso de disco en mi Mac'"
echo "   • 'Migra Library/Caches de forma segura'"
echo "   • 'Limpia caches del sistema'"
echo ""
echo "🚀 ¡Su asistente de disco MCP está listo para usar!"
