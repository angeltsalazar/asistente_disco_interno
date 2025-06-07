#!/bin/bash
# SCRIPT DE BACKUP LOCAL - MAC STUDIO
# BLACK2T → 8TbSeries (solo backups automáticos)
# EJECUTAR SOLO EN MAC STUDIO

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuración
SOURCE_DISK="/Volumes/BLACK2T"
BACKUP_DISK="/Volumes/8TbSeries"
BACKUP_BASE="$BACKUP_DISK/UserData_backup_macmini"
LOG_FILE="/tmp/backup_black2t_to_8tb.log"
DATE_STAMP=$(date '+%Y%m%d_%H%M%S')

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                 BACKUP LOCAL MAC STUDIO                     ║${NC}"
echo -e "${CYAN}║              BLACK2T → 8TbSeries (BACKUPS)                  ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${YELLOW}⚠️  IMPORTANTE: Este script debe ejecutarse SOLO en Mac Studio${NC}"
echo -e "${BLUE}📋 Propósito: Crear backups de BLACK2T en 8TbSeries${NC}"
echo

# Verificar que estamos en Mac Studio
CURRENT_HOST=$(hostname)
if [[ "$CURRENT_HOST" != *"Mac-Studio"* ]]; then
    echo -e "${RED}❌ Error: Este script debe ejecutarse en Mac Studio${NC}"
    echo -e "${YELLOW}Hostname actual: $CURRENT_HOST${NC}"
    exit 1
fi

# Verificar discos
echo -e "${BLUE}🔍 Verificando discos...${NC}"

if [ ! -d "$SOURCE_DISK" ]; then
    echo -e "${RED}❌ BLACK2T no montado en: $SOURCE_DISK${NC}"
    exit 1
fi

if [ ! -d "$BACKUP_DISK" ]; then
    echo -e "${RED}❌ 8TbSeries no montado en: $BACKUP_DISK${NC}"
    exit 1
fi

# Verificar permisos de escritura
if ! touch "$BACKUP_DISK/test_write" 2>/dev/null; then
    echo -e "${RED}❌ 8TbSeries no es escribible${NC}"
    echo -e "${YELLOW}Ejecuta: sudo chown -R $(whoami):staff '$BACKUP_DISK'${NC}"
    exit 1
fi
rm -f "$BACKUP_DISK/test_write"

echo -e "${GREEN}✅ Ambos discos disponibles y escribibles${NC}"
echo

# Crear estructura de backup
echo -e "${BLUE}📁 Creando estructura de backup...${NC}"
mkdir -p "$BACKUP_BASE"
mkdir -p "$BACKUP_BASE/current"
mkdir -p "$BACKUP_BASE/snapshots"

# Función para backup incremental
backup_directory() {
    local source="$1"
    local dest_name="$2"
    local description="$3"
    
    if [ ! -d "$source" ]; then
        echo -e "${YELLOW}⚠️  $source no existe, saltando...${NC}"
        return 0
    fi
    
    local size=$(du -sh "$source" 2>/dev/null | cut -f1)
    echo -e "${BLUE}📦 Backup $description ($size)...${NC}"
    
    local backup_dest="$BACKUP_BASE/current/$dest_name"
    local snapshot_dest="$BACKUP_BASE/snapshots/${dest_name}_${DATE_STAMP}"
    
    # Backup incremental con rsync
    rsync -avz --delete --progress \
        "$source/" \
        "$backup_dest/" \
        2>&1 | tee -a "$LOG_FILE"
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo -e "${GREEN}✅ $description backup completado${NC}"
        
        # Crear snapshot
        echo -e "${BLUE}📸 Creando snapshot...${NC}"
        rsync -avz --progress \
            "$backup_dest/" \
            "$snapshot_dest/" \
            2>&1 | tee -a "$LOG_FILE"
        
        return 0
    else
        echo -e "${RED}❌ Error en backup de $description${NC}"
        return 1
    fi
}

# Menú de opciones
while true; do
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                  OPCIONES DE BACKUP                         ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${GREEN}1) 🔄 Backup completo UserContent_macmini${NC}"
    echo -e "${GREEN}2) 📦 Backup solo Downloads${NC}"
    echo -e "${GREEN}3) 🖼️  Backup solo Pictures${NC}"
    echo -e "${GREEN}4) 📄 Backup solo Documents${NC}"
    echo -e "${BLUE}5) 📊 Ver estado de backups${NC}"
    echo -e "${BLUE}6) 🧹 Limpiar snapshots antiguos${NC}"
    echo -e "${YELLOW}7) ⚙️  Configurar backup automático${NC}"
    echo -e "${RED}8) 🚪 Salir${NC}"
    echo
    echo -e "${CYAN}Selecciona opción (1-8): ${NC}"
    read -r choice
    echo
    
    case $choice in
        1)
            backup_directory "$SOURCE_DISK/UserContent_macmini" "UserContent_macmini" "Contenido completo"
            ;;
        2)
            backup_directory "$SOURCE_DISK/UserContent_macmini/Downloads" "Downloads" "Downloads"
            ;;
        3)
            backup_directory "$SOURCE_DISK/UserContent_macmini/Pictures" "Pictures" "Pictures"
            ;;
        4)
            backup_directory "$SOURCE_DISK/UserContent_macmini/Documents" "Documents" "Documents"
            ;;
        5)
            echo -e "${BLUE}📊 Estado de backups:${NC}"
            echo
            echo -e "${YELLOW}Backups actuales:${NC}"
            ls -la "$BACKUP_BASE/current/" 2>/dev/null || echo "No hay backups"
            echo
            echo -e "${YELLOW}Snapshots disponibles:${NC}"
            ls -la "$BACKUP_BASE/snapshots/" 2>/dev/null || echo "No hay snapshots"
            echo
            echo -e "${YELLOW}Espacio usado:${NC}"
            du -sh "$BACKUP_BASE" 2>/dev/null || echo "No calculable"
            ;;
        6)
            echo -e "${BLUE}🧹 Limpiando snapshots antiguos (>30 días)...${NC}"
            find "$BACKUP_BASE/snapshots" -type d -mtime +30 -exec rm -rf {} \; 2>/dev/null
            echo -e "${GREEN}✅ Limpieza completada${NC}"
            ;;
        7)
            echo -e "${YELLOW}⚙️  Para configurar backup automático:${NC}"
            echo -e "1. Abre Terminal en Mac Studio"
            echo -e "2. Ejecuta: ${GREEN}crontab -e${NC}"
            echo -e "3. Agrega: ${CYAN}0 2 * * * $PWD/$(basename $0)${NC}"
            echo -e "4. Esto ejecutará backup diario a las 2 AM"
            ;;
        8)
            echo -e "${GREEN}¡Backups completados!${NC}"
            echo -e "Log: $LOG_FILE"
            exit 0
            ;;
        *)
            echo -e "${RED}Opción no válida${NC}"
            ;;
    esac
    
    echo
    echo -e "${YELLOW}Presiona Enter para continuar...${NC}"
    read
    clear
done
