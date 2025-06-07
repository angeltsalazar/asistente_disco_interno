#!/bin/bash

# ============================================================================
# ÍNDICE DE SCRIPTS DEL SISTEMA DE MIGRACIÓN
# ============================================================================
# Propósito: Guía rápida de todos los scripts disponibles
# Autor: Asistente de migración
# Fecha: $(date)
# ============================================================================

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                  ÍNDICE DE SCRIPTS                          ║"
echo "║              Sistema de Migración y Backup                  ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo

# ============================================================================
# SCRIPTS PRINCIPALES DE USO DIARIO
# ============================================================================
echo "🚀 SCRIPTS PRINCIPALES - USO DIARIO:"
echo "═══════════════════════════════════"
echo
echo "🖥️  PARA MAC MINI (Transferir datos):"
echo "   📁 ./rsync_black2t_only.sh"
echo "      └─ Transferir directorios de usuario a BLACK2T"
echo "      └─ Crear enlaces simbólicos automáticamente"
echo "      └─ Menú interactivo para seleccionar carpetas"
echo
echo "🖥️  PARA MAC STUDIO (Hacer backups):"
echo "   💾 ./backup_local_macstudio.sh"
echo "      └─ Crear backups de BLACK2T → 8TbSeries"
echo "      └─ Backups incrementales y verificados"
echo "      └─ Solo ejecutable en Mac Studio"
echo

# ============================================================================
# SCRIPTS DE VALIDACIÓN Y DIAGNÓSTICO
# ============================================================================
echo "🔍 SCRIPTS DE VALIDACIÓN Y DIAGNÓSTICO:"
echo "═══════════════════════════════════════"
echo
echo "   🧪 ./system_validation.sh"
echo "      └─ Validación completa del sistema"
echo "      └─ Verificar discos, SSH, scripts y permisos"
echo "      └─ Recomendaciones específicas por máquina"
echo
echo "   🔧 ./permission_master_solver.sh"
echo "      └─ Diagnóstico detallado de permisos"
echo "      └─ Soluciones para problemas comunes"
echo "      └─ Verificación de usuarios y grupos"
echo

# ============================================================================
# SCRIPTS DE DOCUMENTACIÓN
# ============================================================================
echo "📚 SCRIPTS DE DOCUMENTACIÓN:"
echo "═══════════════════════════"
echo
echo "   📖 ./final_status.sh"
echo "      └─ Estado actual y guía de uso diario"
echo "      └─ Resumen de transferencias realizadas"
echo "      └─ Ventajas del sistema implementado"
echo
echo "   🏗️  ./disk_architecture_guide.sh"
echo "      └─ Guía completa de la arquitectura"
echo "      └─ Flujo de datos y mejores prácticas"
echo "      └─ Conceptos técnicos explicados"
echo
echo "   📋 ./resumen_ejecutivo_final.sh"
echo "      └─ Resumen completo del proyecto"
echo "      └─ Logros, métricas y próximos pasos"
echo "      └─ Conclusiones y impacto"
echo
echo "   📝 ./final_setup_instructions.sh"
echo "      └─ Instrucciones finales de configuración"
echo "      └─ Pasos para completar el sistema al 100%"
echo "      └─ Configuración de backups automáticos"
echo

# ============================================================================
# SCRIPTS DE SOLUCIÓN DE PROBLEMAS
# ============================================================================
echo "🚨 SCRIPTS DE SOLUCIÓN DE PROBLEMAS:"
echo "═══════════════════════════════════"
echo
echo "   🔒 ./fix_8tbseries_permissions.sh"
echo "      └─ Diagnóstico de permisos en 8TbSeries"
echo "      └─ Instrucciones para corregir permisos"
echo "      └─ Verificación de estado de discos"
echo
echo "   ⚡ ./quick_fix_8tbseries.sh"
echo "      └─ Reconexión rápida de 8TbSeries"
echo "      └─ Solución para problemas de montaje"
echo "      └─ Verificación automática"
echo
echo "   👤 ./fix_user_permissions_macstudio.sh"
echo "      └─ Configuración de usuario espejo"
echo "      └─ Instrucciones para permisos SMB"
echo "      └─ Solución de problemas de acceso"
echo

# ============================================================================
# SCRIPTS AUXILIARES Y HEREDADOS
# ============================================================================
echo "⚙️  SCRIPTS AUXILIARES:"
echo "═══════════════════════"
echo
echo "   🔄 ./rsync_solution.sh"
echo "      └─ Solución original de rsync con menú"
echo "      └─ Incluye opciones para ambos discos"
echo "      └─ Mantenido por compatibilidad"
echo
echo "   📁 ./manage_user_data_black2t_only.sh"
echo "      └─ Gestión de datos solo en BLACK2T"
echo "      └─ Alternativa simplificada"
echo "      └─ Para casos específicos"
echo

# ============================================================================
# GUÍA DE USO POR SITUACIÓN
# ============================================================================
echo "🎯 GUÍA DE USO POR SITUACIÓN:"
echo "════════════════════════════"
echo
echo "🆕 PRIMER USO:"
echo "   1️⃣  ./final_setup_instructions.sh (leer instrucciones)"
echo "   2️⃣  ./system_validation.sh (verificar estado)"
echo "   3️⃣  ./rsync_black2t_only.sh (transferir datos)"
echo
echo "📅 USO DIARIO:"
echo "   • Mac Mini: ./rsync_black2t_only.sh"
echo "   • Mac Studio: ./backup_local_macstudio.sh"
echo
echo "🔍 DIAGNÓSTICO:"
echo "   • Problemas generales: ./system_validation.sh"
echo "   • Problemas de permisos: ./permission_master_solver.sh"
echo "   • Problemas de 8TbSeries: ./fix_8tbseries_permissions.sh"
echo
echo "📖 CONSULTA:"
echo "   • Estado del sistema: ./final_status.sh"
echo "   • Arquitectura: ./disk_architecture_guide.sh"
echo "   • Resumen completo: ./resumen_ejecutivo_final.sh"
echo

# ============================================================================
# ORDEN RECOMENDADO DE EJECUCIÓN
# ============================================================================
echo "📋 ORDEN RECOMENDADO PARA NUEVOS USUARIOS:"
echo "═════════════════════════════════════════"
echo
echo "1️⃣  ./final_setup_instructions.sh"
echo "    └─ Para entender el estado actual"
echo
echo "2️⃣  ./system_validation.sh"
echo "    └─ Para verificar que todo funciona"
echo
echo "3️⃣  ./disk_architecture_guide.sh"
echo "    └─ Para entender la arquitectura"
echo
echo "4️⃣  ./rsync_black2t_only.sh"
echo "    └─ Para transferir datos (Mac Mini)"
echo
echo "5️⃣  ./backup_local_macstudio.sh"
echo "    └─ Para hacer backups (Mac Studio)"
echo
echo "6️⃣  ./final_status.sh"
echo "    └─ Para ver el estado final"
echo

# ============================================================================
# INFORMACIÓN ADICIONAL
# ============================================================================
echo "ℹ️  INFORMACIÓN ADICIONAL:"
echo "═════════════════════════"
echo
echo "📁 Ubicación:"
echo "   /Volumes/BLACK2T/UserContent_macmini/Documents/Documents/asistente_disco_interno/scripts/"
echo
echo "📋 Logs:"
echo "   ../logs/ - Registros de todas las operaciones"
echo
echo "📚 Documentación:"
echo "   ../docs/ - Documentación adicional"
echo
echo "🔧 Permisos:"
echo "   Todos los scripts tienen permisos de ejecución"
echo
echo "⚡ Ejecución:"
echo "   Cambiar al directorio y ejecutar: ./nombre_script.sh"
echo

echo
echo "════════════════════════════════════════════════════════════════"
echo "📖 ÍNDICE COMPLETADO"
echo "💡 TIP: Todos los scripts incluyen ayuda y menús interactivos"
echo "🎉 Sistema listo para uso diario"
echo "════════════════════════════════════════════════════════════════"
echo
echo "Fecha: $(date)"
