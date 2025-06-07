#!/bin/bash

# ============================================================================
# SCRIPT DE VALIDACIÓN COMPLETA DEL SISTEMA
# ============================================================================
# Propósito: Verificar que todos los componentes del sistema estén funcionando
# Autor: Asistente de migración
# Fecha: $(date)
# ============================================================================

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║              VALIDACIÓN COMPLETA DEL SISTEMA                ║"
echo "║                   Estado y Funcionalidad                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo

# Detectar la máquina actual
HOSTNAME=$(hostname)
echo "🖥️  Máquina actual: $HOSTNAME"
echo

# ============================================================================
# 1. VERIFICACIÓN DE DISCOS
# ============================================================================
echo "📀 VERIFICACIÓN DE DISCOS:"
echo "─────────────────────────────"

if [[ -d "/Volumes/BLACK2T" ]]; then
    echo "✅ BLACK2T montado correctamente"
    BLACK2T_WRITABLE=$(touch "/Volumes/BLACK2T/test_write_$$" 2>/dev/null && echo "SÍ" || echo "NO")
    [[ "$BLACK2T_WRITABLE" == "SÍ" ]] && rm -f "/Volumes/BLACK2T/test_write_$$"
    echo "   📝 Escritura: $BLACK2T_WRITABLE"
    
    # Verificar contenido UserContent_macmini
    if [[ -d "/Volumes/BLACK2T/UserContent_macmini" ]]; then
        USER_DIRS=$(ls -1 "/Volumes/BLACK2T/UserContent_macmini" | wc -l)
        echo "   📁 Directorios de usuario: $USER_DIRS"
    fi
else
    echo "❌ BLACK2T no está montado"
fi

if [[ -d "/Volumes/8TbSeries" ]]; then
    echo "✅ 8TbSeries montado correctamente"
    SERIES_WRITABLE=$(touch "/Volumes/8TbSeries/test_write_$$" 2>/dev/null && echo "SÍ" || echo "NO")
    [[ "$SERIES_WRITABLE" == "SÍ" ]] && rm -f "/Volumes/8TbSeries/test_write_$$"
    echo "   📝 Escritura: $SERIES_WRITABLE"
    
    # Verificar backups
    if [[ -d "/Volumes/8TbSeries/UserContent_macmini_backup" ]]; then
        BACKUP_DIRS=$(ls -1 "/Volumes/8TbSeries/UserContent_macmini_backup" 2>/dev/null | wc -l)
        echo "   💾 Directorios de backup: $BACKUP_DIRS"
    fi
else
    echo "❌ 8TbSeries no está montado"
fi
echo

# ============================================================================
# 2. VERIFICACIÓN DE CONECTIVIDAD SSH
# ============================================================================
echo "🔐 VERIFICACIÓN DE CONECTIVIDAD SSH:"
echo "───────────────────────────────────"

if [[ "$HOSTNAME" == *"Mac-mini"* ]]; then
    echo "📡 Probando conexión SSH a Mac Studio..."
    SSH_TEST=$(timeout 10 ssh -o ConnectTimeout=5 -o BatchMode=yes angelsalazar@Angels-Mac-Studio.local "echo 'SSH_OK'" 2>/dev/null)
    if [[ "$SSH_TEST" == "SSH_OK" ]]; then
        echo "✅ Conexión SSH exitosa"
        echo "   🎯 Usuario: angelsalazar"
        echo "   🏠 Destino: Angels-Mac-Studio.local"
    else
        echo "❌ Conexión SSH falló"
        echo "   💡 Verificar que SSH esté habilitado en Mac Studio"
    fi
else
    echo "ℹ️  No aplicable desde Mac Studio"
fi
echo

# ============================================================================
# 3. VERIFICACIÓN DE SCRIPTS PRINCIPALES
# ============================================================================
echo "📜 VERIFICACIÓN DE SCRIPTS PRINCIPALES:"
echo "──────────────────────────────────────"

SCRIPT_DIR="/Volumes/BLACK2T/UserContent_macmini/Documents/Documents/asistente_disco_interno/scripts"

SCRIPTS_IMPORTANTES=(
    "rsync_black2t_only.sh"
    "backup_local_macstudio.sh" 
    "manage_user_data_black2t_only.sh"
    "permission_master_solver.sh"
    "disk_architecture_guide.sh"
)

for script in "${SCRIPTS_IMPORTANTES[@]}"; do
    if [[ -f "$SCRIPT_DIR/$script" ]]; then
        if [[ -x "$SCRIPT_DIR/$script" ]]; then
            echo "✅ $script (ejecutable)"
        else
            echo "⚠️  $script (sin permisos de ejecución)"
        fi
    else
        echo "❌ $script (no encontrado)"
    fi
done
echo

# ============================================================================
# 4. VERIFICACIÓN DE ARQUITECTURA DE DATOS
# ============================================================================
echo "🏗️  VERIFICACIÓN DE ARQUITECTURA:"
echo "─────────────────────────────────"

echo "📋 Flujo establecido:"
echo "   🎯 Datos activos: BLACK2T"
echo "   💾 Backups: 8TbSeries"
echo "   🔄 Transferencia: Mac Mini → BLACK2T (rsync SSH)"
echo "   💾 Backup: BLACK2T → 8TbSeries (solo Mac Studio)"
echo

# Verificar enlaces simbólicos como ejemplo de transferencias exitosas
HOME_DIR="$HOME"
SYMLINKS_FOUND=0

for dir in Downloads Documents Desktop; do
    if [[ -L "$HOME_DIR/$dir" ]]; then
        TARGET=$(readlink "$HOME_DIR/$dir")
        if [[ "$TARGET" == *"BLACK2T"* ]]; then
            echo "✅ $dir → BLACK2T (transferido)"
            ((SYMLINKS_FOUND++))
        fi
    fi
done

if [[ $SYMLINKS_FOUND -gt 0 ]]; then
    echo "   📊 Directorios ya transferidos: $SYMLINKS_FOUND"
else
    echo "   ℹ️  No se encontraron transferencias previas"
fi
echo

# ============================================================================
# 5. RECOMENDACIONES SEGÚN LA MÁQUINA
# ============================================================================
echo "💡 RECOMENDACIONES:"
echo "──────────────────"

if [[ "$HOSTNAME" == *"Mac-mini"* ]]; then
    echo "🖥️  DESDE MAC MINI:"
    echo "   ✨ Usar: ./rsync_black2t_only.sh"
    echo "   📁 Para transferir directorios de usuario a BLACK2T"
    echo "   🔗 Se crean enlaces simbólicos automáticamente"
    echo
    echo "   🚫 NO usar scripts de backup (solo Mac Studio)"
    
elif [[ "$HOSTNAME" == *"Mac-Studio"* ]]; then
    echo "🖥️  DESDE MAC STUDIO:"
    echo "   💾 Usar: ./backup_local_macstudio.sh"
    echo "   📋 Para crear backups de BLACK2T → 8TbSeries"
    echo "   ⏰ Considerar programar backups automáticos"
    echo
    echo "   🚫 NO usar scripts de transferencia SSH (solo Mac Mini)"
    
else
    echo "❓ Máquina no reconocida: $HOSTNAME"
    echo "   📖 Consultar disk_architecture_guide.sh"
fi
echo

# ============================================================================
# 6. RESUMEN FINAL
# ============================================================================
echo "📊 RESUMEN FINAL:"
echo "────────────────"

ISSUES=0

# Verificar componentes críticos
if [[ ! -d "/Volumes/BLACK2T" ]]; then
    echo "❌ BLACK2T no disponible"
    ((ISSUES++))
fi

if [[ "$BLACK2T_WRITABLE" != "SÍ" ]] && [[ -d "/Volumes/BLACK2T" ]]; then
    echo "❌ BLACK2T sin permisos de escritura"
    ((ISSUES++))
fi

if [[ "$HOSTNAME" == *"Mac-mini"* ]] && [[ "$SSH_TEST" != "SSH_OK" ]]; then
    echo "❌ SSH no funcional"
    ((ISSUES++))
fi

if [[ $ISSUES -eq 0 ]]; then
    echo "🎉 SISTEMA COMPLETAMENTE FUNCIONAL"
    echo "   ✅ Todos los componentes operativos"
    echo "   🚀 Listo para transferencias/backups"
else
    echo "⚠️  SE ENCONTRARON $ISSUES PROBLEMAS"
    echo "   🔧 Revisar y corregir antes de continuar"
fi

echo
echo "📚 Para más información:"
echo "   📖 ./disk_architecture_guide.sh - Guía de arquitectura"
echo "   📋 ./resumen_ejecutivo.sh - Resumen del proyecto"
echo
echo "Validación completada: $(date)"
echo "════════════════════════════════════════════════════════════════"
