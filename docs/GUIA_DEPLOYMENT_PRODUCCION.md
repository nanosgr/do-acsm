# Guía Completa de Deployment a Producción - Proyectos Doodba

Esta guía describe cómo pasar un proyecto Doodba (Odoo) desde desarrollo a un servidor
de producción con HTTPS automático mediante Let's Encrypt.

## Tabla de Contenidos

1. [Pre-requisitos](#pre-requisitos)
2. [Configuración DNS](#configuración-dns)
3. [Preparación del Servidor VPS](#preparación-del-servidor-vps)
4. [Configuración de Traefik con Let's Encrypt](#configuración-de-traefik-con-lets-encrypt)
5. [Deployment de Odoo](#deployment-de-odoo)
6. [Verificación y Troubleshooting](#verificación-y-troubleshooting)
7. [Mantenimiento](#mantenimiento)

---

## Pre-requisitos

### En tu máquina local

- Proyecto Doodba funcionando correctamente en desarrollo
- Git instalado
- Acceso SSH al servidor VPS
- Docker y Docker Compose instalados localmente

### En el servidor VPS

- Ubuntu 20.04+ o Debian 11+ (recomendado)
- Docker y Docker Compose instalados
- Puertos 80 y 443 abiertos en el firewall
- Al menos 2GB de RAM (4GB recomendado para producción)
- Espacio en disco suficiente (mínimo 20GB)

---

## Configuración DNS

### 1. Crear registros DNS

En el panel de tu proveedor de VPS o DNS, crea los siguientes registros:

```
Tipo    Nombre      Valor                           TTL
A       @           IP_DE_TU_SERVIDOR               3600
A       gestion     IP_DE_TU_SERVIDOR               3600
CNAME   *           aeroclubsanmartin.com.ar        3600
```

**Importante**: El wildcard `*.aeroclubsanmartin.com.ar` es útil para subdominios
futuros, pero para Let's Encrypt necesitas registros A específicos para cada dominio.

### 2. Verificar propagación DNS

Espera a que el DNS se propague (puede tardar hasta 24 horas, pero usualmente es más
rápido):

```bash
# Desde tu máquina local
dig gestion.aeroclubsanmartin.com.ar +short
# Debe devolver la IP de tu servidor

# Verificar desde múltiples servidores DNS
nslookup gestion.aeroclubsanmartin.com.ar 8.8.8.8
```

---

## Preparación del Servidor VPS

### 1. Conectarse al servidor

```bash
ssh root@IP_DE_TU_SERVIDOR
# o
ssh usuario@IP_DE_TU_SERVIDOR
```

### 2. Actualizar el sistema

```bash
sudo apt update
sudo apt upgrade -y
```

### 3. Instalar Docker y Docker Compose

```bash
# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Agregar usuario al grupo docker (opcional)
sudo usermod -aG docker $USER

# Instalar Docker Compose
sudo apt install docker-compose-plugin -y

# Verificar instalación
docker --version
docker compose version
```

### 4. Configurar el firewall

```bash
# Si usas UFW
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable
sudo ufw status
```

### 5. Crear estructura de directorios

```bash
mkdir -p ~/doodba-projects
cd ~/doodba-projects
```

---

## Configuración de Traefik con Let's Encrypt

Traefik es el reverse proxy que maneja HTTPS y los certificados de Let's Encrypt
automáticamente.

### 1. Copiar archivo de configuración

Copia el archivo `docs/inverseproxy.yaml` a tu servidor:

```bash
# Desde tu máquina local
scp docs/inverseproxy.yaml usuario@IP_SERVIDOR:~/doodba-projects/
```

O créalo directamente en el servidor usando el contenido del archivo
`docs/inverseproxy.yaml`.

### 2. Configurar email para Let's Encrypt

Edita el archivo `inverseproxy.yaml` y cambia el email:

```bash
nano ~/doodba-projects/inverseproxy.yaml
```

Busca esta línea y cambia el email:

```yaml
- --certificatesresolvers.letsencrypt.acme.email=${LETSENCRYPT_EMAIL:-admin@aeroclubsanmartin.com.ar}
```

O crea un archivo `.env`:

```bash
echo "LETSENCRYPT_EMAIL=tu_email@dominio.com" > ~/doodba-projects/.env
```

### 3. Iniciar Traefik

```bash
cd ~/doodba-projects
docker compose -f inverseproxy.yaml up -d

# Verificar que está corriendo
docker ps | grep traefik

# Ver logs
docker compose -f inverseproxy.yaml logs -f
```

### 4. Verificar la red compartida

```bash
docker network ls | grep inverseproxy_shared
```

Debe aparecer la red `inverseproxy_shared`. Esta red es donde Odoo se conectará con
Traefik.

---

## Deployment de Odoo

### 1. Clonar o copiar el proyecto al servidor

**Opción A: Clonar desde Git (recomendado)**

```bash
cd ~/doodba-projects
git clone https://github.com/tu-usuario/do-acsm.git
cd do-acsm
```

**Opción B: Copiar desde tu máquina local**

```bash
# Desde tu máquina local
rsync -avz --exclude='.git' --exclude='odoo/auto' --exclude='*.pyc' \
  /ruta/local/do-acsm/ usuario@IP_SERVIDOR:~/doodba-projects/do-acsm/
```

### 2. Configurar variables de entorno

Crea los archivos de configuración en `.docker/`:

```bash
cd ~/doodba-projects/do-acsm

# Crear archivo de configuración de Odoo
cat > .docker/odoo.env << 'EOF'
# Odoo configuration
ADMIN_PASSWORD=TU_PASSWORD_ADMIN_SEGURO
PGPASSWORD=TU_PASSWORD_DB_SEGURO
PROXY_MODE=true
WITHOUT_DEMO=all
LIST_DB=false

# Email configuration (opcional)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=tu_email@gmail.com
SMTP_PASSWORD=tu_password_app
SMTP_SSL=false
EMAIL_FROM=tu_email@gmail.com
EOF

# Crear archivo de acceso a base de datos
cat > .docker/db-access.env << 'EOF'
PGPASSWORD=TU_PASSWORD_DB_SEGURO
EOF

# Crear archivo de creación de base de datos
cat > .docker/db-creation.env << 'EOF'
POSTGRES_PASSWORD=TU_PASSWORD_DB_SEGURO
EOF

# Proteger los archivos
chmod 600 .docker/*.env
```

**IMPORTANTE**: Cambia `TU_PASSWORD_ADMIN_SEGURO` y `TU_PASSWORD_DB_SEGURO` por
contraseñas seguras.

### 3. Cambiar al ambiente de producción

```bash
# Hacer que docker-compose.yml apunte a prod.yaml
ln -sf prod.yaml docker-compose.yml
```

### 4. Construir las imágenes

```bash
# Construir las imágenes Docker
docker compose build

# O si tienes imágenes pre-construidas
docker compose pull
```

### 5. Descargar módulos (git-aggregate)

Si es la primera vez o necesitas actualizar módulos:

```bash
# Ejecutar git-aggregate para descargar todos los módulos
docker compose run --rm odoo git-aggregate

# O si usas invoke (necesitas Python local)
# invoke git-aggregate
```

### 6. Iniciar los servicios

```bash
docker compose up -d

# Ver logs
docker compose logs -f odoo
```

### 7. Inicializar la base de datos

**Opción A: Crear base de datos desde cero**

```bash
# Acceder al contenedor
docker compose exec odoo bash

# Dentro del contenedor, inicializar la base de datos
click-odoo-initdb -n acsm -m base,web,l10n_ar

# Salir
exit
```

**Opción B: Restaurar backup de desarrollo**

```bash
# Desde tu máquina local, copiar el backup
scp backup.sql usuario@IP_SERVIDOR:~/

# En el servidor
docker compose exec -T db psql -U odoo < ~/backup.sql

# Si usas filestore, también cópialo
scp -r filestore.tar.gz usuario@IP_SERVIDOR:~/
docker compose exec odoo bash -c "cd /var/lib/odoo && tar xzf -" < ~/filestore.tar.gz
```

### 8. Verificar el estado

```bash
# Ver contenedores corriendo
docker compose ps

# Ver logs de Odoo
docker compose logs -f odoo

# Ver logs de Traefik
cd ~/doodba-projects
docker compose -f inverseproxy.yaml logs -f traefik
```

---

## Verificación y Troubleshooting

### 1. Verificar que Odoo está corriendo

```bash
# Verificar contenedores
docker compose ps

# Debe mostrar:
# - odoo (running)
# - db (running)
```

### 2. Verificar conectividad

```bash
# Probar conexión interna
curl -I http://localhost:8069

# Debe responder con HTTP 200 o 303
```

### 3. Verificar certificado SSL

Accede a tu dominio desde el navegador:

```
https://gestion.aeroclubsanmartin.com.ar
```

Debe cargar con HTTPS y sin advertencias de seguridad.

### 4. Verificar logs de Traefik

```bash
cd ~/doodba-projects
docker compose -f inverseproxy.yaml logs traefik | grep letsencrypt
```

Busca líneas como:

```
Certificates obtained for gestion.aeroclubsanmartin.com.ar
```

### Problemas Comunes

#### Error: "No se puede obtener certificado SSL"

**Causa**: DNS no está propagado o puertos 80/443 bloqueados

**Solución**:

```bash
# Verificar DNS
dig gestion.aeroclubsanmartin.com.ar +short

# Verificar puertos
sudo netstat -tlnp | grep ':80\|:443'

# Verificar firewall
sudo ufw status
```

#### Error: "Backend not found"

**Causa**: Odoo no está conectado a la red `inverseproxy_shared`

**Solución**:

```bash
# Verificar que prod.yaml tiene la configuración correcta
grep -A2 "networks:" prod.yaml

# Reiniciar Odoo
docker compose down
docker compose up -d
```

#### Error: "Bad Gateway 502"

**Causa**: Odoo no está respondiendo correctamente

**Solución**:

```bash
# Ver logs de Odoo
docker compose logs odoo

# Verificar que Odoo esté escuchando
docker compose exec odoo netstat -tlnp | grep 8069
```

#### Error: "Database does not exist"

**Causa**: Base de datos no inicializada

**Solución**:

```bash
# Inicializar base de datos
docker compose exec odoo click-odoo-initdb -n acsm -m base
```

---

## Mantenimiento

### Backups

#### Backup de base de datos

```bash
# Crear backup
docker compose exec -T db pg_dump -U odoo -d acsm > backup_$(date +%Y%m%d).sql

# Comprimir
gzip backup_$(date +%Y%m%d).sql
```

#### Backup de filestore

```bash
# Backup completo de filestore
docker compose exec odoo tar czf - /var/lib/odoo > filestore_$(date +%Y%m%d).tar.gz
```

#### Script de backup automático

```bash
cat > ~/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/home/usuario/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

cd ~/doodba-projects/do-acsm

# Backup DB
docker compose exec -T db pg_dump -U odoo -d acsm | gzip > $BACKUP_DIR/db_$DATE.sql.gz

# Backup filestore
docker compose exec odoo tar czf - /var/lib/odoo > $BACKUP_DIR/filestore_$DATE.tar.gz

# Mantener solo últimos 7 días
find $BACKUP_DIR -name "*.gz" -mtime +7 -delete

echo "Backup completado: $DATE"
EOF

chmod +x ~/backup.sh

# Agregar a crontab (backup diario a las 2 AM)
crontab -e
# Agregar:
# 0 2 * * * /home/usuario/backup.sh >> /home/usuario/backup.log 2>&1
```

### Actualizar Odoo

```bash
cd ~/doodba-projects/do-acsm

# 1. Hacer backup ANTES de actualizar
~/backup.sh

# 2. Detener servicios
docker compose down

# 3. Actualizar código
git pull

# 4. Actualizar módulos
docker compose run --rm odoo git-aggregate

# 5. Reconstruir imágenes
docker compose build

# 6. Iniciar servicios
docker compose up -d

# 7. Actualizar módulos en Odoo
docker compose exec odoo odoo -u all -d acsm --stop-after-init
```

### Monitoreo de logs

```bash
# Logs en tiempo real de Odoo
docker compose logs -f odoo

# Logs de Traefik
cd ~/doodba-projects
docker compose -f inverseproxy.yaml logs -f traefik

# Últimas 100 líneas
docker compose logs --tail=100 odoo
```

### Reiniciar servicios

```bash
# Reiniciar solo Odoo
docker compose restart odoo

# Reiniciar todo
docker compose down
docker compose up -d

# Reiniciar Traefik
cd ~/doodba-projects
docker compose -f inverseproxy.yaml restart
```

### Renovación de certificados

Let's Encrypt renueva automáticamente los certificados, pero puedes forzar la
renovación:

```bash
cd ~/doodba-projects

# Eliminar certificados existentes
docker compose -f inverseproxy.yaml down
docker volume rm traefik-certificates

# Reiniciar Traefik
docker compose -f inverseproxy.yaml up -d

# Ver logs de renovación
docker compose -f inverseproxy.yaml logs -f traefik
```

---

## Checklist de Deployment

- [ ] DNS configurado y propagado
- [ ] Servidor VPS preparado (Docker instalado, puertos abiertos)
- [ ] Traefik iniciado con `inverseproxy.yaml`
- [ ] Red `inverseproxy_shared` creada
- [ ] Proyecto clonado en el servidor
- [ ] Variables de entorno configuradas en `.docker/`
- [ ] `docker-compose.yml` apunta a `prod.yaml`
- [ ] Imágenes construidas
- [ ] Módulos descargados con git-aggregate
- [ ] Base de datos inicializada o restaurada
- [ ] Servicios iniciados (`docker compose up -d`)
- [ ] HTTPS funcionando sin advertencias
- [ ] Backup automático configurado
- [ ] Monitoreo configurado

---

## Recursos Adicionales

- [Documentación de Doodba](https://github.com/Tecnativa/doodba)
- [Documentación de Traefik](https://doc.traefik.io/traefik/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

---

## Contacto y Soporte

Para problemas específicos del proyecto:

- Revisa los logs: `docker compose logs -f`
- Verifica la configuración de red: `docker network inspect inverseproxy_shared`
- Consulta la documentación en `CLAUDE.md` y `AFIP_WEBSERVICES_ARQUITECTURA.md`
