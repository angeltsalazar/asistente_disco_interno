#!/bin/bash

# Script de diagnóstico para Thunderbolt Bridge
# Ejecutar desde Mac Mini para verificar configuración

echo "=========================================="
echo "  DIAGNÓSTICO THUNDERBOLT BRIDGE"
echo "=========================================="
echo "Fecha: $(date)"
echo "Ejecutándose en: $(hostname)"
echo ""

# Función para colorear output
green() { echo -e "\033[32m$1\033[0m"; }
red() { echo -e "\033[31m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
blue() { echo -e "\033[34m$1\033[0m"; }

echo "1. VERIFICANDO INTERFACES DE RED"
echo "=========================================="
echo "Todas las interfaces:"
ifconfig | grep -E "^[a-zA-Z]" | awk '{print $1}' | tr -d ':'

echo ""
echo "Buscando interfaces Thunderbolt/Bridge:"
if ifconfig | grep -q "bridge"; then
    green "✓ Interface bridge encontrada"
    ifconfig | grep -A 10 "bridge"
else
    red "✗ No se encontró interface bridge"
fi

echo ""
echo "2. ESTADO DE THUNDERBOLT BRIDGE"
echo "=========================================="
thunderbolt_status=$(networksetup -listallnetworkservices | grep -i "thunderbolt\|bridge")
if [[ -n "$thunderbolt_status" ]]; then
    green "✓ Servicio Thunderbolt Bridge encontrado:"
    echo "$thunderbolt_status"
    
    # Obtener configuración actual
    echo ""
    echo "Configuración actual:"
    networksetup -getinfo "Thunderbolt Bridge" 2>/dev/null || networksetup -getinfo "Puente Thunderbolt" 2>/dev/null
else
    red "✗ Servicio Thunderbolt Bridge no encontrado"
fi

echo ""
echo "3. VERIFICANDO CONECTIVIDAD THUNDERBOLT"
echo "=========================================="
# Verificar si hay dispositivos Thunderbolt conectados
if command -v system_profiler >/dev/null 2>&1; then
    thunderbolt_devices=$(system_profiler SPThunderboltDataType 2>/dev/null | grep -A 5 "Device Name")
    if [[ -n "$thunderbolt_devices" ]]; then
        green "✓ Dispositivos Thunderbolt detectados:"
        echo "$thunderbolt_devices"
    else
        yellow "⚠ No se detectaron dispositivos Thunderbolt conectados"
    fi
fi

echo ""
echo "4. CONFIGURACIÓN IP ACTUAL"
echo "=========================================="
current_ip=$(ifconfig | grep -A 5 "bridge" | grep "inet " | awk '{print $2}')
if [[ -n "$current_ip" ]]; then
    if [[ "$current_ip" =~ ^169\.254\. ]]; then
        yellow "⚠ IP auto-asignada detectada: $current_ip"
        echo "  Esto indica que no hay comunicación exitosa"
    elif [[ "$current_ip" =~ ^192\.168\.100\. ]]; then
        green "✓ IP manual configurada: $current_ip"
    else
        blue "ℹ IP configurada: $current_ip"
    fi
else
    red "✗ No se encontró IP asignada al bridge"
fi

echo ""
echo "5. PRUEBAS DE CONECTIVIDAD"
echo "=========================================="
target_ips=("192.168.100.1" "169.254.102.84")
for ip in "${target_ips[@]}"; do
    echo "Probando conectividad a $ip..."
    if ping -c 2 -W 2000 "$ip" >/dev/null 2>&1; then
        green "✓ Respuesta de $ip"
    else
        red "✗ Sin respuesta de $ip"
    fi
done

echo ""
echo "6. INFORMACIÓN DEL SISTEMA"
echo "=========================================="
echo "Versión de macOS: $(sw_vers -productVersion)"
echo "Modelo: $(system_profiler SPHardwareDataType | grep "Model Name" | awk -F': ' '{print $2}')"
echo "Puertos disponibles:"
system_profiler SPUSBDataType SPThunderboltDataType 2>/dev/null | grep -E "USB 3|Thunderbolt" | head -5

echo ""
echo "7. RECOMENDACIONES"
echo "=========================================="
if [[ "$current_ip" =~ ^169\.254\. ]]; then
    yellow "PROBLEMA DETECTADO: IP auto-asignada"
    echo ""
    echo "Soluciones sugeridas:"
    echo "1. Verificar que el cable Thunderbolt esté bien conectado"
    echo "2. Configurar IP manual en ambos Macs:"
    echo "   Mac Mini: 192.168.100.2"
    echo "   Mac Studio: 192.168.100.1"
    echo "3. Ejecutar comando de configuración automática:"
    echo ""
    blue "   sudo networksetup -setmanual 'Thunderbolt Bridge' 192.168.100.2 255.255.255.0"
    echo ""
elif [[ "$current_ip" =~ ^192\.168\.100\. ]]; then
    green "✓ Configuración IP correcta"
    echo "Si aún hay problemas, verificar:"
    echo "1. Cable Thunderbolt certificado"
    echo "2. Compartir Pantalla habilitado en Mac Studio"
    echo "3. Firewall no bloqueando conexiones"
fi

echo ""
echo "¿Deseas aplicar configuración automática? (y/n)"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Aplicando configuración manual..."
    sudo networksetup -setmanual "Thunderbolt Bridge" 192.168.100.2 255.255.255.0 2>/dev/null ||
    sudo networksetup -setmanual "Puente Thunderbolt" 192.168.100.2 255.255.255.0
    
    echo "Configuración aplicada. Verificando..."
    sleep 3
    new_ip=$(ifconfig | grep -A 5 "bridge" | grep "inet " | awk '{print $2}')
    if [[ "$new_ip" == "192.168.100.2" ]]; then
        green "✓ IP configurada correctamente: $new_ip"
    else
        red "✗ Error en la configuración. IP actual: $new_ip"
    fi
fi

echo ""
echo "=========================================="
echo "  DIAGNÓSTICO COMPLETADO"
echo "=========================================="
