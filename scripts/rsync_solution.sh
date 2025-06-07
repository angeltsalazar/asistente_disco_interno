#!/bin/bash
# Solución RSYNC: Evitar problemas SMB usando rsync directo sobre SSH
# Esta es una solución más eficiente y confiable que SMB

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuración
MAC_STUDIO_IP="192.168.100.1"
MAC_STUDIO_USER="angelsalazar"  # Usuario del Mac Studio (verificado funcionando)
LOCAL_USER=$(whoami)
LOG_FILE="$HOME/Documents/scripts/rsync_solution_macmini.log"

# Rutas remotas (en Mac Studio)
REMOTE_BLACK2T="/Volumes/BLACK2T"
REMOTE_8TBSERIES="/Volumes/8TbSeries"

# Rutas locales de trabajo (temporales)
LOCAL_WORK_DIR="/tmp/rsync_user_data"
LOCAL_BACKUP_DIR="/tmp/rsync_backup"

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║              SOLUCIÓN RSYNC PARA DATOS USUARIO              ║${NC}"
echo -e "${CYAN}║           Evita problemas SMB usando SSH/RSYNC              ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

# Función para logging
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo -e "$1"
}

# Verificar conectividad SSH
check_ssh_connection() {
    log_message "${BLUE}🔍 Verificando conexión SSH...${NC}"
    
    if ssh -o ConnectTimeout=5 -o BatchMode=yes "${MAC_STUDIO_USER}@${MAC_STUDIO_IP}" "echo 'test'" 2>/dev/null; then
        log_message "${GREEN}✅ SSH conectado exitosamente${NC}"
        return 0
    else
        log_message "${RED}❌ SSH no disponible${NC}"
        echo -e "${YELLOW}Para habilitar SSH, ejecuta primero:${NC}"
        echo -e "${GREEN}./enable_ssh_macstudio.sh${NC}"
        echo
        return 1
    fi
}

# Configurar SSH en Mac Studio
setup_ssh_instructions() {
    echo -e "${YELLOW}📋 CONFIGURACIÓN SSH EN MAC STUDIO:${NC}"
    echo
    echo -e "${BLUE}PASO 1: Habilitar SSH en Mac Studio${NC}"
    echo "1. Ve a: Preferencias del Sistema > Compartir"
    echo "2. Activa: 'Acceso remoto (SSH)'"
    echo "3. Configura: 'Permitir acceso a: Solo estos usuarios'"
    echo "4. Agrega el usuario 'angel' o 'Todos los usuarios'"
    echo
    echo -e "${BLUE}PASO 2: Verificar desde Mac Mini${NC}"
    echo "ssh ${MAC_STUDIO_USER}@${MAC_STUDIO_IP}"
    echo
    echo -e "${BLUE}PASO 3: (Opcional) Configurar clave SSH${NC}"
    echo "ssh-keygen -t rsa"
    echo "ssh-copy-id ${MAC_STUDIO_USER}@${MAC_STUDIO_IP}"
    echo
}

# Verificar discos remotos
check_remote_disks() {
    log_message "${BLUE}🔍 Verificando discos en Mac Studio...${NC}"
    
    local disks_info=$(ssh "${MAC_STUDIO_USER}@${MAC_STUDIO_IP}" "df -h | grep -E '(BLACK2T|8TbSeries)'; ls -la /Volumes/ | grep -E '(BLACK2T|8TbSeries)'" 2>/dev/null)
    
    if [ -n "$disks_info" ]; then
        log_message "${GREEN}✅ Discos remotos detectados:${NC}"
        echo "$disks_info"
        return 0
    else
        log_message "${RED}❌ No se pueden verificar discos remotos${NC}"
        return 1
    fi
}

# Función para mover directorio usando rsync
rsync_move_directory() {
    local source_path="$1"
    local relative_path="$2"
    local target_disk="$3"  # "BLACK2T" o "8TbSeries"
    
    if [ ! -d "$source_path" ]; then
        log_message "${YELLOW}⚠️  $source_path no existe${NC}"
        return 1
    fi
    
    local dir_size=$(du -sh "$source_path" 2>/dev/null | cut -f1)
    log_message "${BLUE}📦 Procesando $relative_path ($dir_size)...${NC}"
    
    # Configurar rutas remotas
    local remote_target=""
    local remote_backup=""
    
    if [ "$target_disk" = "BLACK2T" ]; then
        remote_target="${MAC_STUDIO_USER}@${MAC_STUDIO_IP}:${REMOTE_BLACK2T}/UserData_${LOCAL_USER}_macmini/$relative_path"
        remote_backup="${MAC_STUDIO_USER}@${MAC_STUDIO_IP}:${REMOTE_8TBSERIES}/UserData_${LOCAL_USER}_backup_macmini/$relative_path"
    else
        log_message "${RED}❌ Disco $target_disk no soportado${NC}"
        return 1
    fi
    
    # Crear directorios remotos
    log_message "${BLUE}📁 Creando estructura remota...${NC}"
    ssh "${MAC_STUDIO_USER}@${MAC_STUDIO_IP}" "mkdir -p '$(dirname "${REMOTE_BLACK2T}/UserData_${LOCAL_USER}_macmini/$relative_path")'" 2>/dev/null
    ssh "${MAC_STUDIO_USER}@${MAC_STUDIO_IP}" "mkdir -p '$(dirname "${REMOTE_8TBSERIES}/UserData_${LOCAL_USER}_backup_macmini/$relative_path")'" 2>/dev/null
    
    # PASO 1: Crear backup usando rsync
    log_message "${BLUE}💾 Creando backup con rsync...${NC}"
    if rsync -avz --progress "$source_path/" "$remote_backup/" 2>/dev/null; then
        log_message "${GREEN}✅ Backup creado exitosamente${NC}"
    else
        log_message "${RED}❌ Error creando backup${NC}"
        return 1
    fi
    
    # PASO 2: Mover datos principales usando rsync
    log_message "${BLUE}📤 Moviendo datos principales...${NC}"
    if rsync -avz --progress --remove-source-files "$source_path/" "$remote_target/" 2>/dev/null; then
        log_message "${GREEN}✅ Datos movidos exitosamente${NC}"
        
        # Limpiar directorios vacíos locales
        find "$source_path" -type d -empty -delete 2>/dev/null
        
        # PASO 3: Crear enlace simbólico local
        if [ ! -d "$source_path" ]; then
            # Crear directorio local temporal para montar
            mkdir -p "$LOCAL_WORK_DIR/$relative_path"
            ln -s "$LOCAL_WORK_DIR/$relative_path" "$source_path" 2>/dev/null
            
            log_message "${YELLOW}📋 Datos movidos a Mac Studio. Para acceder:${NC}"
            log_message "${BLUE}   rsync -avz '$remote_target/' '$LOCAL_WORK_DIR/$relative_path/'${NC}"
        fi
        
        return 0
    else
        log_message "${RED}❌ Error moviendo datos principales${NC}"
        return 1
    fi
}

# Función para sincronizar datos de vuelta (acceso)
sync_data_from_remote() {
    local relative_path="$1"
    local direction="$2"  # "download" o "upload"
    
    local remote_path="${MAC_STUDIO_USER}@${MAC_STUDIO_IP}:${REMOTE_BLACK2T}/UserData_${LOCAL_USER}_macmini/$relative_path"
    local local_path="$LOCAL_WORK_DIR/$relative_path"
    
    mkdir -p "$(dirname "$local_path")"
    
    if [ "$direction" = "download" ]; then
        log_message "${BLUE}⬇️  Descargando $relative_path desde Mac Studio...${NC}"
        rsync -avz --progress "$remote_path/" "$local_path/"
    elif [ "$direction" = "upload" ]; then
        log_message "${BLUE}⬆️  Subiendo $relative_path a Mac Studio...${NC}"
        rsync -avz --progress "$local_path/" "$remote_path/"
    fi
}

# Función para mostrar datos disponibles remotamente
show_remote_data() {
    log_message "${BLUE}📊 Datos disponibles en Mac Studio:${NC}"
    
    local remote_data=$(ssh "${MAC_STUDIO_USER}@${MAC_STUDIO_IP}" "find '${REMOTE_BLACK2T}/UserData_${LOCAL_USER}_macmini' -maxdepth 2 -type d 2>/dev/null" 2>/dev/null)
    
    if [ -n "$remote_data" ]; then
        echo "$remote_data" | while read -r dir; do
            local size=$(ssh "${MAC_STUDIO_USER}@${MAC_STUDIO_IP}" "du -sh '$dir' 2>/dev/null | cut -f1" 2>/dev/null)
            local basename=$(basename "$dir")
            echo -e "${GREEN}  ✓ $basename: $size${NC}"
        done
    else
        log_message "${YELLOW}No hay datos remotos encontrados${NC}"
    fi
}

# Menú principal
main_menu() {
    echo -e "${YELLOW}🛠️  OPCIONES DISPONIBLES:${NC}"
    echo "1. 🔧 Configurar SSH (instrucciones)"
    echo "2. ✅ Verificar conexión SSH"
    echo "3. 📦 Mover Downloads usando rsync"
    echo "4. 🎵 Mover bibliotecas de medios"
    echo "5. 📁 Mover directorio específico"
    echo "6. ⬇️  Sincronizar datos desde Mac Studio"
    echo "7. 📊 Ver datos remotos disponibles"
    echo "8. 🔄 Sincronizar cambios locales"
    echo "9. 🚪 Salir"
    
    read -p "Selecciona opción (1-9): " choice
    
    case $choice in
        1)
            setup_ssh_instructions
            echo
            echo -e "${BLUE}Presiona Enter cuando hayas configurado SSH...${NC}"
            read -r
            ;;
        2)
            if check_ssh_connection; then
                check_remote_disks
            else
                echo -e "${RED}Configura SSH primero (opción 1)${NC}"
            fi
            ;;
        3)
            if check_ssh_connection; then
                if [ -d "$HOME/Downloads" ]; then
                    rsync_move_directory "$HOME/Downloads" "Downloads" "BLACK2T"
                else
                    log_message "${YELLOW}Directorio Downloads no existe${NC}"
                fi
            else
                echo -e "${RED}SSH no disponible${NC}"
            fi
            ;;
        4)
            if check_ssh_connection; then
                # Mover bibliotecas de medios
                [ -d "$HOME/Movies" ] && rsync_move_directory "$HOME/Movies" "Movies" "BLACK2T"
                [ -d "$HOME/Music/Logic" ] && rsync_move_directory "$HOME/Music/Logic" "Music/Logic" "BLACK2T"
                [ -d "$HOME/Pictures/Photos Library.photoslibrary" ] && rsync_move_directory "$HOME/Pictures/Photos Library.photoslibrary" "Pictures/Photos Library.photoslibrary" "BLACK2T"
            else
                echo -e "${RED}SSH no disponible${NC}"
            fi
            ;;
        5)
            if check_ssh_connection; then
                echo -e "${YELLOW}Directorios disponibles:${NC}"
                ls -la "$HOME" | grep "^d" | awk '{print $9}' | grep -v "^\.$\|^\.\.$"
                echo
                read -p "Nombre del directorio: " dir_name
                if [ -d "$HOME/$dir_name" ]; then
                    rsync_move_directory "$HOME/$dir_name" "$dir_name" "BLACK2T"
                else
                    log_message "${RED}Directorio no encontrado${NC}"
                fi
            else
                echo -e "${RED}SSH no disponible${NC}"
            fi
            ;;
        6)
            if check_ssh_connection; then
                echo -e "${YELLOW}¿Qué datos quieres sincronizar?${NC}"
                read -p "Nombre del directorio: " dir_name
                sync_data_from_remote "$dir_name" "download"
                log_message "${GREEN}Datos sincronizados en: $LOCAL_WORK_DIR/$dir_name${NC}"
            else
                echo -e "${RED}SSH no disponible${NC}"
            fi
            ;;
        7)
            if check_ssh_connection; then
                show_remote_data
            else
                echo -e "${RED}SSH no disponible${NC}"
            fi
            ;;
        8)
            if check_ssh_connection; then
                echo -e "${YELLOW}¿Qué directorio subir?${NC}"
                read -p "Nombre del directorio: " dir_name
                if [ -d "$LOCAL_WORK_DIR/$dir_name" ]; then
                    sync_data_from_remote "$dir_name" "upload"
                else
                    log_message "${RED}Directorio local no encontrado${NC}"
                fi
            else
                echo -e "${RED}SSH no disponible${NC}"
            fi
            ;;
        9)
            log_message "${BLUE}Saliendo...${NC}"
            exit 0
            ;;
        *)
            log_message "${RED}Opción inválida${NC}"
            ;;
    esac
}

# Función principal
main() {
    # Crear directorio de trabajo
    mkdir -p "$LOCAL_WORK_DIR"
    mkdir -p "$LOCAL_BACKUP_DIR"
    
    while true; do
        echo
        main_menu
        echo
        echo -e "${BLUE}Presiona Enter para continuar...${NC}"
        read -r
        clear
    done
}

# Mostrar información inicial
echo -e "${YELLOW}💡 VENTAJAS DE ESTA SOLUCIÓN:${NC}"
echo -e "${GREEN}✅ No depende de permisos SMB${NC}"
echo -e "${GREEN}✅ Transferencias más rápidas${NC}"
echo -e "${GREEN}✅ Mejor control de errores${NC}"
echo -e "${GREEN}✅ Compresión automática${NC}"
echo -e "${GREEN}✅ Progreso visible${NC}"
echo -e "${GREEN}✅ Backups automáticos${NC}"
echo

echo -e "${YELLOW}📋 REQUISITOS:${NC}"
echo -e "${BLUE}1. SSH habilitado en Mac Studio${NC}"
echo -e "${BLUE}2. Usuario 'angel' con acceso SSH${NC}"
echo -e "${BLUE}3. Discos BLACK2T y 8TbSeries montados en Mac Studio${NC}"
echo

# Ejecutar menú principal
main
