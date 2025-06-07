#!/bin/bash
# Configuración de máquina para el sistema de gestión de aplicaciones
# Este archivo permite cambiar fácilmente entre diferentes máquinas

# CONFIGURACIÓN ACTUAL
MACHINE_SUFFIX="macmini"
MACHINE_NAME="Mac Mini"

# CONFIGURACIONES DISPONIBLES:
# Para Mac Mini: MACHINE_SUFFIX="macmini"
# Para Mac Studio: MACHINE_SUFFIX="macstudio"  
# Para Mac Pro: MACHINE_SUFFIX="macpro"

# Rutas base (no cambiar)
BLACK2T_BASE="/Volumes/BLACK2T"
BACKUP_BASE="/Volumes/8TbSeries"

# Rutas calculadas automáticamente
EXTERNAL_APPS="${BLACK2T_BASE}/Applications_${MACHINE_SUFFIX}"
EXTERNAL_SAFE_APPS="${BLACK2T_BASE}/Applications_safe_${MACHINE_SUFFIX}"
BACKUP_APPS="${BACKUP_BASE}/Applications_${MACHINE_SUFFIX}"
BACKUP_SAFE_APPS="${BACKUP_BASE}/Applications_safe_backup_${MACHINE_SUFFIX}"
USER_DATA_EXTERNAL="${BLACK2T_BASE}/UserData_$(whoami)_${MACHINE_SUFFIX}"
USER_DATA_BACKUP="${BACKUP_BASE}/UserData_$(whoami)_backup_${MACHINE_SUFFIX}"

# Logs con sufijo de máquina
LOG_SUFFIX="_${MACHINE_SUFFIX}.log"

# Función para mostrar configuración actual
show_current_config() {
    echo "=== CONFIGURACIÓN ACTUAL ==="
    echo "Máquina: $MACHINE_NAME"
    echo "Sufijo: $MACHINE_SUFFIX"
    echo "Aplicaciones: $EXTERNAL_APPS"
    echo "Backup: $BACKUP_APPS"
    echo "Datos usuario: $USER_DATA_EXTERNAL"
    echo "============================"
}

# Función para cambiar configuración de máquina
change_machine_config() {
    echo "Configuraciones disponibles:"
    echo "1. Mac Mini (macmini)"
    echo "2. Mac Studio (macstudio)"
    echo "3. Mac Pro (macpro)"
    echo "4. Personalizado"
    
    read -p "Selecciona una opción (1-4): " choice
    
    case $choice in
        1)
            MACHINE_SUFFIX="macmini"
            MACHINE_NAME="Mac Mini"
            ;;
        2)
            MACHINE_SUFFIX="macstudio"
            MACHINE_NAME="Mac Studio"
            ;;
        3)
            MACHINE_SUFFIX="macpro"
            MACHINE_NAME="Mac Pro"
            ;;
        4)
            read -p "Ingresa el sufijo personalizado: " custom_suffix
            read -p "Ingresa el nombre de la máquina: " custom_name
            MACHINE_SUFFIX="$custom_suffix"
            MACHINE_NAME="$custom_name"
            ;;
        *)
            echo "Opción inválida"
            return 1
            ;;
    esac
    
    # Actualizar este archivo
    sed -i '' "s/MACHINE_SUFFIX=\".*\"/MACHINE_SUFFIX=\"$MACHINE_SUFFIX\"/" "$0"
    sed -i '' "s/MACHINE_NAME=\".*\"/MACHINE_NAME=\"$MACHINE_NAME\"/" "$0"
    
    echo "✅ Configuración actualizada para $MACHINE_NAME ($MACHINE_SUFFIX)"
    echo "⚠️  Nota: Los scripts individuales también necesitan ser actualizados"
}

# Si se ejecuta el script directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_current_config
    echo
    read -p "¿Quieres cambiar la configuración? (y/N): " change
    if [[ $change =~ ^[Yy]$ ]]; then
        change_machine_config
    fi
fi
