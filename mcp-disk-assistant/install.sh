#!/bin/bash
# Instalador automático del MCP Disk Assistant
# Configura el servidor MCP para uso con Cursor/Claude

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🖥️  Instalador MCP Disk Assistant${NC}"
echo -e "${BLUE}=================================${NC}"
echo

# Rutas
MCP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/Library/Application Support/Claude"
CONFIG_FILE="$CONFIG_DIR/claude_desktop_config.json"

echo -e "${YELLOW}📍 Directorio MCP: $MCP_DIR${NC}"

# Verificar Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js no está instalado${NC}"
    echo -e "${YELLOW}Por favor instala Node.js desde: https://nodejs.org/${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Node.js encontrado: $(node --version)${NC}"

# Verificar npm
if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ npm no está instalado${NC}"
    exit 1
fi

echo -e "${GREEN}✅ npm encontrado: $(npm --version)${NC}"

# Instalar dependencias
echo -e "${BLUE}📦 Instalando dependencias...${NC}"
cd "$MCP_DIR"
npm install

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Error instalando dependencias${NC}"
    exit 1
fi

# Compilar TypeScript
echo -e "${BLUE}🔨 Compilando proyecto...${NC}"
npm run build

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Error compilando proyecto${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Proyecto compilado exitosamente${NC}"

# Crear directorio de configuración si no existe
mkdir -p "$CONFIG_DIR"

# Verificar si ya existe configuración
EXISTING_CONFIG=""
if [ -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}⚠️  Configuración existente encontrada${NC}"
    EXISTING_CONFIG=$(cat "$CONFIG_FILE")
fi

# Crear configuración MCP
echo -e "${BLUE}⚙️  Configurando MCP server...${NC}"

if [ -z "$EXISTING_CONFIG" ]; then
    # Crear nueva configuración
    cat > "$CONFIG_FILE" << EOF
{
  "mcpServers": {
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
else
    # Fusionar con configuración existente
    echo -e "${YELLOW}🔄 Fusionando con configuración existente...${NC}"
    
    # Backup de configuración existente
    cp "$CONFIG_FILE" "$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Usar jq si está disponible, sino manual
    if command -v jq &> /dev/null; then
        echo "$EXISTING_CONFIG" | jq --arg cmd "node" --arg args "$MCP_DIR/dist/index.js" --arg cwd "$(dirname "$MCP_DIR")" --arg env_path "$(dirname "$MCP_DIR")" '
        .mcpServers["disk-assistant"] = {
          "command": $cmd,
          "args": [$args],
          "cwd": $cwd,
          "env": {
            "DISK_ASSISTANT_BASE_PATH": $env_path
          }
        }' > "$CONFIG_FILE"
    else
        echo -e "${YELLOW}⚠️  jq no disponible, configuración manual requerida${NC}"
        echo -e "${BLUE}Agregar esta sección a $CONFIG_FILE:${NC}"
        echo
        cat << EOF
{
  "mcpServers": {
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
        echo
        echo -e "${YELLOW}Presiona Enter cuando hayas agregado la configuración...${NC}"
        read
    fi
fi

# Verificar configuración
echo -e "${BLUE}🔍 Verificando configuración...${NC}"
if [ -f "$CONFIG_FILE" ]; then
    echo -e "${GREEN}✅ Archivo de configuración creado: $CONFIG_FILE${NC}"
    
    # Mostrar configuración
    echo -e "${BLUE}📄 Configuración actual:${NC}"
    cat "$CONFIG_FILE" | head -20
    echo
else
    echo -e "${RED}❌ Error creando configuración${NC}"
    exit 1
fi

# Verificar permisos de scripts
echo -e "${BLUE}🔐 Verificando permisos de scripts...${NC}"
SCRIPTS_DIR="$(dirname "$MCP_DIR")/scripts"
if [ -d "$SCRIPTS_DIR" ]; then
    chmod +x "$SCRIPTS_DIR"/*.sh
    echo -e "${GREEN}✅ Permisos de scripts configurados${NC}"
else
    echo -e "${YELLOW}⚠️  Directorio de scripts no encontrado: $SCRIPTS_DIR${NC}"
fi

# Test rápido del servidor
echo -e "${BLUE}🧪 Probando servidor MCP...${NC}"
timeout 5s node "$MCP_DIR/dist/index.js" <<< '{"jsonrpc": "2.0", "method": "tools/list", "id": 1}' 2>/dev/null && echo -e "${GREEN}✅ Servidor MCP responde correctamente${NC}" || echo -e "${YELLOW}⚠️  Test del servidor incompleto (normal en instalación)${NC}"

# Instrucciones finales
echo
echo -e "${GREEN}🎉 ¡INSTALACIÓN COMPLETADA!${NC}"
echo -e "${GREEN}=========================${NC}"
echo
echo -e "${BLUE}📝 Próximos pasos:${NC}"
echo -e "${YELLOW}1. Reinicia Cursor/Claude completamente${NC}"
echo -e "${YELLOW}2. El asistente estará disponible como 'disk-assistant'${NC}"
echo -e "${YELLOW}3. Puedes usar comandos como:${NC}"
echo -e "${BLUE}   • 'Analiza mi disco y recomienda optimizaciones'${NC}"
echo -e "${BLUE}   • 'Migra mi carpeta Downloads de forma segura'${NC}"
echo -e "${BLUE}   • 'Limpia todos los caches del sistema'${NC}"
echo -e "${BLUE}   • 'Muestra el estado de mis migraciones'${NC}"
echo
echo -e "${GREEN}🛠️  Herramientas disponibles:${NC}"
echo -e "${BLUE}   • analyze_disk_usage - Análisis de disco${NC}"
echo -e "${BLUE}   • migrate_user_data - Migración segura${NC}"
echo -e "${BLUE}   • cleanup_system - Limpieza del sistema${NC}"
echo -e "${BLUE}   • check_disk_status - Estado de discos${NC}"
echo -e "${BLUE}   • get_recommendations - Recomendaciones IA${NC}"
echo -e "${BLUE}   • safe_move_applications - Gestión de apps${NC}"
echo
echo -e "${YELLOW}📍 Archivos de configuración:${NC}"
echo -e "${BLUE}   • Config: $CONFIG_FILE${NC}"
echo -e "${BLUE}   • Logs: $(dirname "$MCP_DIR")/logs/${NC}"
echo -e "${BLUE}   • Scripts: $(dirname "$MCP_DIR")/scripts/${NC}"
echo
echo -e "${GREEN}✨ ¡El asistente de disco ahora está integrado en tu chat!${NC}"
