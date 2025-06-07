#!/bin/bash
# Instalador del Asistente de Administración del Disco Interno
# Configura automáticamente el sistema para uso inmediato

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                              ║${NC}"
echo -e "${CYAN}║     INSTALADOR DEL ASISTENTE DE DISCO INTERNO               ║${NC}"
echo -e "${CYAN}║                                                              ║${NC}"
echo -e "${CYAN}║   Configura automáticamente el sistema completo             ║${NC}"
echo -e "${CYAN}║                                                              ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

echo -e "${BLUE}📁 Directorio de instalación: $SCRIPT_DIR${NC}"
echo

# Verificar estructura
echo -e "${YELLOW}=== VERIFICANDO ESTRUCTURA ===${NC}"

directories=("scripts" "docs" "config" "logs" "backups" "utils" "demos")
for dir in "${directories[@]}"; do
    if [ -d "$SCRIPT_DIR/$dir" ]; then
        echo -e "${GREEN}✅ $dir/${NC}"
    else
        echo -e "${RED}❌ $dir/ - Creando...${NC}"
        mkdir -p "$SCRIPT_DIR/$dir"
    fi
done

# Dar permisos de ejecución a todos los scripts
echo -e "${YELLOW}=== CONFIGURANDO PERMISOS ===${NC}"
if [ -d "$SCRIPT_DIR/scripts" ]; then
    chmod +x "$SCRIPT_DIR/scripts"/*.sh
    echo -e "${GREEN}✅ Permisos de ejecución configurados${NC}"
else
    echo -e "${RED}❌ No se encontró directorio de scripts${NC}"
fi

# Verificar discos externos
echo -e "${YELLOW}=== VERIFICANDO DISCOS EXTERNOS ===${NC}"
if [ -d "/Volumes/BLACK2T" ]; then
    echo -e "${GREEN}✅ BLACK2T montado${NC}"
else
    echo -e "${RED}❌ BLACK2T no montado${NC}"
    echo -e "${YELLOW}   Usa disk_manager.sh para montar discos${NC}"
fi

if [ -d "/Volumes/8TbSeries" ]; then
    echo -e "${GREEN}✅ 8TbSeries montado${NC}"
else
    echo -e "${YELLOW}⚠️  8TbSeries no montado (opcional)${NC}"
fi

# Verificar configuración de máquina
echo -e "${YELLOW}=== CONFIGURACIÓN DE MÁQUINA ===${NC}"
if [ -f "$SCRIPT_DIR/scripts/machine_config.sh" ]; then
    cd "$SCRIPT_DIR/scripts"
    source machine_config.sh 2>/dev/null
    echo -e "${GREEN}✅ Configuración cargada${NC}"
    echo -e "${BLUE}   Máquina: $MACHINE_SUFFIX${NC}"
    echo -e "${BLUE}   Disco principal: BLACK2T${NC}"
else
    echo -e "${RED}❌ machine_config.sh no encontrado${NC}"
fi

# Inicializar sistema de estado si no existe
echo -e "${YELLOW}=== SISTEMA DE ESTADO ===${NC}"
STATE_FILE="$SCRIPT_DIR/config/migration_state.json"
if [ -f "$STATE_FILE" ]; then
    echo -e "${GREEN}✅ Sistema de estado ya configurado${NC}"
else
    echo -e "${BLUE}🔧 Inicializando sistema de estado...${NC}"
    if [ -f "$SCRIPT_DIR/scripts/migration_state.sh" ]; then
        cd "$SCRIPT_DIR/scripts"
        source migration_state.sh
        create_initial_state
        # Mover el archivo al directorio config
        if [ -f "migration_state.json" ]; then
            mv "migration_state.json" "$SCRIPT_DIR/config/"
            echo -e "${GREEN}✅ Sistema de estado inicializado${NC}"
        fi
    else
        echo -e "${RED}❌ migration_state.sh no encontrado${NC}"
    fi
fi

# Crear alias convenientes
echo -e "${YELLOW}=== CONFIGURANDO ALIAS ===${NC}"
ALIAS_FILE="$SCRIPT_DIR/aliases.sh"
cat > "$ALIAS_FILE" << 'EOF'
#!/bin/bash
# Alias convenientes para el Asistente de Disco Interno

ASISTENTE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Alias principales
alias asistente="cd '$ASISTENTE_DIR/scripts' && ./app_manager_master.sh"
alias migrar="cd '$ASISTENTE_DIR/scripts' && ./move_user_content.sh"
alias limpiar="cd '$ASISTENTE_DIR/scripts' && ./clean_system_caches.sh"
alias discos="cd '$ASISTENTE_DIR/scripts' && ./disk_manager.sh"
alias estado="cd '$ASISTENTE_DIR/scripts' && source migration_state.sh && show_migration_status"

# Funciones útiles
asistente_help() {
    echo "=== ALIAS DEL ASISTENTE DE DISCO INTERNO ==="
    echo "asistente  - Abrir menú principal"
    echo "migrar     - Migración integral de contenido"
    echo "limpiar    - Limpiar caches y temporales"
    echo "discos     - Gestionar discos externos"
    echo "estado     - Ver estado de migración"
    echo "asistente_help - Mostrar esta ayuda"
}

echo "✅ Alias del Asistente de Disco Interno cargados"
echo "💡 Escribe 'asistente_help' para ver comandos disponibles"
EOF

chmod +x "$ALIAS_FILE"
echo -e "${GREEN}✅ Archivo de alias creado: $ALIAS_FILE${NC}"

# Crear script de inicio rápido
echo -e "${YELLOW}=== SCRIPT DE INICIO RÁPIDO ===${NC}"
QUICK_START="$SCRIPT_DIR/inicio_rapido.sh"
cat > "$QUICK_START" << EOF
#!/bin/bash
# Inicio rápido del Asistente de Disco Interno
cd "$SCRIPT_DIR/scripts"
./app_manager_master.sh
EOF
chmod +x "$QUICK_START"
echo -e "${GREEN}✅ Script de inicio rápido creado${NC}"

# Resumen final
echo
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                    INSTALACIÓN COMPLETADA                   ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${GREEN}🎉 El Asistente de Disco Interno está listo para usar${NC}"
echo
echo -e "${BLUE}📋 FORMAS DE EJECUTAR:${NC}"
echo -e "${PURPLE}1. Script de inicio rápido:${NC}"
echo -e "   ${YELLOW}./inicio_rapido.sh${NC}"
echo
echo -e "${PURPLE}2. Menú principal directamente:${NC}"
echo -e "   ${YELLOW}cd scripts && ./app_manager_master.sh${NC}"
echo
echo -e "${PURPLE}3. Cargar alias convenientes:${NC}"
echo -e "   ${YELLOW}source aliases.sh${NC}"
echo -e "   ${YELLOW}asistente${NC}"
echo
echo -e "${BLUE}📚 DOCUMENTACIÓN:${NC}"
echo -e "   ${YELLOW}docs/README_app_manager.md${NC} - Documentación completa"
echo -e "   ${YELLOW}README.md${NC} - Guía de inicio"
echo
echo -e "${BLUE}🔧 CONFIGURACIÓN:${NC}"
echo -e "   ${YELLOW}config/migration_state.json${NC} - Estado del sistema"
echo -e "   ${YELLOW}logs/${NC} - Registros de operaciones"
echo
echo -e "${GREEN}💡 Tip: Ejecuta primero la limpieza de caches (opción 1) para liberar espacio inmediatamente${NC}"
