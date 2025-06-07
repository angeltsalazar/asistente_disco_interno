# Gestor de Aplicaciones en Discos Externos

Sistema completo y escalable para mover aplicaciones de `/Applications` a discos externos y liberar espacio en el disco interno de tu Mac.

## 📋 Descripción

Este sistema te permite mover aplicaciones grandes a discos externos manteniendo su funcionalidad a través de enlaces simbólicos, con backups automáticos y monitoreo del estado. **Diseñado para ser usado en múltiples máquinas (Mac Mini, Mac Studio, Mac Pro)**.

## 🎯 Configuración Multi-Máquina

### Configuración Actual: Mac Mini
- **Disco Principal**: `BLACK2T` → `/Volumes/BLACK2T/Applications_macmini`
- **Disco Backup**: `8TbSeries` → `/Volumes/8TbSeries/Applications_macmini`
- **Datos Usuario**: `/Volumes/BLACK2T/UserData_$(whoami)_macmini`
- **Aplicaciones**: `/Applications` (enlaces simbólicos)

### Configuraciones Disponibles
- **Mac Mini**: sufijo `_macmini`
- **Mac Studio**: sufijo `_macstudio`
- **Mac Pro**: sufijo `_macpro`
- **Personalizado**: sufijo personalizable

## 🔧 Gestión de Configuración

### Cambiar entre Máquinas
```bash
# Ver configuración actual
./machine_config.sh

# Cambiar configuración automáticamente
./update_machine_config.sh
```

### Configuración Manual
Para cambiar manualmente la configuración, edita las rutas en cada script:
- Busca líneas con `_macmini`
- Cambia a `_macstudio` o `_macpro` según corresponda

## 📁 Scripts Incluidos

### 1. `app_manager_master.sh` - Script Principal
El punto de entrada principal con interfaz de menú completa.

```bash
./app_manager_master.sh
```

### 2. `move_apps_to_external.sh` - Mover Aplicaciones
Mueve aplicaciones seleccionadas al disco externo con backup automático.

**Características:**
- ✅ Backup automático antes de mover
- ✅ Creación de enlaces simbólicos
- ✅ Verificación de integridad
- ✅ Lista de aplicaciones recomendadas
- ✅ Logging detallado

### 3. `restore_apps_from_external.sh` - Restaurar Aplicaciones
Restaura aplicaciones desde el backup al disco interno.

**Características:**
- ✅ Restauración desde backup
- ✅ Eliminación de enlaces rotos
- ✅ Verificación de estado
- ✅ Restauración individual o masiva

### 4. `monitor_external_apps.sh` - Monitor del Sistema
Monitor completo del estado de aplicaciones y discos.

**Características:**
- 📊 Estado de discos y espacio
- 🔗 Salud de enlaces simbólicos
- 📱 Conteo de aplicaciones
- 💾 Espacio ahorrado
- 📋 Reportes automáticos

### 5. `disk_manager.sh` - Gestor de Discos
Gestión automática de montaje y estado de discos externos.

**Características:**
- 🔌 Montaje automático
- ✅ Verificación de conectividad
- ⚙️ Configuración de automontaje
- 📝 Logging de eventos

### 6. `machine_config.sh` - Configuración de Máquina
Gestiona la configuración específica de cada máquina.

**Características:**
- 🖥️ Configuraciones pre-definidas para Mac Mini, Studio, Pro
- ⚙️ Sufijos automáticos en directorios
- 📋 Visualización de configuración actual
- 🔧 Cambio fácil entre máquinas

### 7. `update_machine_config.sh` - Actualizador de Configuración
Actualiza automáticamente todos los scripts para una nueva máquina.

**Características:**
- 🔄 Actualización automática de todos los scripts
- 💾 Backup automático antes de cambios
- ✅ Validación de configuración
- 📝 Logging de cambios

### 8. `safe_move_apps.sh` - Movimiento Seguro (RECOMENDADO)
Script mejorado que solo mueve aplicaciones seguras, nunca apps del sistema.

**Características:**
- 🛡️ Lista de aplicaciones críticas (NUNCA mover)
- ✅ Lista de aplicaciones seguras (OK para mover)
- 🔍 Validación automática de seguridad
- 📊 Análisis pre-movimiento

### 9. `clean_system_caches.sh` - Limpieza Segura
Primera línea de defensa para liberar espacio sin riesgos.

**Características:**
- 🧹 Limpieza de caches y archivos temporales
- 🛡️ 100% seguro, no afecta aplicaciones
- 📊 Reporte de espacio liberado
- 🚀 Método más rápido para ganar espacio

### 10. `manage_user_data.sh` - Gestión de Datos de Usuario
Mueve datos de usuario grandes de forma segura.

**Características:**
- 📁 Gestión de Documents, Downloads, Desktop
- 🎵 Manejo de bibliotecas multimedia
- 🔗 Enlaces simbólicos transparentes
- 💾 Backup automático

### 8. `migration_state.sh` - Sistema de Estado Automatizado
**NUEVO**: Sistema avanzado de seguimiento y estado de migración.

```bash
# Inicializar sistema de estado
source migration_state.sh
create_initial_state

# Verificar estado de un directorio
get_directory_status "Documents"

# Actualizar estado tras migración
update_directory_status "Documents" "migrated" "/path/target" "/path/backup"

# Verificar si necesita actualización
check_needs_update "Documents"

# Ver estado completo del sistema
show_migration_status
```

**Características:**
- **Seguimiento Automático**: Registra qué directorios han sido migrados
- **Estados Disponibles**: `not_migrated`, `in_progress`, `migrated`, `error`
- **Auto-actualización**: Detecta cuando se necesita sincronización
- **Integridad**: Verifica enlaces simbólicos y destinos
- **Historial**: Registra fechas, tamaños y rutas de migración

### 9. `move_user_content.sh` - Migración Integral con Estado
**ACTUALIZADO**: Integración completa con el sistema de estado.

```bash
./move_user_content.sh
```

**Mejoras con Sistema de Estado:**
- ✅ **Detección Automática**: Sabe si un directorio ya fue migrado
- 🔄 **Sincronización Inteligente**: Detecta cambios y actualiza automáticamente
- 📊 **Seguimiento Detallado**: Registra tamaños, fechas y rutas
- 🔗 **Verificación de Enlaces**: Corrige enlaces simbólicos rotos
- 📋 **Estado Visual**: Interfaz clara del estado de cada directorio

**Flujo de Trabajo Automatizado:**
1. Al ejecutar una migración, primero verifica el estado actual
2. Si ya está migrado, verifica si necesita actualización
3. Si necesita actualización, sincroniza automáticamente
4. Registra todos los cambios en el archivo de estado
5. Mantiene historial completo para auditoría

## 📊 Sistema de Estado y Migración Automatizada

### Flujo de Trabajo del Sistema de Estado

1. **Inicialización Automática**
   - Al usar `move_user_content.sh`, el sistema de estado se inicializa automáticamente
   - Crea `migration_state.json` con configuración predeterminada
   - Registra máquina, disco externo y estructura inicial

2. **Proceso de Migración Inteligente**
   ```bash
   # El sistema verifica automáticamente:
   # 1. ¿Ya está migrado?
   # 2. ¿Necesita actualización?
   # 3. ¿Es la primera migración?
   ```

3. **Estados de Directorios**
   - `not_migrated`: No ha sido movido al disco externo
   - `in_progress`: Migración en curso
   - `migrated`: Exitosamente migrado con enlace simbólico
   - `error`: Error durante la migración

### Mantenimiento y Sincronización

**Auto-actualización Habilitada** 🔄
- Directorios de usuario importantes (Documents, Downloads, Pictures, etc.)
- Detecta automáticamente cambios y sincroniza
- Corrige enlaces simbólicos rotos

**Solo Manual** 🔒
- Directorios del sistema (Application Support, algunos caches)
- Requiere intervención manual para actualizaciones
- Mayor seguridad para datos críticos

### Ver Estado del Sistema
```bash
# Desde el menú principal
./app_manager_master.sh
# Opción 9: "Ver estado detallado de migración"

# O directamente
source migration_state.sh
show_migration_status
```

### Mejores Prácticas para el Estado

1. **Verificación Regular**
   - Revisa el estado mensualmente
   - Busca directorios que necesiten actualización
   - Verifica integridad de enlaces simbólicos

2. **Backup del Archivo de Estado**
   - `migration_state.json` contiene información crítica
   - Incluirlo en backups regulares
   - Ubicación: `$HOME/Documents/scripts/migration_state.json`

3. **Resolución de Conflictos**
   ```bash
   # Si un directorio muestra estado incorrecto
   update_directory_status "DirectoryName" "migrated" "/correct/path" ""
   
   # Para forzar re-migración
   update_directory_status "DirectoryName" "not_migrated" "" ""
   ```

4. **Monitoreo de Cambios**
   - El sistema detecta archivos nuevos automáticamente
   - Sincroniza cambios cuando `auto_update` está habilitado
   - Preserva estructura y permisos originales

## 🚀 Uso Rápido

### Inicio Rápido
```bash
# Ejecutar el gestor principal
./app_manager_master.sh
```

### Comandos Directos
```bash
# Mover aplicaciones
sudo ./move_apps_to_external.sh

# Restaurar aplicaciones
sudo ./restore_apps_from_external.sh

# Monitor del sistema
./monitor_external_apps.sh

# Gestión de discos
./disk_manager.sh
```

## 📝 Flujo Recomendado

### 1. Preparación Inicial
1. Conectar ambos discos externos (`BLACK2T` y `8TbSeries`)
2. Ejecutar el gestor de discos para verificar montaje
3. Crear backup completo (opcional pero recomendado)

### 2. Movimiento de Aplicaciones
1. Usar el monitor para identificar aplicaciones grandes
2. Mover aplicaciones paso a paso, empezando por las menos críticas
3. Verificar funcionamiento después de cada movimiento

### 3. Monitoreo Continuo
1. Ejecutar el monitor regularmente
2. Verificar salud de enlaces simbólicos
3. Monitorear espacio liberado

## 🔍 Aplicaciones Recomendadas para Mover

### ✅ Seguras para Mover
- Adobe Creative Cloud y aplicaciones Adobe
- Final Cut Pro, Logic Pro
- Xcode y herramientas de desarrollo
- Unity, Blender (aplicaciones de desarrollo 3D)
- Steam, Epic Games Launcher
- Microsoft Office
- Máquinas virtuales (VirtualBox, VMware, Parallels)
- DaVinci Resolve
- Aplicaciones de diseño (Sketch, Figma)

### ❌ NO Mover
- Aplicaciones del sistema (Safari, Mail, Calendar)
- Utilidades críticas (Disk Utility, Activity Monitor)
- Aplicaciones que uses sin discos externos conectados

## 📊 Monitoreo y Logs

### Archivos de Log
- `move_apps.log` - Log de movimientos de aplicaciones
- `restore_apps.log` - Log de restauraciones
- `disk_mount.log` - Log de montaje de discos
- `automount.log` - Log de automontaje

### Reportes
El monitor puede generar reportes detallados con:
- Estado de discos y espacio
- Conteo de aplicaciones
- Salud de enlaces simbólicos
- Espacio ahorrado

## ⚙️ Configuración Avanzada

### Automontaje en Inicio
```bash
# Configurar automontaje usando el gestor de discos
./disk_manager.sh
# Seleccionar opción 7: "Configurar automontaje en inicio"
```

### Personalizar Lista de Aplicaciones
Editar la variable `RECOMMENDED_APPS` en `move_apps_to_external.sh`:

```bash
RECOMMENDED_APPS=(
    "Tu Aplicación Personalizada"
    "Otra Aplicación"
    # Añadir más aplicaciones aquí
)
```

## 🛠️ Solución de Problemas

### Disco No Montado
```bash
# Usar el gestor de discos
./disk_manager.sh
# Seleccionar "Montar todos los discos"
```

### Enlaces Simbólicos Rotos
```bash
# Usar el monitor para identificar
./monitor_external_apps.sh
# Seleccionar "Verificar estado de enlaces simbólicos"

# Restaurar aplicación específica
sudo ./restore_apps_from_external.sh
```

### Error de Permisos
```bash
# Todos los scripts de movimiento/restauración requieren sudo
sudo ./move_apps_to_external.sh
sudo ./restore_apps_from_external.sh
```

### Verificar Integridad
```bash
# Verificar que una aplicación funciona después del movimiento
open "/Applications/NombreApp.app"

# Verificar enlace simbólico
ls -la "/Applications/NombreApp.app"
```

## 🔐 Seguridad y Backups

### Backups Automáticos
- Cada aplicación se respalda automáticamente antes de mover
- Los backups se almacenan en `/Volumes/8TbSeries/Applications_macmini`
- Se puede crear un backup completo usando el menú principal

### Restauración de Emergencia
Si algo sale mal, siempre puedes restaurar desde los backups:

```bash
# Restaurar aplicación específica
sudo cp -R "/Volumes/8TbSeries/Applications_macmini/NombreApp.app" "/Applications/"

# Eliminar enlace roto si existe
sudo rm "/Applications/NombreApp.app"
```

## 📈 Beneficios

- **Espacio Liberado**: Pueden liberarse decenas de GB dependiendo de las aplicaciones
- **Funcionalidad Mantenida**: Las aplicaciones funcionan normalmente
- **Backup Automático**: Protección contra pérdida de datos
- **Monitoreo Continuo**: Estado del sistema siempre visible
- **Reversible**: Proceso completamente reversible

## 💡 Consejos

1. **Empezar Gradual**: Mover pocas aplicaciones al principio
2. **Verificar Funcionamiento**: Probar cada aplicación después de mover
3. **Mantener Discos Conectados**: Para acceso a aplicaciones movidas
4. **Monitoreo Regular**: Usar el monitor para verificar salud del sistema
5. **Backup Antes de Cambios**: Siempre tener backups antes de modificaciones importantes

## 🆘 Soporte

Si encuentras problemas:

1. Verificar logs en `~/Documents/scripts/*.log`
2. Usar el monitor para diagnosticar el estado
3. Restaurar aplicaciones problemáticas desde backup
4. Verificar que ambos discos estén montados y funcionando

---

**Autor**: Script generado para optimización de espacio en Mac mini  
**Fecha**: Junio 2025  
**Versión**: 1.0

## 🖥️ Gestión Multi-Máquina

### Configurar para Nueva Máquina

1. **Método Automático (Recomendado)**
```bash
# Ejecutar el actualizador
./update_machine_config.sh

# Seleccionar la nueva máquina:
# 1. Mac Mini (macmini)
# 2. Mac Studio (macstudio) 
# 3. Mac Pro (macpro)
# 4. Personalizado
```

2. **Verificar Configuración**
```bash
# Ver configuración actual
./machine_config.sh

# Verificar que todos los scripts están actualizados
./app_manager_master.sh
```

### Estructura de Directorios por Máquina

```
/Volumes/BLACK2T/
├── Applications_macmini/
├── Applications_macstudio/
├── Applications_macpro/
├── UserData_usuario_macmini/
├── UserData_usuario_macstudio/
└── UserData_usuario_macpro/

/Volumes/8TbSeries/
├── Applications_macmini/
├── Applications_macstudio/
├── Applications_macpro/
├── UserData_usuario_backup_macmini/
├── UserData_usuario_backup_macstudio/
└── UserData_usuario_backup_macpro/
```

### Beneficios del Sistema Multi-Máquina

- ✅ **Separación clara** entre configuraciones de diferentes Macs
- ✅ **Sin conflictos** al usar los mismos discos en múltiples máquinas
- ✅ **Backups independientes** para cada configuración
- ✅ **Fácil migración** de configuraciones entre máquinas
- ✅ **Logs separados** para mejor diagnóstico
- ✅ **Escalabilidad** para agregar más máquinas

### Casos de Uso Comunes

**Escenario 1: Mac Mini + Mac Studio**
- Mac Mini: aplicaciones diarias y desarrollo
- Mac Studio: aplicaciones profesionales y media

**Escenario 2: Migración de Máquina**
```bash
# En la máquina antigua: crear backup completo
./app_manager_master.sh
# Opción 8: Crear backup completo

# En la máquina nueva: configurar y restaurar
./update_machine_config.sh
./app_manager_master.sh
# Opción 4: Restaurar aplicaciones
```
