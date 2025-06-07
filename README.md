# 🎛️ Asistente de Administración del Disco Interno

**Sistema completo e inteligente para optimizar el espacio del disco interno de tu Mac**

## 📋 Descripción

Este asistente te permite administrar eficientemente el espacio de tu disco interno mediante:
- Migración automática de aplicaciones a discos externos
- Sistema de estado inteligente con seguimiento automático
- Limpieza de caches y archivos temporales
- Gestión de datos de usuario con enlaces simbólicos
- Monitoreo y restauración automática
- Soporte multi-máquina

## 🎯 Características Principales

### ✨ Sistema de Estado Automatizado
- **Seguimiento inteligente** de qué está migrado y qué no
- **Detección automática** de cambios y necesidad de sincronización
- **Auto-corrección** de enlaces simbólicos rotos
- **Historial completo** de todas las migraciones

### 🔄 Migración Inteligente
- **Prevención de duplicación** - No migra lo que ya está migrado
- **Sincronización automática** - Mantiene actualizado el contenido
- **Backups automáticos** - Protege tus datos durante la migración
- **Verificación de integridad** - Asegura que todo funcione correctamente

### 🛡️ Seguridad y Confiabilidad
- **Lista blanca de aplicaciones** - Solo mueve aplicaciones seguras
- **Verificaciones previas** - Confirma espacio y permisos
- **Rollback automático** - Restaura en caso de problemas
- **Logs detallados** - Registro completo de todas las operaciones

## 📁 Estructura del Asistente

```
asistente_disco_interno/
├── scripts/           # Scripts principales del sistema
├── docs/             # Documentación completa
├── config/           # Archivos de configuración
├── logs/             # Registros de operaciones
├── backups/          # Backups automáticos
├── utils/            # Utilidades auxiliares
├── demos/            # Scripts de demostración
└── README.md         # Este archivo
```

## 🚀 Inicio Rápido

### 1. Instalación
```bash
cd asistente_disco_interno/scripts
chmod +x *.sh
```

### 2. Configuración Inicial
```bash
# Configurar para tu máquina
./machine_config.sh

# Verificar discos externos
./disk_manager.sh
```

### 3. Uso Principal
```bash
# Menú principal completo
./app_manager_master.sh

# Migración integral de contenido de usuario
./move_user_content.sh

# Ver estado del sistema
source migration_state.sh && show_migration_status
```

## 📊 Scripts Principales

### 🎛️ `app_manager_master.sh`
**Script principal con menú completo**
- Limpieza de caches (sin riesgo)
- Migración integral de contenido
- Gestión de aplicaciones
- Monitoreo del sistema
- Ver estado detallado

### 📁 `move_user_content.sh`
**Migración inteligente de contenido de usuario**
- Documents, Downloads, Pictures, Movies, Music
- Caches y herramientas de desarrollo
- Estado automático y sincronización
- Backups y enlaces simbólicos

### 🎯 `migration_state.sh`
**Sistema de estado automatizado**
- Seguimiento de migraciones
- Detección de cambios
- Auto-actualización
- Verificación de integridad

### 🧹 `clean_system_caches.sh`
**Limpieza segura del sistema**
- Caches de aplicaciones
- Archivos temporales
- Logs antiguos
- Papelera automática

### 💾 `disk_manager.sh`
**Gestión de discos externos**
- Montaje automático
- Verificación de salud
- Configuración de automontaje
- Resolución de problemas

## ⚙️ Configuración Multi-Máquina

El sistema soporta múltiples Macs con configuración automática:

- **Mac Mini**: `_macmini` (predeterminado)
- **Mac Studio**: `_macstudio`
- **Mac Pro**: `_macpro`

```bash
# Cambiar configuración automáticamente
./update_machine_config.sh
```

## 🔧 Solución de Problemas

### Disco No Montado
```bash
./disk_manager.sh
# Seleccionar "Montar todos los discos"
```

### Enlaces Simbólicos Rotos
```bash
./monitor_external_apps.sh
# O usar el sistema de estado para auto-corrección
```

### Ver Estado Completo
```bash
# Desde el menú principal
./app_manager_master.sh
# Opción 9: "Ver estado detallado de migración"
```

## 📈 Beneficios del Sistema

### Espacio Liberado
- **Aplicaciones grandes**: 50-200GB típicamente
- **Contenido de usuario**: 10-100GB según uso
- **Caches y temporales**: 5-20GB regularmente

### Rendimiento
- **Disco interno más rápido** - Menos fragmentación
- **Acceso transparente** - Enlaces simbólicos funcionan igual
- **Backup automático** - Protección de datos

### Mantenimiento
- **Automatizado** - Mínima intervención manual
- **Inteligente** - Sabe qué hacer en cada situación
- **Confiable** - Sistema probado y robusto

## 🎓 Mejores Prácticas

1. **Ejecutar limpieza regularmente** (opción 1 del menú)
2. **Verificar estado mensualmente** (opción 9 del menú)
3. **Mantener discos externos siempre montados**
4. **Revisar logs en caso de problemas**
5. **Hacer backup del archivo de estado**

## 🤝 Integración con MCP (Model Context Protocol)

Este asistente está diseñado para interactuar con el sistema a través del **Model Context Protocol (MCP)**, lo que permite una gestión de tareas más avanzada y automatizada. MCP facilita la comunicación con servidores externos que proporcionan herramientas y recursos adicionales, extendiendo las capacidades del asistente.

### 🤖 Manejo de Tareas con MCP

El asistente puede recibir y ejecutar tareas complejas a través de comandos enviados por un cliente MCP. Esto permite:

- **Automatización de flujos de trabajo**: Encadenar múltiples operaciones del asistente en una sola tarea.
- **Interacción con herramientas externas**: Utilizar herramientas proporcionadas por otros servidores MCP para complementar las funcionalidades del asistente.
- **Monitoreo y control remoto**: Gestionar el estado del disco y las migraciones desde una interfaz externa compatible con MCP.

### ⚙️ Servidor `disk-assistant`

El asistente incluye un servidor MCP llamado `disk-assistant`, que expone las funcionalidades principales como herramientas accesibles a través de MCP. Esto significa que puedes:

- **Ejecutar scripts**: Invocar scripts como `app_manager_master.sh` o `move_user_content.sh` directamente a través de comandos MCP.
- **Acceder a recursos**: Obtener información del estado del sistema o logs a través de recursos MCP.

**Ejemplo de uso (conceptual):**

```xml
<use_mcp_tool>
<server_name>disk-assistant</server_name>
<tool_name>execute_script</tool_name>
<arguments>
  {
    "script_name": "app_manager_master.sh",
    "arguments": ["--clean-caches"]
  }
</arguments>
</use_mcp_tool>
```
*(Nota: El ejemplo anterior es conceptual y la implementación real de las herramientas MCP puede variar.)*

## 📞 Soporte

- **Documentación**: Ver carpeta `docs/`
- **Logs**: Carpeta `logs/` para diagnóstico
- **Demos**: Carpeta `demos/` para pruebas
- **Estado**: `migration_state.json` para información detallada

---

**Versión**: 2.0 (Sistema con Estado Automatizado)  
**Fecha**: Junio 2025  
**Compatibilidad**: macOS 10.15+ (Catalina y superiores)  
**Soporte**: Mac Mini, Mac Studio, Mac Pro con discos externos
