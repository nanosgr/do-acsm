# Guía de Despliegue en Producción — do-acsm (Doodba / Odoo 18.0)

**Proyecto**: Aero Club San Martín **Dominio**: aeroclubsanmartin.com.ar **Stack**: Odoo
18.0 · PostgreSQL 16 · Traefik 2.11 · Docker Compose

---

## Índice

1. [Requisitos del servidor](#1-requisitos-del-servidor)
2. [Preparación del servidor](#2-preparación-del-servidor)
3. [Clonar el repositorio en producción](#3-clonar-el-repositorio-en-producción)
4. [Configurar los archivos de entorno](#4-configurar-los-archivos-de-entorno)
5. [Levantar el reverse proxy (Traefik)](#5-levantar-el-reverse-proxy-traefik)
6. [Primer despliegue de Odoo](#6-primer-despliegue-de-odoo)
7. [Verificación post-despliegue](#7-verificación-post-despliegue)
8. [Proceso de actualización](#8-proceso-de-actualización)
9. [Backups y restauración](#9-backups-y-restauración)
10. [Monitoreo y logs](#10-monitoreo-y-logs)
11. [Mejores prácticas de seguridad](#11-mejores-prácticas-de-seguridad)
12. [Resolución de problemas comunes](#12-resolución-de-problemas-comunes)

---

## 1. Requisitos del servidor

### Hardware mínimo recomendado

| Recurso | Mínimo    | Recomendado |
| ------- | --------- | ----------- |
| CPU     | 2 vCPU    | 4 vCPU      |
| RAM     | 4 GB      | 8 GB        |
| Disco   | 40 GB SSD | 80 GB SSD   |
| Red     | 100 Mbps  | 1 Gbps      |

### Software

- **OS**: Ubuntu 22.04 LTS o Debian 12 (recomendado)
- **Docker Engine**: 24.x o superior
- **Docker Compose**: v2.x (plugin integrado a Docker)
- **Git**: 2.x
- **Python**: 3.10+ (solo para Invoke en dev; en prod no es estrictamente necesario)

---

## 2. Preparación del servidor

### 2.1 Instalar Docker Engine

```bash
# Actualizar paquetes del sistema
sudo apt update && sudo apt upgrade -y

# Instalar dependencias
sudo apt install -y ca-certificates curl gnupg lsb-release

# Agregar repositorio oficial de Docker
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Agregar usuario al grupo docker (evita usar sudo)
sudo usermod -aG docker $USER
newgrp docker

# Verificar instalación
docker --version
docker compose version
```

### 2.2 Configurar firewall

```bash
sudo ufw allow 22/tcp     # SSH
sudo ufw allow 80/tcp     # HTTP  (necesario para Let's Encrypt)
sudo ufw allow 443/tcp    # HTTPS
sudo ufw enable
sudo ufw status
```

> **Importante**: No exponer el puerto 8069 ni 8072 directamente. Traefik es el único
> punto de entrada.

### 2.3 Configurar el DNS

Antes de continuar, el registro DNS del dominio debe apuntar a la IP del servidor:

```
aeroclubsanmartin.com.ar  A  <IP_DEL_SERVIDOR>
```

Verificar propagación:

```bash
dig aeroclubsanmartin.com.ar A +short
```

### 2.4 Crear directorio de trabajo

```bash
sudo mkdir -p /opt/doodba
sudo chown $USER:$USER /opt/doodba
```

---

## 3. Clonar el repositorio en producción

```bash
cd /opt/doodba

# Clonar el repositorio del proyecto
git clone <URL_DEL_REPOSITORIO> do-acsm
cd do-acsm

# Verificar que estás en la rama correcta
git branch
git log --oneline -5
```

> **Nota**: Si el repositorio es privado, configurar una deploy key de SSH en el
> servidor antes de clonar.

### 3.1 Configurar deploy key (si el repo es privado)

```bash
# Generar clave SSH en el servidor
ssh-keygen -t ed25519 -C "deploy@aeroclubsanmartin" -f ~/.ssh/deploy_acsm

# Mostrar la clave pública para agregarla en GitHub/GitLab
cat ~/.ssh/deploy_acsm.pub

# Configurar SSH para usar esta clave con el repositorio
cat >> ~/.ssh/config << 'EOF'
Host github.com
  IdentityFile ~/.ssh/deploy_acsm
  IdentitiesOnly yes
EOF
```

---

## 4. Configurar los archivos de entorno

Los archivos en `.docker/` contienen credenciales sensibles. **Nunca deben commitearse
al repositorio.** Verificar que estén en `.gitignore`.

### 4.1 Archivo `.docker/odoo.env`

```bash
cat > .docker/odoo.env << 'EOF'
ADMIN_PASSWORD=<CONTRASEÑA_MAESTRA_SEGURA>
EOF
```

> **Importante**: Cambiar `ADMIN_PASSWORD` por una contraseña fuerte (mínimo 16
> caracteres, combinando letras, números y símbolos). Esta es la contraseña maestra de
> Odoo que protege operaciones críticas como restaurar backups.

### 4.2 Archivo `.docker/db-access.env`

```bash
cat > .docker/db-access.env << 'EOF'
PGPASSWORD=<CONTRASEÑA_POSTGRES_SEGURA>
EOF
```

### 4.3 Archivo `.docker/db-creation.env`

```bash
cat > .docker/db-creation.env << 'EOF'
POSTGRES_PASSWORD=<MISMA_CONTRASEÑA_POSTGRES>
EOF
```

> Las contraseñas en `db-access.env` y `db-creation.env` deben ser **idénticas**.

### 4.4 Verificar permisos de los archivos de entorno

```bash
chmod 600 .docker/*.env
ls -la .docker/
```

---

## 5. Levantar el reverse proxy (Traefik)

Traefik corre como un stack independiente. Debe iniciarse **antes** que Odoo.

### 5.1 Crear la red compartida

```bash
docker network create inverseproxy_shared
```

### 5.2 Preparar volumen para certificados TLS

```bash
docker volume create traefik-certificates
```

### 5.3 Iniciar Traefik

El archivo `docs/inverseproxy.yaml` contiene la configuración del reverse proxy:

```bash
# Desde el directorio del proyecto
docker compose -f docs/inverseproxy.yaml up -d

# Verificar que está corriendo
docker compose -f docs/inverseproxy.yaml ps

# Ver logs iniciales
docker compose -f docs/inverseproxy.yaml logs -f --tail=50
```

Traefik se encargará automáticamente de:

- Redirigir HTTP → HTTPS
- Solicitar y renovar certificados Let's Encrypt
- Enrutar el tráfico a Odoo según las reglas configuradas en `prod.yaml`

### 5.4 Verificar conectividad HTTP

```bash
# Debe responder con redirección 301 a HTTPS
curl -I http://aeroclubsanmartin.com.ar
```

---

## 6. Primer despliegue de Odoo

### 6.1 Construir la imagen Docker

```bash
cd /opt/doodba/do-acsm

# Construir la imagen personalizada de Odoo
docker compose -f prod.yaml build --no-cache

# (Opcional) verificar que la imagen fue creada
docker images | grep acsm
```

### 6.2 Iniciar la base de datos

```bash
# Iniciar solo el servicio de base de datos primero
docker compose -f prod.yaml up -d db

# Esperar que PostgreSQL esté listo
docker compose -f prod.yaml logs db --tail=20
```

### 6.3 Inicializar la base de datos de Odoo

```bash
# Instalar Odoo con los módulos base (primera vez)
docker compose -f prod.yaml run --rm odoo \
  odoo --stop-after-init \
  -d acsm \
  -i base,l10n_ar,account \
  --without-demo=all
```

### 6.4 Levantar todos los servicios

```bash
docker compose -f prod.yaml up -d

# Verificar estado
docker compose -f prod.yaml ps

# Seguir los logs
docker compose -f prod.yaml logs -f odoo
```

### 6.5 Verificar acceso

```bash
# Debe responder 200 OK con HTTPS
curl -I https://aeroclubsanmartin.com.ar/web/login
```

Acceder desde el navegador a `https://aeroclubsanmartin.com.ar` y completar la
configuración inicial de Odoo.

---

## 7. Verificación post-despliegue

Lista de verificación después de cada despliegue:

- [ ] El sitio responde en `https://aeroclubsanmartin.com.ar`
- [ ] La redirección HTTP → HTTPS funciona
- [ ] El certificado TLS es válido
      (`curl -v https://aeroclubsanmartin.com.ar 2>&1 | grep "SSL certificate"`)
- [ ] El login de Odoo funciona
- [ ] Las notificaciones de bus (WebSocket) funcionan: verificar que no haya errores en
      la consola del navegador relacionados con `/websocket`
- [ ] Los módulos requeridos están instalados y actualizados
- [ ] Los workers de Odoo están respondiendo (revisar logs)
- [ ] La base de datos tiene los backups automáticos configurados

---

## 8. Proceso de actualización

### 8.1 Actualizar el código

```bash
cd /opt/doodba/do-acsm

# Traer los últimos cambios
git fetch origin
git pull origin master

# Revisar qué cambió
git log --oneline HEAD@{1}..HEAD
```

### 8.2 Reconstruir la imagen si hay cambios en Dockerfile o addons

```bash
docker compose -f prod.yaml build
```

### 8.3 Actualizar módulos con cambios en el código

```bash
# Detener Odoo (la base de datos sigue corriendo)
docker compose -f prod.yaml stop odoo

# Actualizar módulos específicos
docker compose -f prod.yaml run --rm odoo \
  odoo --stop-after-init \
  -d acsm \
  -u nombre_modulo

# O actualizar todos los módulos instalados
docker compose -f prod.yaml run --rm odoo \
  odoo --stop-after-init \
  -d acsm \
  -u all

# Reiniciar Odoo
docker compose -f prod.yaml up -d odoo
```

### 8.4 Actualizar el template de Doodba (copier)

Cuando hay una nueva versión del template `Tecnativa/doodba-copier-template`:

```bash
# En el entorno de DESARROLLO (nunca en producción directamente)
copier update --trust

# Revisar los cambios generados
git diff

# Resolver conflictos si los hay, luego hacer commit
git add .
git commit -m "Actualizar template Doodba a vX.Y.Z"

# Desplegar en producción recién después del commit y las pruebas
```

> **Regla de oro**: Nunca ejecutar `copier update` directamente en el servidor de
> producción. Hacerlo siempre en desarrollo, probar, hacer commit y luego hacer
> `git pull` en producción.

### 8.5 Actualizar Traefik

```bash
cd /opt/doodba/do-acsm

# Editar docs/inverseproxy.yaml para cambiar la versión de imagen si es necesario
# Luego:
docker compose -f docs/inverseproxy.yaml pull
docker compose -f docs/inverseproxy.yaml up -d
```

---

## 9. Backups y restauración

### 9.1 Backup manual desde la interfaz de Odoo

Odoo incluye un gestor de backups en `/web/database/manager`. Requiere la contraseña
maestra (`ADMIN_PASSWORD`). Descarga un archivo `.zip` con la base de datos y el
filestore.

### 9.2 Backup manual desde línea de comandos

```bash
# Backup de la base de datos PostgreSQL
docker compose -f prod.yaml exec db \
  pg_dump -U odoo -Fc acsm > /opt/backups/acsm_$(date +%Y%m%d_%H%M%S).dump

# Backup del filestore (archivos adjuntos)
docker run --rm \
  -v do-acsm_filestore:/data \
  -v /opt/backups:/backup \
  alpine tar czf /backup/filestore_$(date +%Y%m%d_%H%M%S).tar.gz -C /data .
```

### 9.3 Script de backup automático

Crear `/opt/scripts/backup-acsm.sh`:

```bash
#!/bin/bash
set -e

BACKUP_DIR="/opt/backups/acsm"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

mkdir -p "$BACKUP_DIR"

# Backup PostgreSQL
docker compose -f /opt/doodba/do-acsm/prod.yaml exec -T db \
  pg_dump -U odoo -Fc acsm > "$BACKUP_DIR/db_${DATE}.dump"

# Backup filestore
docker run --rm \
  -v do-acsm_filestore:/data \
  -v "$BACKUP_DIR":/backup \
  alpine tar czf "/backup/filestore_${DATE}.tar.gz" -C /data .

# Eliminar backups más viejos que 30 días
find "$BACKUP_DIR" -name "*.dump" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete

echo "[$DATE] Backup completado en $BACKUP_DIR"
```

```bash
chmod +x /opt/scripts/backup-acsm.sh

# Agregar al crontab (backup diario a las 2 AM)
crontab -e
# Agregar:
# 0 2 * * * /opt/scripts/backup-acsm.sh >> /var/log/backup-acsm.log 2>&1
```

### 9.4 Restauración de backup

```bash
# 1. Detener Odoo
docker compose -f prod.yaml stop odoo

# 2. Restaurar la base de datos
docker compose -f prod.yaml exec -T db \
  pg_restore -U odoo -d acsm --clean /backup/db_YYYYMMDD_HHMMSS.dump

# 3. Restaurar el filestore
docker run --rm \
  -v do-acsm_filestore:/data \
  -v /opt/backups/acsm:/backup \
  alpine sh -c "rm -rf /data/* && tar xzf /backup/filestore_YYYYMMDD_HHMMSS.tar.gz -C /data"

# 4. Reiniciar Odoo
docker compose -f prod.yaml up -d odoo
```

---

## 10. Monitoreo y logs

### 10.1 Ver logs en tiempo real

```bash
# Logs de Odoo
docker compose -f prod.yaml logs -f odoo

# Logs de PostgreSQL
docker compose -f prod.yaml logs -f db

# Logs de Traefik
docker compose -f docs/inverseproxy.yaml logs -f traefik
```

### 10.2 Ver el estado de los contenedores

```bash
docker compose -f prod.yaml ps
docker stats --no-stream
```

### 10.3 Verificar uso de disco

```bash
# Tamaño de volúmenes Docker
docker system df -v

# Espacio en disco del servidor
df -h /
```

### 10.4 Verificar certificado TLS

```bash
# Ver fecha de vencimiento del certificado
echo | openssl s_client -connect aeroclubsanmartin.com.ar:443 2>/dev/null \
  | openssl x509 -noout -dates
```

---

## 11. Mejores prácticas de seguridad

### 11.1 Credenciales

- **Cambiar contraseñas por defecto**: Las contraseñas de `odoo.env`, `db-access.env` y
  `db-creation.env` que vienen del template (`odoo`, etc.) deben reemplazarse
  inmediatamente por valores únicos y seguros.
- **ADMIN_PASSWORD**: Usar una contraseña maestra fuerte (20+ caracteres). Esta
  contraseña protege el gestor de bases de datos en `/web/database/manager`.
- **Nunca commitear `.docker/*.env`** al repositorio Git.

### 11.2 Acceso al gestor de base de datos

Por defecto, `/web/database/manager` es accesible públicamente. Para deshabilitarlo en
producción, agregar en `.docker/odoo.env`:

```bash
LIST_DB=false
```

Esto ya está configurado en `prod.yaml` (`LIST_DB: "false"`), pero es bueno verificarlo.

### 11.3 Deshabilitar acceso directo a PostgreSQL

El `postgres_exposed: false` en `.copier-answers.yml` ya asegura que PostgreSQL no
exponga su puerto fuera de la red Docker. Verificar que no haya mapeo de puerto 5432 en
`prod.yaml`.

### 11.4 Mantener el sistema actualizado

```bash
# Actualizaciones de seguridad del OS
sudo apt update && sudo apt upgrade -y

# Revisar imágenes Docker con vulnerabilidades conocidas
docker scout quickview  # requiere Docker Scout
```

### 11.5 Acceso SSH al servidor

```bash
# Deshabilitar login por contraseña (solo claves SSH)
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart sshd
```

### 11.6 Rotación de logs de Docker

Crear `/etc/docker/daemon.json`:

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "50m",
    "max-file": "5"
  }
}
```

```bash
sudo systemctl restart docker
```

---

## 12. Resolución de problemas comunes

### Traefik no genera el certificado TLS

1. Verificar que el DNS apunta a la IP del servidor correcta
2. Verificar que el puerto 80 está abierto (necesario para el challenge HTTP-01)
3. Ver logs de Traefik:
   `docker compose -f docs/inverseproxy.yaml logs traefik | grep -i "acme\|cert\|error"`

### Odoo no arranca (error de base de datos)

```bash
# Ver logs de error
docker compose -f prod.yaml logs odoo | tail -50

# Verificar que PostgreSQL está corriendo
docker compose -f prod.yaml ps db

# Intentar conectar manualmente
docker compose -f prod.yaml exec db psql -U odoo -d acsm -c "SELECT version();"
```

### Error "inverseproxy_shared network not found"

```bash
# La red debe crearse antes de levantar Odoo
docker network create inverseproxy_shared
docker compose -f prod.yaml up -d
```

### WebSocket no funciona (notificaciones de bus caídas)

Verificar que el router de longpolling está activo en Traefik:

```bash
# Ver las reglas registradas en Traefik
curl -s http://localhost:8080/api/http/routers 2>/dev/null | python3 -m json.tool | grep longpolling
```

Verificar que Odoo tiene `ODOO_BUS_PUBLIC_SAMESITE_WS=1` en las variables de entorno (ya
configurado en `prod.yaml`).

### Permisos en el filestore

Si Odoo no puede escribir archivos adjuntos:

```bash
docker compose -f prod.yaml exec odoo ls -la /var/lib/odoo
# El directorio debe pertenecer al usuario odoo (UID 1000 por defecto en Doodba)
```

### Limpiar contenedores e imágenes huérfanas

```bash
# Ver uso de espacio Docker
docker system df

# Limpiar recursos no utilizados (imágenes, redes, volúmenes huérfanos)
# ADVERTENCIA: no ejecutar sin revisar qué se eliminará
docker system prune -f

# Limpiar imágenes antiguas específicas
docker image prune -a --filter "until=720h"
```

---

## Referencia rápida de comandos

```bash
# Iniciar todos los servicios
docker compose -f prod.yaml up -d

# Detener todos los servicios
docker compose -f prod.yaml down

# Reiniciar solo Odoo
docker compose -f prod.yaml restart odoo

# Ver estado
docker compose -f prod.yaml ps

# Ver logs de Odoo en tiempo real
docker compose -f prod.yaml logs -f odoo

# Actualizar módulo en caliente
docker compose -f prod.yaml run --rm odoo odoo --stop-after-init -d acsm -u mi_modulo

# Acceder a la shell de PostgreSQL
docker compose -f prod.yaml exec db psql -U odoo -d acsm

# Backup rápido de la base de datos
docker compose -f prod.yaml exec -T db pg_dump -U odoo -Fc acsm > backup_$(date +%Y%m%d).dump

# Traefik: reiniciar
docker compose -f docs/inverseproxy.yaml restart traefik

# Traefik: actualizar imagen
docker compose -f docs/inverseproxy.yaml pull && docker compose -f docs/inverseproxy.yaml up -d
```
