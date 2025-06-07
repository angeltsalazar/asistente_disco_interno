#!/bin/bash
# Solución rápida: Reconectar 8TbSeries con permisos correctos

echo "🔄 Reconectando 8TbSeries con permisos de escritura..."
echo

# Desmontar actual
echo "1. Desmontando 8TbSeries actual..."
diskutil unmount "/Volumes/8TbSeries"

echo "2. Esperando 3 segundos..."
sleep 3

# Mostrar opciones de reconexión
echo "3. OPCIONES DE RECONEXIÓN:"
echo
echo "OPCIÓN A - Finder (MÁS FÁCIL):"
echo "1. Se abrirá Finder para conectar al servidor"
echo "2. Cuando aparezca la ventana de conexión:"
echo "   - Usuario: Angel Salazar (el que aparece en la lista)"
echo "   - O prueba: Everyone"
echo "   - O prueba: Invitado"
echo "3. Selecciona 8TbSeries"
echo
echo "OPCIÓN B - Terminal:"
echo "mount -t smbfs '//Angel Salazar@192.168.100.1/8TbSeries' /Volumes/8TbSeries"
echo

read -p "¿Abrir Finder para reconectar? (Y/n): " open_finder

if [[ ! $open_finder =~ ^[Nn]$ ]]; then
    echo "Abriendo Finder..."
    open "smb://192.168.100.1"
    
    echo
    echo "⏳ Esperando que reconectes el disco..."
    echo "Presiona Enter cuando hayas reconectado 8TbSeries..."
    read -r
    
    # Verificar si ahora funciona
    if test -w /Volumes/8TbSeries; then
        echo "🎉 ¡ÉXITO! 8TbSeries ahora es escribible"
        
        # Probar crear directorio
        echo "Probando crear directorio de prueba..."
        if mkdir -p "/Volumes/8TbSeries/UserData_$(whoami)_backup_macmini/test"; then
            echo "✅ Directorio creado exitosamente"
            rmdir "/Volumes/8TbSeries/UserData_$(whoami)_backup_macmini/test" 2>/dev/null
            rmdir "/Volumes/8TbSeries/UserData_$(whoami)_backup_macmini" 2>/dev/null
            
            echo
            echo "🚀 Ya puedes ejecutar:"
            echo "   ./scripts/manage_user_data.sh"
        else
            echo "❌ Aún no se puede crear directorios"
        fi
    else
        echo "❌ El disco sigue siendo solo lectura"
        echo
        echo "💡 Alternativas:"
        echo "1. Ejecutar: ./scripts/manage_user_data_black2t_only.sh"
        echo "2. Ejecutar: ./scripts/fix_user_permissions_macstudio.sh"
    fi
else
    echo
    echo "📋 Comandos manuales que puedes probar:"
    echo
    echo "# Opción 1: Conectar como Angel Salazar"
    echo "mount -t smbfs '//Angel\\ Salazar@192.168.100.1/8TbSeries' /Volumes/8TbSeries"
    echo
    echo "# Opción 2: Conectar como invitado"
    echo "mount -t smbfs -o guest '//192.168.100.1/8TbSeries' /Volumes/8TbSeries"
    echo
    echo "# Opción 3: Usar AppleScript"
    echo "osascript -e 'mount volume \"smb://192.168.100.1/8TbSeries\"'"
fi
