#!/bin/bash
# Instalador específico para VS Code Insiders con MCP Disk Assistant
# Configura el servidor MCP para uso con extensiones de VS Code

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🆚 Instalador MCP Disk Assistant para VS Code${NC}"
echo -e "${BLUE}===============================================${NC}"
echo

# Rutas
MCP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VSCODE_CONFIG_DIR="$HOME/.vscode-insiders/User"
VSCODE_SETTINGS="$VSCODE_CONFIG_DIR/settings.json"

echo -e "${YELLOW}📍 Directorio MCP: $MCP_DIR${NC}"
echo -e "${YELLOW}📍 VS Code Config: $VSCODE_CONFIG_DIR${NC}"

# Verificar Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js no está instalado${NC}"
    echo -e "${YELLOW}Por favor instala Node.js desde: https://nodejs.org/${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Node.js encontrado: $(node --version)${NC}"

# Verificar VS Code Insiders
if ! command -v code-insiders &> /dev/null; then
    echo -e "${YELLOW}⚠️  VS Code Insiders no encontrado en PATH${NC}"
    echo -e "${YELLOW}Continuando con la instalación manual...${NC}"
fi

# Instalar dependencias y compilar
echo -e "${BLUE}📦 Instalando dependencias y compilando...${NC}"
cd "$MCP_DIR"
npm install && npm run build

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Error en la instalación/compilación${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Proyecto compilado exitosamente${NC}"

# Crear directorio de configuración si no existe
mkdir -p "$VSCODE_CONFIG_DIR"

# Crear configuración para VS Code
echo -e "${BLUE}⚙️  Configurando MCP para VS Code...${NC}"

# Archivo de configuración MCP para extensiones
cat > "$MCP_DIR/vscode-mcp-config.json" << EOF
{
  "mcpServers": {
    "disk-assistant": {
      "command": "node",
      "args": ["$MCP_DIR/dist/index.js"],
      "cwd": "$(dirname "$MCP_DIR")",
      "env": {
        "DISK_ASSISTANT_BASE_PATH": "$(dirname "$MCP_DIR")",
        "NODE_ENV": "production"
      }
    }
  }
}
EOF

# Configuración para settings.json de VS Code
VSCODE_MCP_CONFIG=$(cat << EOF
{
  "cline.mcpServers": {
    "disk-assistant": {
      "command": "node",
      "args": ["$MCP_DIR/dist/index.js"],
      "cwd": "$(dirname "$MCP_DIR")",
      "env": {
        "DISK_ASSISTANT_BASE_PATH": "$(dirname "$MCP_DIR")"
      }
    }
  },
  "copilot-mcp.servers": [
    {
      "name": "disk-assistant",
      "command": "node",
      "args": ["$MCP_DIR/dist/index.js"],
      "cwd": "$(dirname "$MCP_DIR")",
      "env": {
        "DISK_ASSISTANT_BASE_PATH": "$(dirname "$MCP_DIR")"
      }
    }
  ],
  "mcp.servers": {
    "disk-assistant": {
      "command": "node", 
      "args": ["$MCP_DIR/dist/index.js"],
      "cwd": "$(dirname "$MCP_DIR")",
      "env": {
        "DISK_ASSISTANT_BASE_PATH": "$(dirname "$MCP_DIR")"
      }
    }
  }
}
EOF
)

# Manejar settings.json existente
if [ -f "$VSCODE_SETTINGS" ]; then
    echo -e "${YELLOW}⚠️  Configuración de VS Code existente encontrada${NC}"
    
    # Backup
    cp "$VSCODE_SETTINGS" "$VSCODE_SETTINGS.backup.$(date +%Y%m%d_%H%M%S)"
    
    if command -v jq &> /dev/null; then
        echo -e "${BLUE}🔄 Fusionando configuración con jq...${NC}"
        
        # Fusionar configuraciones
        jq --argjson new_config "$VSCODE_MCP_CONFIG" '. + $new_config' "$VSCODE_SETTINGS" > "$VSCODE_SETTINGS.tmp" && mv "$VSCODE_SETTINGS.tmp" "$VSCODE_SETTINGS"
    else
        echo -e "${YELLOW}⚠️  jq no disponible. Configuración manual requerida.${NC}"
        echo -e "${BLUE}Agrega esta configuración a $VSCODE_SETTINGS:${NC}"
        echo "$VSCODE_MCP_CONFIG"
        echo
        echo -e "${YELLOW}Presiona Enter cuando hayas agregado la configuración...${NC}"
        read
    fi
else
    # Crear nueva configuración
    echo "$VSCODE_MCP_CONFIG" > "$VSCODE_SETTINGS"
    echo -e "${GREEN}✅ Configuración de VS Code creada${NC}"
fi

# Crear script de inicio directo
cat > "$MCP_DIR/start-mcp-server.sh" << EOF
#!/bin/bash
# Script para iniciar el servidor MCP manualmente
cd "$MCP_DIR"
node dist/index.js
EOF
chmod +x "$MCP_DIR/start-mcp-server.sh"

# Verificar permisos de scripts
echo -e "${BLUE}🔐 Verificando permisos de scripts...${NC}"
SCRIPTS_DIR="$(dirname "$MCP_DIR")/scripts"
if [ -d "$SCRIPTS_DIR" ]; then
    chmod +x "$SCRIPTS_DIR"/*.sh
    echo -e "${GREEN}✅ Permisos de scripts configurados${NC}"
fi

# Instrucciones para extensiones
echo
echo -e "${GREEN}🎉 ¡INSTALACIÓN PARA VS CODE COMPLETADA!${NC}"
echo -e "${GREEN}=======================================${NC}"
echo
echo -e "${BLUE}📝 Próximos pasos:${NC}"
echo
echo -e "${YELLOW}1. Instalar una extensión MCP en VS Code Insiders:${NC}"
echo -e "${BLUE}   • 'Cline' (recomendada) - saoudrizwan.claude-dev${NC}"
echo -e "${BLUE}   • 'Copilot MCP' - automatalabs.copilot-mcp${NC}"
echo -e "${BLUE}   • 'MCP Server Runner' - zebradev.mcp-server-runner${NC}"
echo
echo -e "${YELLOW}2. Configurar la extensión:${NC}"
echo -e "${BLUE}   • Abre VS Code Insiders${NC}"
echo -e "${BLUE}   • Ve a Extensions > busca 'Cline' o 'MCP'${NC}"
echo -e "${BLUE}   • Instala la extensión${NC}"
echo -e "${BLUE}   • Reinicia VS Code${NC}"
echo
echo -e "${YELLOW}3. Para usar manualmente:${NC}"
echo -e "${BLUE}   • Ejecuta: $MCP_DIR/start-mcp-server.sh${NC}"
echo -e "${BLUE}   • O usa: node $MCP_DIR/dist/index.js${NC}"
echo
echo -e "${GREEN}🛠️  Configuraciones creadas:${NC}"
echo -e "${BLUE}   • MCP Config: $MCP_DIR/vscode-mcp-config.json${NC}"
echo -e "${BLUE}   • VS Code Settings: $VSCODE_SETTINGS${NC}"
echo -e "${BLUE}   • Script directo: $MCP_DIR/start-mcp-server.sh${NC}"
echo
echo -e "${GREEN}🔧 Herramientas disponibles:${NC}"
echo -e "${BLUE}   • analyze_disk_usage - Análisis de disco${NC}"
echo -e "${BLUE}   • migrate_user_data - Migración segura${NC}"
echo -e "${BLUE}   • cleanup_system - Limpieza del sistema${NC}"
echo -e "${BLUE}   • check_disk_status - Estado de discos${NC}"
echo -e "${BLUE}   • get_recommendations - Recomendaciones IA${NC}"
echo -e "${BLUE}   • safe_move_applications - Gestión de apps${NC}"
echo
echo -e "${YELLOW}📋 Comandos de ejemplo una vez configurado:${NC}"
echo -e "${BLUE}   • 'Analiza mi disco y recomienda optimizaciones'${NC}"
echo -e "${BLUE}   • 'Migra Library/Caches de forma segura'${NC}" 
echo -e "${BLUE}   • 'Limpia todos los caches del sistema'${NC}"
echo -e "${BLUE}   • 'Muestra el estado de mis migraciones'${NC}"
echo
echo -e "${GREEN}✨ ¡El asistente de disco está listo para VS Code!${NC}"
