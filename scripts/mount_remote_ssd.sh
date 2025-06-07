#!/bin/bash

# Script para montar SSD remoto via Thunderbolt Bridge
# Ejecutar desde Mac Mini

echo "=========================================="
echo "  MONTAJE SSD REMOTO VIA THUNDERBOLT"
echo "=========================================="

# Configuración
MAC_STUDIO_IP="192.168.100.1"
SSD_SHARE_NAME="BLACK2T"
LOCAL_MOUNT_POINT="/Volumes/BLACK2T_Remote"
USERNAME="$(whoami)"

# Obtener información detallada del usuario
FULL_NAME=$(dscl . -read /Users/"$USERNAME" RealName 2>/dev/null | sed 's/RealName: //' | head -1)
USER_ID=$(id -u "$USERNAME")

echo "Usuario actual: $USERNAME"
echo "Nombre completo: $FULL_NAME"
echo "UID: $USER_ID"

# Función para colorear output
green() { echo -e "\033[32m$1\033[0m"; }
red() { echo -e "\033[31m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
blue() { echo -e "\033[34m$1\033[0m"; }

echo "1. VERIFICANDO CONECTIVIDAD THUNDERBOLT"
echo "=========================================="
if ping -c 2 -W 2000 "$MAC_STUDIO_IP" >/dev/null 2>&1; then
    green "✓ Mac Studio accesible via Thunderbolt ($MAC_STUDIO_IP)"
else
    red "✗ No se puede conectar a Mac Studio"
    echo "Verifica que Thunderbolt Bridge esté configurado correctamente"
    exit 1
fi

echo ""
echo "2. VERIFICANDO RECURSOS COMPARTIDOS"
echo "=========================================="
echo "Buscando recursos compartidos en Mac Studio..."
if command -v smbutil >/dev/null 2>&1; then
    available_shares=$(smbutil view //"$MAC_STUDIO_IP" 2>/dev/null | grep "Disk" | awk '{print $1}')
    if [[ -n "$available_shares" ]]; then
        green "✓ Recursos compartidos encontrados:"
        echo "$available_shares"
    else
        yellow "⚠ No se encontraron recursos compartidos o requiere autenticación"
    fi
fi

echo ""
echo "3. CREANDO PUNTO DE MONTAJE"
echo "=========================================="
if [[ ! -d "$LOCAL_MOUNT_POINT" ]]; then
    echo "Creando directorio de montaje: $LOCAL_MOUNT_POINT"
    sudo mkdir -p "$LOCAL_MOUNT_POINT"
    sudo chown "$USERNAME" "$LOCAL_MOUNT_POINT"
    green "✓ Punto de montaje creado"
else
    blue "ℹ Punto de montaje ya existe"
fi

echo ""
echo "4. MONTANDO SSD REMOTO"
echo "=========================================="
echo "Intentando montar $SSD_SHARE_NAME desde Mac Studio..."

# Método 1: SMB directo
if mount | grep -q "$LOCAL_MOUNT_POINT"; then
    yellow "⚠ Ya hay algo montado en $LOCAL_MOUNT_POINT"
    echo "¿Desmontar y volver a montar? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        sudo umount "$LOCAL_MOUNT_POINT"
        echo "Desmontado anterior"
    else
        echo "Cancelando montaje"
        exit 0
    fi
fi

# Intentar montaje
echo "Usando usuario: $USERNAME"
echo "Ingresa tu contraseña para Mac Studio:"

# Intentar con diferentes formatos de usuario
mount_attempts=(
    "//$USERNAME@$MAC_STUDIO_IP/$SSD_SHARE_NAME"
    "//\"$USERNAME\"@$MAC_STUDIO_IP/$SSD_SHARE_NAME"
    "//${USERNAME// /\\ }@$MAC_STUDIO_IP/$SSD_SHARE_NAME"
)

mounted=false
for attempt in "${mount_attempts[@]}"; do
    echo "Intentando: $attempt"
    if mount -t smbfs "$attempt" "$LOCAL_MOUNT_POINT" 2>/dev/null; then
        mounted=true
        green "✓ SSD montado exitosamente con: $attempt"
        break
    fi
done

if [[ "$mounted" == "true" ]]; then
    green "✓ SSD montado exitosamente en $LOCAL_MOUNT_POINT"
    
    # Verificar contenido
    if [[ -n "$(ls -A "$LOCAL_MOUNT_POINT" 2>/dev/null)" ]]; then
        echo ""
        echo "Contenido disponible:"
        ls -la "$LOCAL_MOUNT_POINT" | head -10
    fi
    
    # Mostrar velocidad de transferencia
    echo ""
    echo "5. PRUEBA DE VELOCIDAD"
    echo "=========================================="
    echo "Probando velocidad de lectura..."
    if command -v dd >/dev/null 2>&1; then
        test_file="$LOCAL_MOUNT_POINT/.speed_test_$$"
        if touch "$test_file" 2>/dev/null; then
            echo "Creando archivo de prueba (100MB)..."
            time dd if=/dev/zero of="$test_file" bs=1m count=100 2>/dev/null
            rm "$test_file" 2>/dev/null
        else
            yellow "⚠ No se pudo crear archivo de prueba (permisos)"
        fi
    fi
    
else
    red "✗ Error al montar SSD"
    echo ""
    echo "Posibles soluciones:"
    echo "1. Verificar que 'Compartir archivos' esté habilitado en Mac Studio"
    echo "2. Verificar que BLACK2T esté compartido"
    echo "3. Verificar credenciales de usuario"
    echo ""
    echo "Comandos manuales para probar:"
    blue "mount -t smbfs //$USERNAME@$MAC_STUDIO_IP/$SSD_SHARE_NAME $LOCAL_MOUNT_POINT"
    blue "mount -t smbfs //\"$USERNAME\"@$MAC_STUDIO_IP/$SSD_SHARE_NAME $LOCAL_MOUNT_POINT"
fi

echo ""
echo "6. INFORMACIÓN DE MONTAJE"
echo "=========================================="
if mount | grep -q "$LOCAL_MOUNT_POINT"; then
    green "✓ SSD correctamente montado"
    mount | grep "$LOCAL_MOUNT_POINT"
    echo ""
    echo "Para acceder: $LOCAL_MOUNT_POINT"
    echo "Para desmontar: sudo umount $LOCAL_MOUNT_POINT"
else
    red "✗ SSD no está montado"
fi

echo ""
echo "=========================================="
echo "  PROCESO COMPLETADO"
echo "=========================================="
