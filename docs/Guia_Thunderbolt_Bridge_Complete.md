# Guía Completa: Configuración Thunderbolt Bridge entre Mac Studio y Mac Mini

## 📋 Resumen
Esta guía configura una conexión Thunderbolt directa entre Mac Studio y Mac Mini para:
- ✅ **Share Screen optimizado** con resolución dinámica
- ✅ **Acceso SSD de alta velocidad** (~35 Gbps comprobados)
- ✅ **Configuración persistente** que se mantiene al reiniciar

---

## 🔧 Hardware Requerido
- Mac Studio y Mac Mini con puertos Thunderbolt 3/4
- Cable Thunderbolt 3/4 o USB-C certificado para datos
- SSD externo conectado a Mac Studio (opcional)

---

## ⚙️ Configuración Inicial

### **Paso 1: Configuración de Red - Mac Studio**
```bash
# IP Manual para Mac Studio
Preferencias del Sistema > Red > Thunderbolt Bridge
- Configurar IPv4: Manualmente
- IP: 192.168.100.1
- Máscara de subred: 255.255.255.0
- Router: (dejar vacío)
```

### **Paso 2: Configuración de Red - Mac Mini**
```bash
# IP Manual para Mac Mini  
Preferencias del Sistema > Red > Thunderbolt Bridge
- Configurar IPv4: Manualmente
- IP: 192.168.100.2
- Máscara de subred: 255.255.255.0
- Router: (dejar vacío)
```

### **Paso 3: Verificar Conectividad**
```bash
# Desde Mac Mini
ping 192.168.100.1

# Desde Mac Studio
ping 192.168.100.2

# Prueba de velocidad (opcional)
iperf3 -c 192.168.100.1  # desde Mac Mini
```

---

## 🖥️ Configuración Share Screen

### **En Mac Studio (Host):**
```bash
Preferencias del Sistema > Compartir
✅ Activar "Compartir pantalla"
✅ Permitir acceso para usuarios específicos
```

### **En Mac Mini (Cliente):**
```bash
1. Abrir "Compartir Pantalla"
2. Conectar a: 192.168.100.1
3. Verificar: "Resolución dinámica disponible"
4. Usar: Ver > Resolución dinámica ✅
```

**Resultado esperado:**
- Sin mensaje "conexión estándar"
- Redimensionamiento automático de resolución
- Velocidad óptima y baja latencia

---

## 💾 Configuración SSD Compartido

### **En Mac Studio:**
```bash
Preferencias del Sistema > Compartir
✅ Activar "Compartir archivos"
➕ Agregar carpeta: /Volumes/BLACK2T
👤 Usuarios: Agregar usuario Mac Mini
🔒 Permisos: Lectura y escritura
```

### **En Mac Mini:**
#### **Opción A: Manual**
```bash
# Crear punto de montaje
sudo mkdir -p /Volumes/BLACK2T_Remote

# Montar SSD
mount -t smbfs //tu_usuario@192.168.100.1/BLACK2T /Volumes/BLACK2T_Remote
```

#### **Opción B: Script Automático**
```bash
# Ejecutar script de diagnóstico y montaje
./mount_remote_ssd.sh
```

---

## 🚀 Scripts de Automatización

### **Script 1: Diagnóstico Thunderbolt**
```bash
# Ubicación: /Users/angelsalazar/Documents/scripts/thunderbolt_diagnostics.sh
./thunderbolt_diagnostics.sh

# Funciones:
- Verifica interfaces de red
- Diagnostica conectividad Thunderbolt  
- Prueba velocidad de conexión
- Sugiere soluciones automáticas
```

### **Script 2: Montaje SSD Automático**
```bash
# Ubicación: /Users/angelsalazar/Documents/scripts/mount_remote_ssd.sh
./mount_remote_ssd.sh

# Funciones:
- Verifica conectividad via Thunderbolt
- Monta SSD automáticamente
- Prueba velocidad de transferencia
- Maneja usuarios con espacios en nombre
```

---

## 📊 Rendimiento Esperado

### **Velocidades Comprobadas:**
- **Throughput de red:** ~35.8 Gbps
- **Transferencia real:** ~1-3 GB/s (dependiendo del SSD)
- **Latencia:** <5ms
- **Share Screen:** 60 FPS, resolución completa

### **Comparación con otras conexiones:**
| Conexión | Velocidad | Latencia | Calidad |
|----------|-----------|----------|---------|
| **Thunderbolt Bridge** | 35+ Gbps | <5ms | ⭐⭐⭐⭐⭐ |
| Ethernet Gigabit | 1 Gbps | ~10ms | ⭐⭐⭐ |
| WiFi 6 | 2-3 Gbps | ~20ms | ⭐⭐⭐ |
| WiFi 5 | 500 Mbps | ~30ms | ⭐⭐ |

---

## 🔄 Uso Diario

### **Iniciar Sesión:**
1. **Encender ambos Macs** (conexión automática)
2. **Abrir Share Screen** en Mac Mini
3. **Conectar a:** `192.168.100.1`
4. **Montar SSD** (si necesario): `./mount_remote_ssd.sh`

### **Verificar Estado:**
```bash
# Comprobar conectividad
ping 192.168.100.1

# Ver dispositivos montados
mount | grep BLACK2T

# Verificar velocidad (opcional)
iperf3 -c 192.168.100.1
```

---

## 🛠️ Solución de Problemas

### **Problema: "Resolución dinámica no disponible"**
**Solución:**
- Verificar IPs: Mac Studio (192.168.100.1), Mac Mini (192.168.100.2)
- Probar ping entre ambos dispositivos
- Ejecutar `./thunderbolt_diagnostics.sh`

### **Problema: SSD no se monta**
**Solución:**
- Verificar "Compartir archivos" habilitado en Mac Studio
- Comprobar que BLACK2T esté en carpetas compartidas
- Ejecutar `./mount_remote_ssd.sh` para diagnóstico

### **Problema: Conexión lenta**
**Solución:**
- Probar `iperf3 -c 192.168.100.1` (debe ser >30 Gbps)
- Verificar cable Thunderbolt certificado
- Revisar que no haya interferencia de otras conexiones

### **Problema: "Alto rango dinámico no disponible"**
**Solución:**
- En Mac Studio: Preferencias > Pantallas > Desactivar HDR temporalmente
- O ignorar mensaje (no afecta funcionalidad)

---

## 📝 Comandos de Referencia Rápida

```bash
# Verificar configuración de red
networksetup -getinfo "Thunderbolt Bridge"

# Configurar IP manual (ejemplo Mac Mini)
sudo networksetup -setmanual "Thunderbolt Bridge" 192.168.100.2 255.255.255.0

# Montar SSD manualmente
mount -t smbfs //usuario@192.168.100.1/BLACK2T /Volumes/BLACK2T_Remote

# Desmontar SSD
sudo umount /Volumes/BLACK2T_Remote

# Probar velocidad
iperf3 -c 192.168.100.1

# Ver dispositivos Thunderbolt
system_profiler SPThunderboltDataType
```

---

## ✅ Configuración Exitosa - Checklist Final

- [ ] **Red configurada:** IPs manuales asignadas y ping funcional
- [ ] **Share Screen:** Resolución dinámica disponible
- [ ] **SSD accesible:** Montaje exitoso via Thunderbolt
- [ ] **Velocidad:** >30 Gbps en pruebas iperf3
- [ ] **Scripts:** Ambos scripts ejecutables y funcionales
- [ ] **Persistencia:** Configuración se mantiene tras reinicio

---

## 🎯 Beneficios Finales

1. **Una sola conexión física** para todo
2. **Máximo rendimiento** en ambos casos de uso
3. **Configuración persistente** sin reconfiguración
4. **Scripts automatizados** para diagnóstico y montaje
5. **Velocidad comprobada** de 35+ Gbps

---

**Fecha de creación:** 4 de junio de 2025  
**Configuración comprobada:** Mac Studio + Mac Mini via Thunderbolt Bridge  
**Velocidad verificada:** 35.8 Gbps
