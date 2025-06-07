#!/bin/bash
# Script para solucionar el problema de permisos en el disco 8TbSeries
# El disco se monta como solo lectura y necesitamos permisos de escritura

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║              SOLUCION PERMISOS 8TbSeries                    ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

echo -e "${YELLOW}🔍 DIAGNÓSTICO DEL PROBLEMA:${NC}"
echo -e "${RED}El disco 8TbSeries está montado como SOLO LECTURA${NC}"
echo -e "${BLUE}Esto impide crear directorios de backup${NC}"
echo

echo -e "${YELLOW}📊 ESTADO ACTUAL:${NC}"
echo -e "${GREEN}✅ BLACK2T: $(test -w /Volumes/BLACK2T && echo "ESCRIBIBLE" || echo "NO ESCRIBIBLE")${NC}"
echo -e "${RED}❌ 8TbSeries: $(test -w /Volumes/8TbSeries && echo "ESCRIBIBLE" || echo "NO ESCRIBIBLE")${NC}"
echo

echo -e "${YELLOW}🛠️  SOLUCIONES DISPONIBLES:${NC}"
echo
echo -e "${BLUE}OPCIÓN 1: Remontar el disco con permisos de escritura${NC}"
echo "1. Desmontar 8TbSeries"
echo "2. Reconectar desde Finder con credenciales apropiadas"
echo

echo -e "${BLUE}OPCIÓN 2: Usar solo BLACK2T (temporalmente)${NC}"
echo "1. Modificar script para usar solo BLACK2T"
echo "2. Crear backups en subdirectorio de BLACK2T"
echo

echo -e "${BLUE}OPCIÓN 3: Verificar configuración en Mac Studio${NC}"
echo "1. Revisar permisos de compartir archivos"
echo "2. Asegurar permisos de escritura para tu usuario"
echo

echo -e "${YELLOW}¿Qué solución quieres intentar?${NC}"
echo "1. 🔄 Remontar 8TbSeries (RECOMENDADO)"
echo "2. ⚡ Usar solo BLACK2T (solución rápida)"
echo "3. 🔧 Manual: Instrucciones para Mac Studio"
echo "4. 🔍 Solo diagnóstico (salir)"

read -p "Selecciona opción (1-4): " choice

case $choice in
    1)
        echo -e "${BLUE}🔄 Remontando 8TbSeries...${NC}"
        echo
        echo -e "${YELLOW}Paso 1: Desmontando disco actual${NC}"
        diskutil unmount "/Volumes/8TbSeries"
        
        echo -e "${YELLOW}Paso 2: Abriendo Finder para reconectar${NC}"
        open "smb://192.168.100.1"
        
        echo -e "${GREEN}✅ Se abrió Finder. Ahora:${NC}"
        echo "1. Conecta al servidor 192.168.100.1"
        echo "2. Ingresa tu usuario y contraseña"
        echo "3. Selecciona el disco 8TbSeries"
        echo "4. Asegúrate de tener permisos de escritura"
        echo
        echo -e "${BLUE}Presiona Enter cuando hayas reconectado el disco...${NC}"
        read -r
        
        # Verificar si ahora es escribible
        if test -w /Volumes/8TbSeries; then
            echo -e "${GREEN}🎉 ¡ÉXITO! 8TbSeries ahora es escribible${NC}"
        else
            echo -e "${RED}❌ El disco sigue siendo solo lectura${NC}"
            echo -e "${YELLOW}Prueba la Opción 2 o 3${NC}"
        fi
        ;;
        
    2)
        echo -e "${BLUE}⚡ Configurando uso solo de BLACK2T...${NC}"
        
        # Crear script modificado
        cat > "/tmp/manage_user_data_black2t_only.sh" << 'EOF'
#!/bin/bash
# Script modificado para usar solo BLACK2T cuando 8TbSeries no es escribible

# Detectar BLACK2T
BLACK2T_MOUNT="/Volumes/BLACK2T"

if [ ! -w "$BLACK2T_MOUNT" ]; then
    echo "❌ Error: BLACK2T no es escribible"
    exit 1
fi

# Configuración modificada - Todo en BLACK2T
EXTERNAL_USER_DATA="${BLACK2T_MOUNT}/UserData_$(whoami)_macmini"
BACKUP_USER_DATA="${BLACK2T_MOUNT}/UserData_$(whoami)_backup_macmini"  # ¡CAMBIO AQUÍ!

echo "✅ Configuración para solo BLACK2T:"
echo "   Datos: $EXTERNAL_USER_DATA"
echo "   Backup: $BACKUP_USER_DATA"

# Crear estructura
mkdir -p "$EXTERNAL_USER_DATA"
mkdir -p "$BACKUP_USER_DATA"

echo "🎉 Estructura creada exitosamente en BLACK2T"
EOF
        
        chmod +x "/tmp/manage_user_data_black2t_only.sh"
        
        echo -e "${GREEN}✅ Script temporal creado: /tmp/manage_user_data_black2t_only.sh${NC}"
        echo -e "${YELLOW}Para usarlo: bash /tmp/manage_user_data_black2t_only.sh${NC}"
        ;;
        
    3)
        echo -e "${BLUE}🔧 INSTRUCCIONES PARA MAC STUDIO:${NC}"
        echo
        echo -e "${YELLOW}En el Mac Studio, verifica:${NC}"
        echo
        echo "1. ${BLUE}Preferencias del Sistema > Compartir${NC}"
        echo "2. ${BLUE}Compartir archivos debe estar activado${NC}"
        echo "3. ${BLUE}Selecciona el disco 8TbSeries en la lista${NC}"
        echo "4. ${BLUE}En 'Usuarios', agrega tu usuario (angelsalazar)${NC}"
        echo "5. ${BLUE}Asegúrate de que tienes permisos de 'Lectura y escritura'${NC}"
        echo
        echo -e "${YELLOW}También verifica permisos del sistema de archivos:${NC}"
        echo "1. ${BLUE}En Mac Studio, abre Terminal${NC}"
        echo "2. ${BLUE}Ejecuta: ls -la /Volumes/8TbSeries${NC}"
        echo "3. ${BLUE}Si es necesario: sudo chown angelsalazar /Volumes/8TbSeries${NC}"
        echo
        echo -e "${GREEN}Después de hacer estos cambios, reconecta desde el Mac Mini${NC}"
        ;;
        
    4)
        echo -e "${BLUE}📊 DIAGNÓSTICO COMPLETO:${NC}"
        echo
        echo "Estado de montaje:"
        mount | grep -E "(BLACK2T|8TbSeries)"
        echo
        echo "Permisos de directorios:"
        ls -la /Volumes/ | grep -E "(BLACK2T|8TbSeries)"
        echo
        echo "Prueba de escritura:"
        test -w /Volumes/BLACK2T && echo "✅ BLACK2T: Escribible" || echo "❌ BLACK2T: Solo lectura"
        test -w /Volumes/8TbSeries && echo "✅ 8TbSeries: Escribible" || echo "❌ 8TbSeries: Solo lectura"
        ;;
        
    *)
        echo -e "${RED}❌ Opción inválida${NC}"
        exit 1
        ;;
esac

echo
echo -e "${CYAN}💡 RECOMENDACIÓN:${NC}"
echo -e "${YELLOW}Mientras solucionas los permisos, puedes:${NC}"
echo -e "${GREEN}1. Usar solo BLACK2T para tus datos${NC}"
echo -e "${GREEN}2. Los backups se crearán en BLACK2T temporalmente${NC}"
echo -e "${GREEN}3. Una vez solucionado 8TbSeries, mover los backups allí${NC}"
echo

echo -e "${BLUE}Presiona Enter para continuar...${NC}"
read -r
