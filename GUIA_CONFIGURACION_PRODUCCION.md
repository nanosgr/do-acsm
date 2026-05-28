# Guía de Configuración y Actualización en Producción

## Configuración de Odoo (odoo.conf)

### Ubicación del archivo

El archivo de configuración debe estar en:

```
odoo/custom/conf.d/01-odoo.conf
```

**Importante**: En Doodba, los archivos en `odoo/custom/conf.d/` se copian durante la
construcción de la imagen Docker, no se montan como volúmenes. Por lo tanto, **cada
cambio en este archivo requiere reconstruir la imagen**.

### Contenido del archivo

```ini
[options]
# Workers configuration (required for longpolling/websocket)
# Must be >= 2 for longpolling to work
workers = 4

# Max cron threads (set to 0 if you have multiple Odoo instances)
max_cron_threads = 1

# Worker limits
limit_memory_hard = 2684354560
limit_memory_soft = 2147483648
limit_request = 8192
limit_time_cpu = 600
limit_time_real = 1200

# Longpolling port (required for websocket support)
gevent_port = 8072
```

### Parámetros explicados

#### Workers

- **`workers = 4`**: Número de procesos HTTP workers
  - Valor recomendado: (CPU cores \* 2) + 1
  - **OBLIGATORIO**: Debe ser >= 2 para que funcione longpolling/websocket
  - Con `workers = 0`: Modo desarrollo, sin longpolling

#### Max Cron Threads

- **`max_cron_threads = 1`**: Número de threads para tareas programadas (cron)
  - Usar `1` para una sola instancia de Odoo
  - Usar `0` si tienes múltiples instancias (para evitar que se ejecuten crons
    duplicados)

#### Worker Limits

- **`limit_memory_hard = 2684354560`** (2.5 GB): Límite duro de memoria por worker

  - Si se excede, el worker se reinicia inmediatamente

- **`limit_memory_soft = 2147483648`** (2 GB): Límite suave de memoria

  - Si se excede, el worker se reinicia después de completar la request actual

- **`limit_request = 8192`**: Número máximo de requests antes de reiniciar el worker

  - Previene memory leaks acumulativos

- **`limit_time_cpu = 600`** (10 minutos): Tiempo máximo de CPU por request

- **`limit_time_real = 1200`** (20 minutos): Tiempo máximo total (wall time) por request

#### Longpolling Port

- **`gevent_port = 8072`**: Puerto para el servicio de websocket/longpolling
  - **CRÍTICO**: Sin este parámetro, Odoo NO levanta el servicio de longpolling
  - Debe coincidir con el puerto configurado en Traefik (ver `prod.yaml`)

### Configuraciones alternativas según recursos del servidor

#### Servidor pequeño (2 CPU, 4GB RAM)

```ini
[options]
workers = 2
max_cron_threads = 1
limit_memory_hard = 1610612736  # 1.5 GB
limit_memory_soft = 1073741824  # 1 GB
limit_request = 8192
limit_time_cpu = 600
limit_time_real = 1200
gevent_port = 8072
```

#### Servidor mediano (4 CPU, 8GB RAM)

```ini
[options]
workers = 4
max_cron_threads = 1
limit_memory_hard = 2684354560  # 2.5 GB
limit_memory_soft = 2147483648  # 2 GB
limit_request = 8192
limit_time_cpu = 600
limit_time_real = 1200
gevent_port = 8072
```

#### Servidor grande (8 CPU, 16GB RAM)

```ini
[options]
workers = 8
max_cron_threads = 2
limit_memory_hard = 2684354560  # 2.5 GB
limit_memory_soft = 2147483648  # 2 GB
limit_request = 8192
limit_time_cpu = 600
limit_time_real = 1200
gevent_port = 8072
```

---

## Proceso de Actualización en Producción

### 1. Realizar cambios en el repositorio local

Edita los archivos necesarios en tu máquina de desarrollo:

```bash
# Ejemplo: editar configuración
nano odoo/custom/conf.d/01-odoo.conf

# O agregar/modificar módulos
nano odoo/custom/src/private/mi_modulo/__manifest__.py
```

### 2. Hacer commit y push

```bash
# Ver cambios
git status

# Agregar archivos
git add odoo/custom/conf.d/01-odoo.conf

# Commit
git commit -m "Actualizar configuración de workers para longpolling"

# Push al repositorio
git push origin master
```

### 3. Actualizar código en el servidor

Conéctate al servidor de producción vía SSH:

```bash
# Ir al directorio del proyecto
cd /opt/do-acsm

# Traer los cambios
git pull
```

### 4. Reconstruir la imagen Docker

**Solo necesitas reconstruir si cambiaste:**

- Archivos en `odoo/custom/conf.d/`
- Archivos en `odoo/custom/src/` (módulos)
- `repos.yaml` o `addons.yaml`
- `pip.txt` u otras dependencias

```bash
# Reconstruir la imagen de Odoo
docker-compose -f prod.yaml build odoo
```

**Nota**: El build puede tomar 5-15 minutos dependiendo de los cambios y la conexión a
internet.

### 5. Recrear el contenedor

```bash
# Detener y eliminar el contenedor actual
docker-compose -f prod.yaml stop odoo
docker-compose -f prod.yaml rm -f odoo

# Crear y levantar el nuevo contenedor
docker-compose -f prod.yaml up -d odoo
```

### 6. Verificar que todo funciona

```bash
# Ver los últimos logs
docker-compose -f prod.yaml logs --tail=100 odoo

# Verificar que el servicio HTTP está corriendo
# Deberías ver: "HTTP service (werkzeug) running on 0.0.0.0:8069"

# Verificar que el servicio de longpolling está corriendo
# Deberías ver: "Evented Service (longpolling) running on 0.0.0.0:8072"

# Verificar que los workers están activos
# Deberías ver líneas como: "Worker WorkerHTTP (26) alive"

# Ver logs en tiempo real (Ctrl+C para salir)
docker-compose -f prod.yaml logs -f odoo
```

### 7. Verificar en el navegador

1. Accede a http://gestion.aeroclubsanmartin.com.ar
2. Verifica que la aplicación carga correctamente
3. Si modificaste módulos, instala/actualiza según sea necesario

---

## Comandos útiles de diagnóstico

### Ver configuración actual de Odoo

```bash
# Ver el archivo de configuración dentro del contenedor
docker-compose -f prod.yaml exec odoo cat /opt/odoo/auto/odoo.conf
```

### Verificar que el puerto 8072 está escuchando

```bash
# Dentro del contenedor
docker-compose -f prod.yaml exec odoo netstat -tuln | grep 8072

# Deberías ver algo como:
# tcp        0      0 0.0.0.0:8072            0.0.0.0:*               LISTEN
```

### Ver procesos de Odoo

```bash
docker-compose -f prod.yaml exec odoo ps aux | grep odoo
```

### Reiniciar solo Odoo (sin rebuild)

```bash
# Reinicio simple (solo reinicia el proceso, no recrea el contenedor)
docker-compose -f prod.yaml restart odoo

# Recrear el contenedor (sin rebuild de imagen)
docker-compose -f prod.yaml up -d odoo
```

### Ver logs de errores

```bash
# Ver logs con filtro
docker-compose -f prod.yaml logs odoo | grep -i error

# Ver logs en tiempo real solo de errores
docker-compose -f prod.yaml logs -f odoo | grep -E "ERROR|CRITICAL|WARNING"
```

---

## Diferencias entre Desarrollo y Producción

### Desarrollo (devel.yaml)

```yaml
# En devel.yaml, el comando sobrescribe el archivo de configuración
command:
  - odoo
  - --workers=0 # ¡Esto sobrescribe workers en conf.d/01-odoo.conf!
  - --dev=reload,qweb,werkzeug,xml
```

**Resultado**:

- No usa workers (modo single-process)
- No tiene longpolling activo
- Auto-recarga de código
- Mejor para desarrollo

### Producción (prod.yaml)

```yaml
# En prod.yaml, NO hay comando
# Por lo tanto, usa la configuración de conf.d/01-odoo.conf
```

**Resultado**:

- Usa workers según configuración
- Longpolling activo en puerto 8072
- Sin auto-recarga
- Optimizado para producción

---

## Troubleshooting

### El websocket no funciona después de actualizar

1. Verifica que el archivo `01-odoo.conf` tiene `gevent_port = 8072`
2. Verifica que reconstruiste la imagen: `docker-compose -f prod.yaml build odoo`
3. Verifica que recreaste el contenedor: `docker-compose -f prod.yaml up -d odoo`
4. Verifica los logs: `docker-compose -f prod.yaml logs odoo | grep longpolling`

### Error: "ContainerConfig" al hacer up

Este es un bug conocido de `docker-compose` 1.29.2. Solución:

```bash
docker-compose -f prod.yaml stop odoo
docker-compose -f prod.yaml rm -f odoo
docker-compose -f prod.yaml up -d odoo
```

### Los cambios en conf.d no se aplican

Recuerda que necesitas **rebuild** la imagen:

```bash
docker-compose -f prod.yaml build odoo
docker-compose -f prod.yaml stop odoo
docker-compose -f prod.yaml rm -f odoo
docker-compose -f prod.yaml up -d odoo
```

### Odoo consume mucha memoria

Ajusta los límites en `01-odoo.conf`:

- Reduce `workers`
- Reduce `limit_memory_soft` y `limit_memory_hard`
- Reduce `limit_request`

### Los crons se ejecutan múltiples veces

Si tienes múltiples instancias de Odoo, configura:

```ini
max_cron_threads = 0
```

En todas las instancias excepto una.

---

## Checklist de actualización

- [ ] Cambios realizados en repositorio local
- [ ] Commit y push al repositorio remoto
- [ ] SSH al servidor de producción
- [ ] `cd /opt/do-acsm`
- [ ] `git pull`
- [ ] `docker-compose -f prod.yaml build odoo` (si cambió código/config)
- [ ] `docker-compose -f prod.yaml stop odoo`
- [ ] `docker-compose -f prod.yaml rm -f odoo`
- [ ] `docker-compose -f prod.yaml up -d odoo`
- [ ] `docker-compose -f prod.yaml logs --tail=100 odoo`
- [ ] Verificar en logs: "HTTP service" y "Evented Service (longpolling)"
- [ ] Probar en navegador
- [ ] Verificar websocket/longpolling funciona (módulo Discuss)

---

## Referencias

- Documentación Doodba: https://github.com/Tecnativa/doodba
- Documentación Odoo Workers:
  https://www.odoo.com/documentation/18.0/administration/on_premise/deploy.html#worker-number-calculation
- Configuración Traefik: Ver `prod.yaml` líneas 33-75 para configuración de longpolling
