#!/bin/bash
# Script simple para migrar Pictures de forma manual y segura

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

SOURCE_DIR="$HOME/Pictures"
TARGET_BASE="/Volumes/BLACK2T/UserContent_macmini"
TARGET_DIR="$TARGET_BASE/Pictures"
BACKUP_DIR="$TARGET_BASE/backups/Pictures_$(date +%Y%m%d_%H%M%S)"

echo -e "${BLUE}=== MIGRACIÓN MANUAL DE PICTURES ===${NC}"
echo

# Verificar que el disco externo esté montado
if [[ ! -d "/Volumes/BLACK2T" ]]; then
    echo -e "${RED}❌ BLACK2T no está montado${NC}"
    exit 1
fi

# Verificar que Pictures tenga contenido
if [[ ! -d "$SOURCE_DIR" ]] || [[ -z "$(ls -A "$SOURCE_DIR" 2>/dev/null)" ]]; then
    echo -e "${YELLOW}⚠️ Pictures está vacío o no existe${NC}"
    exit 0
fi

# Mostrar tamaño actual
echo -e "${BLUE}📊 Analizando Pictures...${NC}"
SIZE=$(du -sh "$SOURCE_DIR" | cut -f1)
echo -e "   📁 Tamaño de Pictures: ${GREEN}$SIZE${NC}"
echo

# Listar contenido
echo -e "${BLUE}📋 Contenido de Pictures:${NC}"
ls -la "$SOURCE_DIR"
echo

read -p "¿Continuar con la migración? (y/N): " confirm
if [[ ! "$confirm" =~ ^[yY]$ ]]; then
    echo -e "${YELLOW}❌ Operación cancelada${NC}"
    exit 0
fi

echo -e "${BLUE}🔧 Creando estructura de destino...${NC}"
mkdir -p "$TARGET_DIR"
mkdir -p "$BACKUP_DIR"

echo -e "${BLUE}📦 Creando backup...${NC}"
cp -R "$SOURCE_DIR/" "$BACKUP_DIR/"
if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✅ Backup creado en: $BACKUP_DIR${NC}"
else
    echo -e "${RED}❌ Error creando backup${NC}"
    exit 1
fi

echo -e "${BLUE}📁 Moviendo Pictures...${NC}"
rsync -avh --progress "$SOURCE_DIR/" "$TARGET_DIR/"
if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✅ Pictures movido exitosamente${NC}"
    
    # Crear enlace simbólico
    echo -e "${BLUE}🔗 Creando enlace simbólico...${NC}"
    rm -rf "$SOURCE_DIR"
    ln -s "$TARGET_DIR" "$SOURCE_DIR"
    
    if [[ -L "$SOURCE_DIR" ]]; then
        echo -e "${GREEN}✅ Enlace simbólico creado exitosamente${NC}"
        echo -e "${GREEN}✅ Migración de Pictures completada${NC}"
    else
        echo -e "${RED}❌ Error creando enlace simbólico${NC}"
        # Restaurar desde backup
        cp -R "$BACKUP_DIR/" "$SOURCE_DIR/"
        exit 1
    fi
else
    echo -e "${RED}❌ Error moviendo Pictures${NC}"
    exit 1
fi

echo
echo -e "${GREEN}🎉 MIGRACIÓN COMPLETADA${NC}"
echo -e "   📁 Origen: $SOURCE_DIR (ahora enlace simbólico)"
echo -e "   📁 Destino: $TARGET_DIR"
echo -e "   💾 Backup: $BACKUP_DIR"
