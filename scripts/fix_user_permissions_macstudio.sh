#!/bin/bash
# Script para agregar usuario de Mac Mini a los permisos de 8TbSeries en Mac Studio
# El problema: Solo aparecen usuarios del Mac Studio, no del Mac Mini

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         AGREGAR USUARIO MAC MINI A MAC STUDIO               ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

echo -e "${YELLOW}🔍 INFORMACIÓN DE USUARIO MAC MINI:${NC}"
echo -e "${BLUE}Usuario: $(whoami)${NC}"
echo -e "${BLUE}Nombre: Angel Salazar${NC}"
echo -e "${BLUE}UID: 501${NC}"
echo -e "${BLUE}Grupos: admin, staff${NC}"
echo

echo -e "${YELLOW}❌ PROBLEMA IDENTIFICADO:${NC}"
echo -e "${RED}En Mac Studio solo aparecen usuarios locales del Mac Studio${NC}"
echo -e "${RED}No aparece tu usuario 'angelsalazar' del Mac Mini${NC}"
echo

echo -e "${YELLOW}📋 SOLUCIONES DISPONIBLES:${NC}"
echo
echo -e "${BLUE}MÉTODO 1: Crear usuario específico en Mac Studio (RECOMENDADO)${NC}"
echo -e "${GREEN}✅ Más seguro y organizado${NC}"
echo -e "${GREEN}✅ Permisos específicos para compartir${NC}"
echo
echo -e "${BLUE}MÉTODO 2: Usar usuarios genéricos/Everyone${NC}"
echo -e "${YELLOW}⚠️  Menos seguro pero más simple${NC}"
echo
echo -e "${BLUE}MÉTODO 3: Configurar usuario invitado con permisos${NC}"
echo -e "${YELLOW}⚠️  Temporal pero funcional${NC}"

echo
echo -e "${YELLOW}¿Qué método prefieres?${NC}"
echo "1. 👤 Crear usuario específico en Mac Studio"
echo "2. 🌐 Usar configuración Everyone/Invitado"
echo "3. 🔧 Configuración manual avanzada"
echo "4. 📊 Solo ver instrucciones detalladas"

read -p "Selecciona opción (1-4): " choice

case $choice in
    1)
        echo
        echo -e "${CYAN}👤 MÉTODO 1: CREAR USUARIO ESPECÍFICO EN MAC STUDIO${NC}"
        echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
        echo
        echo -e "${BLUE}PASO 1: En Mac Studio - Crear usuario${NC}"
        echo "1. Ve a: Preferencias del Sistema > Usuarios y grupos"
        echo "2. Haz clic en el candado 🔒 para hacer cambios"
        echo "3. Haz clic en el botón '+' para agregar usuario"
        echo "4. Selecciona: 'Usuario estándar'"
        echo -e "${GREEN}5. Nombre completo: angelsalazar-macmini${NC}"
        echo -e "${GREEN}6. Nombre de cuenta: angelsalazar-macmini${NC}"
        echo -e "${GREEN}7. Contraseña: [usa la misma que tu Mac Mini]${NC}"
        echo "8. Haz clic en 'Crear usuario'"
        echo
        echo -e "${BLUE}PASO 2: En Mac Studio - Configurar compartir${NC}"
        echo "1. Ve a: Preferencias del Sistema > Compartir"
        echo "2. Selecciona 'Compartir archivos'"
        echo "3. Selecciona el disco '8TbSeries' en la lista"
        echo "4. En 'Usuarios', haz clic en el botón '+'"
        echo -e "${GREEN}5. Selecciona 'angelsalazar-macmini'${NC}"
        echo -e "${GREEN}6. Cambia permisos a 'Lectura y escritura'${NC}"
        echo "7. Haz clic en 'Listo'"
        echo
        echo -e "${BLUE}PASO 3: En Mac Mini - Reconectar${NC}"
        echo "1. Desmonta 8TbSeries: diskutil unmount '/Volumes/8TbSeries'"
        echo "2. Abre Finder > Ir > Conectar al servidor"
        echo "3. Servidor: smb://192.168.100.1"
        echo -e "${GREEN}4. Usuario: angelsalazar-macmini${NC}"
        echo -e "${GREEN}5. Contraseña: [la que configuraste]${NC}"
        echo "6. Selecciona el disco 8TbSeries"
        ;;
        
    2)
        echo
        echo -e "${CYAN}🌐 MÉTODO 2: CONFIGURACIÓN EVERYONE/INVITADO${NC}"
        echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
        echo
        echo -e "${BLUE}PASO 1: En Mac Studio - Configurar acceso invitado${NC}"
        echo "1. Ve a: Preferencias del Sistema > Compartir"
        echo "2. Selecciona 'Compartir archivos'"
        echo "3. Selecciona el disco '8TbSeries'"
        echo "4. En 'Usuarios', verifica si aparece 'Everyone'"
        echo "5. Si no aparece, haz clic en 'Opciones...'"
        echo -e "${GREEN}6. Marca 'Compartir archivos y carpetas mediante SMB'${NC}"
        echo -e "${GREEN}7. Marca 'Compartir archivos y carpetas mediante AFP'${NC}"
        echo "8. Acepta los cambios"
        echo
        echo -e "${BLUE}PASO 2: Configurar permisos Everyone${NC}"
        echo "1. En la lista de usuarios para 8TbSeries"
        echo "2. Si aparece 'Everyone', selecciónalo"
        echo -e "${GREEN}3. Cambia permisos a 'Lectura y escritura'${NC}"
        echo "4. Si no aparece 'Everyone', continúa al Paso 3"
        echo
        echo -e "${BLUE}PASO 3: En Mac Mini - Conectar como invitado${NC}"
        echo "1. Desmonta 8TbSeries actual"
        echo "2. Abre Finder > Conectar al servidor"
        echo "3. smb://192.168.100.1"
        echo -e "${GREEN}4. Selecciona 'Invitado' en lugar de usuario específico${NC}"
        echo "5. Selecciona 8TbSeries"
        ;;
        
    3)
        echo
        echo -e "${CYAN}🔧 MÉTODO 3: CONFIGURACIÓN MANUAL AVANZADA${NC}"
        echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
        echo
        echo -e "${BLUE}OPCIÓN A: Usar cuenta de administrador temporal${NC}"
        echo "1. En Mac Studio, identifica el usuario administrador principal"
        echo "2. En Compartir > 8TbSeries, agrega ese usuario administrador"
        echo "3. En Mac Mini, conéctate usando esas credenciales de admin"
        echo
        echo -e "${BLUE}OPCIÓN B: Configurar mediante Terminal (Mac Studio)${NC}"
        echo "1. Conecta SSH al Mac Studio desde Mac Mini:"
        echo "   ssh angel@192.168.100.1"
        echo "2. En Mac Studio via SSH, ejecuta:"
        echo "   sudo sharing -a /Volumes/8TbSeries -S -s 001"
        echo "   sudo dscl . -create /Users/macmini-user"
        echo "   sudo dscl . -create /Users/macmini-user UserShell /bin/bash"
        echo
        echo -e "${BLUE}OPCIÓN C: Modificar permisos directamente${NC}"
        echo "1. En Mac Studio Terminal:"
        echo "   sudo chmod 777 /Volumes/8TbSeries"
        echo "   sudo chown nobody:wheel /Volumes/8TbSeries"
        echo -e "${RED}⚠️  CUIDADO: Esto da acceso completo a todos${NC}"
        ;;
        
    4)
        echo
        echo -e "${CYAN}📊 INSTRUCCIONES DETALLADAS COMPLETAS${NC}"
        echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
        echo
        echo -e "${BLUE}1. DIAGNÓSTICO ACTUAL:${NC}"
        echo "   • Mac Mini usuario: angelsalazar (UID 501)"
        echo "   • Mac Studio usuario: Angel Salazar (diferente cuenta)"
        echo "   • Problema: SMB solo reconoce usuarios locales del servidor"
        echo
        echo -e "${BLUE}2. POR QUÉ NO APARECE TU USUARIO:${NC}"
        echo "   • SMB/AFP buscan usuarios en el servidor (Mac Studio)"
        echo "   • Tu usuario 'angelsalazar' está en Mac Mini, no Mac Studio"
        echo "   • Mac Studio solo muestra sus usuarios locales"
        echo
        echo -e "${BLUE}3. SOLUCIONES EN ORDEN DE PREFERENCIA:${NC}"
        echo -e "${GREEN}   A) Crear usuario espejo en Mac Studio${NC}"
        echo -e "${GREEN}   B) Usar configuración Everyone/Guest${NC}"
        echo -e "${YELLOW}   C) Configurar usuario genérico compartido${NC}"
        echo -e "${RED}   D) Permisos totalmente abiertos (no recomendado)${NC}"
        echo
        echo -e "${BLUE}4. VERIFICACIÓN POST-CONFIGURACIÓN:${NC}"
        echo "   • Comando para probar: touch /Volumes/8TbSeries/test_write"
        echo "   • Si funciona: rm /Volumes/8TbSeries/test_write"
        echo "   • Si falla: revisar permisos nuevamente"
        ;;
        
    *)
        echo -e "${RED}❌ Opción inválida${NC}"
        exit 1
        ;;
esac

echo
echo -e "${CYAN}💡 RECOMENDACIÓN FINAL:${NC}"
echo -e "${YELLOW}Después de configurar cualquier método:${NC}"
echo
echo -e "${GREEN}1. Prueba crear directorio:${NC}"
echo "   mkdir /Volumes/8TbSeries/test_permissions"
echo
echo -e "${GREEN}2. Si funciona, ejecuta:${NC}"
echo "   ./scripts/manage_user_data.sh"
echo
echo -e "${GREEN}3. Si sigue fallando, usa:${NC}"
echo "   ./scripts/manage_user_data_black2t_only.sh"

echo
echo -e "${BLUE}¿Necesitas ayuda con algún paso específico? (y/N):${NC}"
read -r help_needed

if [[ $help_needed =~ ^[Yy]$ ]]; then
    echo
    echo -e "${YELLOW}¿Qué necesitas?${NC}"
    echo "1. Comando para desmontar 8TbSeries"
    echo "2. Comando para reconectar manualmente"
    echo "3. Verificar estado actual"
    echo "4. Probar escritura en disco"
    
    read -p "Selecciona (1-4): " help_choice
    
    case $help_choice in
        1)
            echo -e "${BLUE}Comando para desmontar:${NC}"
            echo "diskutil unmount '/Volumes/8TbSeries'"
            ;;
        2)
            echo -e "${BLUE}Comandos para reconectar:${NC}"
            echo "open 'smb://192.168.100.1'"
            echo "# O usando mount:"
            echo "mount -t smbfs //usuario@192.168.100.1/8TbSeries /Volumes/8TbSeries"
            ;;
        3)
            echo -e "${BLUE}Verificando estado actual...${NC}"
            mount | grep 8TbSeries
            ls -la /Volumes/8TbSeries/ | head -5
            test -w /Volumes/8TbSeries && echo "✅ Escribible" || echo "❌ Solo lectura"
            ;;
        4)
            echo -e "${BLUE}Probando escritura...${NC}"
            if touch /Volumes/8TbSeries/test_write_$$; then
                echo -e "${GREEN}✅ Escritura exitosa${NC}"
                rm /Volumes/8TbSeries/test_write_$$
            else
                echo -e "${RED}❌ Sin permisos de escritura${NC}"
            fi
            ;;
    esac
fi

echo
echo -e "${BLUE}Presiona Enter para continuar...${NC}"
read -r
