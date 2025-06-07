# Solución para Problemas del Puntero en Screen Sharing

## Descripción del Problema

Durante las sesiones de "Share Screen" entre Mac Studio y Mac Mini a través de Thunderbolt Bridge, el puntero del mouse desaparece en varias situaciones:

1. **Puntero fuera de límites**: Cuando el cursor se mueve más allá de las fronteras de la pantalla
2. **Desaparición al usar teclado**: El puntero desaparece al comenzar a usar el teclado
3. **Movimientos rápidos**: El cursor desaparece durante movimientos muy rápidos del mouse

## Scripts Creados

### 1. `cursor_diagnostics.sh` - Script Principal de Diagnóstico

**Uso**: `./cursor_diagnostics.sh [opción]`

**Opciones disponibles**:
- `monitor` - Monitorear continuamente el estado del puntero
- `fix` - Intentar reparar problemas del puntero
- `reset` - Reiniciar completamente el sistema del puntero
- `info` - Mostrar información detallada del sistema
- `help` - Mostrar ayuda

**Sin opciones**: Ejecuta diagnóstico completo

**Funciones principales**:
- Obtiene información detallada del puntero y pantallas
- Monitorea la posición del cursor en tiempo real
- Verifica límites de pantalla
- Repara problemas básicos del cursor
- Diagnostica procesos de Screen Sharing

### 2. `cursor_auto_monitor.sh` - Monitor Automático en Segundo Plano

Este script se ejecuta continuamente en segundo plano y corrige automáticamente los problemas del puntero.

**Características**:
- Monitorea la posición del cursor cada 3 segundos
- Detecta cuando el cursor está fuera de límites
- Reposiciona automáticamente el cursor cuando está estático por más de 10 segundos
- Solo actúa cuando hay sesiones de Screen Sharing activas
- Genera logs detallados de su actividad

### 3. `cursor_manager.sh` - Gestor del Monitor Automático

**Uso**: `./cursor_manager.sh [comando]`

**Comandos disponibles**:
- `start` - Iniciar el monitor automático
- `stop` - Detener el monitor automático
- `restart` - Reiniciar el monitor automático
- `status` - Mostrar estado actual del monitor
- `log` - Mostrar log en tiempo real
- `help` - Mostrar ayuda

### 4. `cursor_config.sh` - Configuraciones del Sistema

Aplica configuraciones optimizadas para prevenir problemas del cursor:
- Configuraciones del cursor y visibilidad
- Ajustes de trackpad/mouse
- Configuraciones de accesibilidad
- Optimizaciones de Screen Sharing
- Configuraciones de red para Thunderbolt Bridge

### 5. `quick_cursor_check.sh` - Verificación Rápida

Script generado automáticamente que proporciona una verificación rápida del estado actual del cursor y los procesos relacionados.

## Instrucciones de Uso

### Uso Básico - Solución Rápida

```bash
# Diagnóstico rápido
./cursor_diagnostics.sh

# Reparación inmediata
./cursor_diagnostics.sh fix

# Verificación rápida
./quick_cursor_check.sh
```

### Monitoreo Automático (Recomendado)

```bash
# Iniciar monitor automático
./cursor_manager.sh start

# Verificar estado
./cursor_manager.sh status

# Ver log en tiempo real
./cursor_manager.sh log

# Detener monitor
./cursor_manager.sh stop
```

### Configuración del Sistema

```bash
# Aplicar configuraciones optimizadas (requiere sudo)
./cursor_config.sh
```

### Monitoreo Manual

```bash
# Monitorear posición del cursor en tiempo real
./cursor_diagnostics.sh monitor
```

## Soluciones Específicas

### 1. Problema: Puntero desaparece al ir más allá de fronteras

**Solución automática**:
```bash
./cursor_manager.sh start
```

**Solución manual**:
```bash
./cursor_diagnostics.sh fix
```

### 2. Problema: Puntero desaparece al usar teclado

**Verificar configuración**:
- Ir a Preferencias del Sistema > Accesibilidad > Puntero
- Desactivar "Ocultar cursor mientras se escribe"

**Solución de emergencia**:
```bash
./cursor_diagnostics.sh fix
```

### 3. Problema: Puntero desaparece con movimientos rápidos

**Configuración del sistema**:
```bash
./cursor_config.sh
```

**Si persiste**:
```bash
./cursor_diagnostics.sh reset
```

## Archivos de Log y Monitoreo

- **Log del monitor automático**: `/tmp/cursor_auto_monitor.log`
- **PID del monitor**: `/tmp/cursor_auto_monitor.pid`

## Permisos Requeridos

Para que los scripts funcionen correctamente, necesitas habilitar permisos de accesibilidad:

1. Ir a **Preferencias del Sistema** > **Seguridad y Privacidad** > **Privacidad**
2. Seleccionar **Accesibilidad** en la lista de la izquierda
3. Hacer clic en el candado y autenticarse
4. Agregar **Terminal** o la aplicación desde la que ejecutas los scripts
5. Asegurarse de que esté marcada la casilla junto a la aplicación

## Automatización al Inicio

Para que el monitor se inicie automáticamente al encender el Mac:

1. Crear un Launch Agent:
```bash
# Crear archivo plist
cat > ~/Library/LaunchAgents/com.cursor.monitor.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.cursor.monitor</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/angelsalazar/Documents/scripts/cursor_manager.sh</string>
        <string>start</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
EOF

# Cargar el Launch Agent
launchctl load ~/Library/LaunchAgents/com.cursor.monitor.plist
```

## Solución de Problemas

### El script no puede obtener la posición del cursor
- Verificar permisos de accesibilidad en Preferencias del Sistema
- Reiniciar Terminal después de dar permisos

### El monitor automático no se inicia
```bash
# Verificar que el script existe y es ejecutable
ls -la /Users/angelsalazar/Documents/scripts/cursor_auto_monitor.sh

# Verificar logs
cat /tmp/cursor_auto_monitor.log
```

### Screen Sharing sigue teniendo problemas
1. Reiniciar ambos Macs
2. Ejecutar configuración del sistema: `./cursor_config.sh`
3. Iniciar monitor automático: `./cursor_manager.sh start`
4. Cerrar y reabrir la sesión de Screen Sharing

## Mantenimiento

### Limpieza de logs
```bash
# Limpiar log del monitor
> /tmp/cursor_auto_monitor.log

# O eliminarlo completamente
rm /tmp/cursor_auto_monitor.log
```

### Actualización de scripts
Los scripts están diseñados para ser autocontenidos. Para actualizarlos, simplemente reemplaza los archivos en `/Users/angelsalazar/Documents/scripts/`.

---

**Fecha de creación**: 5 de junio de 2025  
**Autor**: Script automático para resolución de problemas de cursor en Screen Sharing  
**Versión**: 1.0
