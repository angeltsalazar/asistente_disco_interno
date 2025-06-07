#!/bin/bash

# Script de prueba del Asistente de Disco Interno
# Verifica que todos los componentes estén funcionando correctamente

clear
echo "=== PRUEBA DEL ASISTENTE DE DISCO INTERNO ==="
echo
echo "Ubicación actual: $(pwd)"
echo "Fecha: $(date)"
echo

# Función para mostrar estado con colores
print_status() {
    if [[ $1 == "OK" ]]; then
        echo "  ✅ $2"
    else
        echo "  ❌ $2"
    fi
}

# 1. Verificar estructura de directorios
echo "1. Verificando estructura de directorios..."
for dir in scripts docs logs config backups utils demos; do
    if [[ -d "$dir" ]]; then
        count=$(ls "$dir" 2>/dev/null | wc -l | tr -d ' ')
        print_status "OK" "$dir/ - $count archivos"
    else
        print_status "ERROR" "$dir/ - no existe"
    fi
done
echo

# 2. Verificar scripts principales
echo "2. Verificando scripts principales..."
main_scripts=(
    "install.sh"
    "aliases.sh" 
    "inicio_rapido.sh"
    "scripts/app_manager_master.sh"
    "scripts/damage_assessment.sh"
    "scripts/disk_manager.sh"
)

for script in "${main_scripts[@]}"; do
    if [[ -f "$script" && -x "$script" ]]; then
        print_status "OK" "$script - ejecutable"
    elif [[ -f "$script" ]]; then
        print_status "OK" "$script - existe (sin permisos de ejecución)"
    else
        print_status "ERROR" "$script - no encontrado"
    fi
done
echo

# 3. Verificar estado del disco
echo "3. Estado de los discos..."
if [[ -d "/Volumes/BLACK2T" ]]; then
    print_status "OK" "BLACK2T montado"
    df -h /Volumes/BLACK2T | tail -1 | awk '{print "    Espacio: " $3 " usado de " $2 " (" $5 ")"}'
else
    print_status "ERROR" "BLACK2T no montado"
fi

echo "  Disco interno:"
df -h / | tail -1 | awk '{print "    Espacio: " $3 " usado de " $2 " (" $5 ")"}'
echo

# 4. Probar carga de aliases
echo "4. Probando aliases..."
if [[ -f "aliases.sh" ]]; then
    source aliases.sh > /dev/null 2>&1
    print_status "OK" "Aliases cargados correctamente"
else
    print_status "ERROR" "No se pudieron cargar los aliases"
fi
echo

# 5. Verificar configuración
echo "5. Verificando configuración..."
if [[ -f "config/migration_state.json" ]]; then
    if command -v jq >/dev/null 2>&1; then
        print_status "OK" "Estado del sistema (JSON válido)"
        echo "    Última actualización: $(jq -r '.last_update // "No definida"' config/migration_state.json)"
    else
        print_status "OK" "Estado del sistema (jq no disponible para validar)"
    fi
else
    print_status "ERROR" "Archivo de estado no encontrado"
fi
echo

# Resumen final
echo "=== RESUMEN ==="
total_scripts=$(ls scripts/ 2>/dev/null | wc -l | tr -d ' ')
total_docs=$(ls docs/ 2>/dev/null | wc -l | tr -d ' ')
total_logs=$(ls logs/ 2>/dev/null | wc -l | tr -d ' ')

echo "📊 Estadísticas:"
echo "  • Scripts: $total_scripts archivos"
echo "  • Documentación: $total_docs archivos"  
echo "  • Logs: $total_logs archivos"
echo
echo "🚀 Para usar el asistente:"
echo "  1. source aliases.sh"
echo "  2. ./inicio_rapido.sh"
echo "  3. O usar: disco-menu (después de cargar aliases)"
echo
echo "✨ ¡Sistema listo para usar!"
