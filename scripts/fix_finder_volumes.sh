#!/bin/bash
# Script para hacer que los volúmenes SMB aparezcan correctamente en Finder
# Autor: Script de corrección de volúmenes en Finder
# Fecha: $(date)

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}=== CORRECCIÓN DE VOLÚMENES EN FINDER ===${NC}"
echo

# Función para encontrar el punto de montaje real de un disco
find_real_mount_point() {
    local disk_name="$1"
    
    # Buscar en mount por SMB primero
    local smb_mount=$(mount | grep -i "/$disk_name on" | awk '{print $3}' | head -1)
    if [ -n "$smb_mount" ] && [ -d "$smb_mount" ]; then
        echo "$smb_mount"
        return 0
    fi
    
    # Buscar variaciones del nombre (-1, -2, etc.)
    for suffix in "" "-1" "-2" "-3"; do
        local path="/Volumes/${disk_name}${suffix}"
        if [ -d "$path" ] && [ "$(ls -A "$path" 2>/dev/null)" ]; then
            echo "$path"
            return 0
        fi
    done
    
    return 1
}

# Verificar estado actual
echo -e "${CYAN}1. Estado actual de volúmenes:${NC}"
echo -e "${BLUE}Volúmenes montados:${NC}"
mount | grep -E "(BLACK2T|8TbSeries)" | while read line; do
    echo "   $line"
done
echo

echo -e "${BLUE}Directorios en /Volumes:${NC}"
ls -la /Volumes/ | grep -E "(BLACK2T|8TbSeries)" | while read line; do
    echo "   $line"
done
echo

# Detectar puntos de montaje
BLACK2T_MOUNT=$(find_real_mount_point "BLACK2T")
SERIES8TB_MOUNT=$(find_real_mount_point "8TbSeries")

echo -e "${CYAN}2. Puntos de montaje detectados:${NC}"
if [ -n "$BLACK2T_MOUNT" ]; then
    echo -e "${GREEN}✅ BLACK2T: $BLACK2T_MOUNT${NC}"
else
    echo -e "${RED}❌ BLACK2T: No encontrado${NC}"
fi

if [ -n "$SERIES8TB_MOUNT" ]; then
    echo -e "${GREEN}✅ 8TbSeries: $SERIES8TB_MOUNT${NC}"
else
    echo -e "${RED}❌ 8TbSeries: No encontrado${NC}"
fi
echo

# Opciones para el usuario
echo -e "${CYAN}3. Opciones disponibles:${NC}"
echo "1. Abrir volúmenes en Finder"
echo "2. Reiniciar Finder"
echo "3. Crear alias en el escritorio"
echo "4. Verificar configuración de Finder"
echo "5. Mostrar directorios vacíos problemáticos"
echo "6. Salir"
echo

while true; do
    read -p "Selecciona una opción (1-6): " choice
    case $choice in
        1)
            echo -e "${BLUE}Abriendo volúmenes en Finder...${NC}"
            if [ -n "$BLACK2T_MOUNT" ]; then
                open "$BLACK2T_MOUNT"
                echo -e "${GREEN}✅ Abierto BLACK2T${NC}"
            fi
            if [ -n "$SERIES8TB_MOUNT" ]; then
                open "$SERIES8TB_MOUNT"
                echo -e "${GREEN}✅ Abierto 8TbSeries${NC}"
            fi
            ;;
        2)
            echo -e "${BLUE}Reiniciando Finder...${NC}"
            killall Finder
            sleep 2
            echo -e "${GREEN}✅ Finder reiniciado${NC}"
            ;;
        3)
            echo -e "${BLUE}Creando alias en el escritorio...${NC}"
            if [ -n "$BLACK2T_MOUNT" ]; then
                ln -sf "$BLACK2T_MOUNT" "$HOME/Desktop/BLACK2T"
                echo -e "${GREEN}✅ Alias creado para BLACK2T${NC}"
            fi
            if [ -n "$SERIES8TB_MOUNT" ]; then
                ln -sf "$SERIES8TB_MOUNT" "$HOME/Desktop/8TbSeries"
                echo -e "${GREEN}✅ Alias creado para 8TbSeries${NC}"
            fi
            ;;
        4)
            echo -e "${BLUE}Configuración actual de Finder:${NC}"
            echo -e "Mostrar discos externos en escritorio: $(defaults read com.apple.finder ShowExternalHardDrivesOnDesktop 2>/dev/null || echo 'No establecido')"
            echo -e "Mostrar servidores montados en escritorio: $(defaults read com.apple.finder ShowMountedServersOnDesktop 2>/dev/null || echo 'No establecido')"
            echo -e "Mostrar discos duros en escritorio: $(defaults read com.apple.finder ShowHardDrivesOnDesktop 2>/dev/null || echo 'No establecido')"
            echo
            echo -e "${YELLOW}Para habilitar la visualización de volúmenes de red:${NC}"
            echo "defaults write com.apple.finder ShowMountedServersOnDesktop -bool true"
            echo "killall Finder"
            ;;
        5)
            echo -e "${BLUE}Directorios vacíos problemáticos:${NC}"
            for dir in "/Volumes/BLACK2T" "/Volumes/8TbSeries"; do
                if [ -d "$dir" ]; then
                    size=$(du -s "$dir" 2>/dev/null | awk '{print $1}')
                    if [ "$size" = "0" ]; then
                        echo -e "${YELLOW}⚠️  $dir está vacío y puede causar problemas${NC}"
                        echo -e "${BLUE}   Para eliminarlo (requiere sudo): sudo rmdir '$dir'${NC}"
                    else
                        echo -e "${GREEN}✅ $dir tiene contenido${NC}"
                    fi
                else
                    echo -e "${GREEN}✅ $dir no existe${NC}"
                fi
            done
            ;;
        6)
            echo -e "${BLUE}Saliendo...${NC}"
            break
            ;;
        *)
            echo -e "${RED}Opción inválida. Usa 1-6.${NC}"
            ;;
    esac
    echo
done
