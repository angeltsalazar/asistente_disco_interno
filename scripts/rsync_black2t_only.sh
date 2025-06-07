#!/bin/bash
# RSYNC OPTIMIZADO - Solo usando BLACK2T (que funciona)
# Versión simplificada y robusta

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuración
MAC_STUDIO_IP="192.168.100.1"
MAC_STUDIO_USER="angelsalazar"
REMOTE_DISK="/Volumes/BLACK2T"
LOG_FILE="/tmp/rsync_black2t.log"

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                RSYNC OPTIMIZADO - BLACK2T                   ║${NC}"
echo -e "${CYAN}║             Transferencia directa SSH/RSYNC                 ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${YELLOW}📋 ARQUITECTURA DE DISCOS:${NC}"
echo -e "${GREEN}• BLACK2T:${NC} Almacenamiento PRINCIPAL (datos activos)"
echo -e "${BLUE}• 8TbSeries:${NC} Solo BACKUPS (automáticos desde Mac Studio)"
echo -e "${MAGENTA}• Flujo:${NC} Mac Mini → BLACK2T → 8TbSeries (backup local)"
echo

# Verificar SSH
echo -e "${BLUE}🔍 Verificando conexión SSH...${NC}"
if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "${MAC_STUDIO_USER}@${MAC_STUDIO_IP}" "echo 'OK'" > /dev/null 2>&1; then
    echo -e "${RED}❌ SSH no disponible${NC}"
    echo -e "Ejecuta primero: ${GREEN}./enable_ssh_macstudio.sh${NC}"
    exit 1
fi
echo -e "${GREEN}✅ SSH funcionando${NC}"

# Verificar disco remoto
echo -e "${BLUE}🔍 Verificando BLACK2T remoto...${NC}"
if ! ssh "${MAC_STUDIO_USER}@${MAC_STUDIO_IP}" "test -d $REMOTE_DISK && touch $REMOTE_DISK/test_write && rm $REMOTE_DISK/test_write" 2>/dev/null; then
    echo -e "${RED}❌ BLACK2T no escribible en Mac Studio${NC}"
    exit 1
fi
echo -e "${GREEN}✅ BLACK2T escribible en Mac Studio${NC}"

echo

# Función para transferir directorio
transfer_directory() {
    local source="$1"
    local dest_name="$2"
    local description="$3"
    
    if [ ! -d "$source" ]; then
        echo -e "${YELLOW}⚠️  $source no existe, saltando...${NC}"
        return 0
    fi
    
    local size=$(du -sh "$source" 2>/dev/null | cut -f1)
    echo -e "${BLUE}📁 Transfiriendo $description ($size)...${NC}"
    
    # Crear directorio remoto
    ssh "${MAC_STUDIO_USER}@${MAC_STUDIO_IP}" "mkdir -p '$REMOTE_DISK/UserContent_macmini/$dest_name'"
    
    # Transferir con rsync
    rsync -avz --progress --stats \
        "$source/" \
        "${MAC_STUDIO_USER}@${MAC_STUDIO_IP}:$REMOTE_DISK/UserContent_macmini/$dest_name/" \
        2>&1 | tee -a "$LOG_FILE"
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo -e "${GREEN}✅ $description transferido exitosamente${NC}"
        
        # Crear enlace simbólico local
        if [ ! -L "$source.moved_to_BLACK2T" ]; then
            ln -s "$REMOTE_DISK/UserContent_macmini/$dest_name" "$source.moved_to_BLACK2T"
            echo -e "${BLUE}🔗 Enlace simbólico creado${NC}"
        fi
        
        return 0
    else
        echo -e "${RED}❌ Error transfiriendo $description${NC}"
        return 1
    fi
}

# Menú principal
while true; do
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    OPCIONES RSYNC                           ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${GREEN}1) 📦 Downloads${NC}"
    echo -e "${GREEN}2) 🖼️  Imágenes (Pictures)${NC}"  
    echo -e "${GREEN}3) 🎵 Música (Music)${NC}"
    echo -e "${GREEN}4) 🎬 Videos (Movies)${NC}"
    echo -e "${GREEN}5) 📄 Documentos (Documents)${NC}"
    echo -e "${GREEN}6) 🗃️  Escritorio (Desktop)${NC}"
    echo -e "${BLUE}7) 📁 Directorio personalizado${NC}"
    echo -e "${YELLOW}8) 📊 Ver estado actual${NC}"
    echo -e "${RED}9) 🚪 Salir${NC}"
    echo
    echo -e "${CYAN}Selecciona opción (1-9): ${NC}"
    read -r choice
    echo
    
    case $choice in
        1)
            transfer_directory "$HOME/Downloads" "Downloads" "Downloads"
            ;;
        2)
            transfer_directory "$HOME/Pictures" "Pictures" "Imágenes"
            ;;
        3)
            transfer_directory "$HOME/Music" "Music" "Música"
            ;;
        4)
            transfer_directory "$HOME/Movies" "Movies" "Videos"
            ;;
        5)
            transfer_directory "$HOME/Documents" "Documents" "Documentos"
            ;;
        6)
            transfer_directory "$HOME/Desktop" "Desktop" "Escritorio"
            ;;
        7)
            echo -e "${CYAN}Ingresa la ruta completa del directorio: ${NC}"
            read -r custom_path
            if [ -d "$custom_path" ]; then
                local dirname=$(basename "$custom_path")
                transfer_directory "$custom_path" "$dirname" "$dirname"
            else
                echo -e "${RED}❌ Directorio no existe${NC}"
            fi
            ;;
        8)
            echo -e "${BLUE}📊 Estado actual:${NC}"
            echo -e "• SSH: ${GREEN}✅ Funcionando${NC}"
            echo -e "• BLACK2T remoto: ${GREEN}✅ Escribible${NC}"
            echo -e "• Log: $LOG_FILE"
            echo
            ssh "${MAC_STUDIO_USER}@${MAC_STUDIO_IP}" "ls -la '$REMOTE_DISK/UserContent_macmini/' 2>/dev/null || echo 'Aún no hay datos transferidos'"
            ;;
        9)
            echo -e "${GREEN}¡Transferencias completadas!${NC}"
            echo -e "Los datos están en: ${CYAN}$REMOTE_DISK/UserContent_macmini/${NC}"
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
