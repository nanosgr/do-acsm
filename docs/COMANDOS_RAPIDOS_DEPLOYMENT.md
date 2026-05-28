# Comandos Rápidos para Deployment a Producción

Esta es una guía rápida con los comandos esenciales para hacer deployment. Para detalles
completos, consulta `GUIA_DEPLOYMENT_PRODUCCION.md`.

## 1. Preparación del Servidor (Una sola vez)

```bash
# Conectarse al servidor
ssh root@IP_SERVIDOR

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo apt install docker-compose-plugin -y

# Configurar firewall
sudo ufw allow 22/tcp && sudo ufw allow 80/tcp && sudo ufw allow 443/tcp
sudo ufw enable

# Crear directorios
mkdir -p ~/doodba-projects
cd ~/doodba-projects
```

## 2. Configurar Traefik (Una sola vez)

```bash
# Copiar archivo desde local
# (Ejecutar en tu máquina local)
scp docs/inverseproxy.yaml usuario@IP_SERVIDOR:~/doodba-projects/

# Configurar email (en el servidor)
echo "LETSENCRYPT_EMAIL=tu_email@dominio.com" > ~/doodba-projects/.env

# Iniciar Traefik
cd ~/doodba-projects
docker compose -f inverseproxy.yaml up -d

# Verificar
docker ps | grep traefik
docker network ls | grep inverseproxy_shared
```

## 3. Deployment de Odoo

```bash
# Clonar proyecto
cd ~/doodba-projects
git clone TU_REPO_URL do-acsm
cd do-acsm

# Configurar variables de entorno
cat > .docker/odoo.env << 'EOF'
ADMIN_PASSWORD=CAMBIAR_ESTO
PGPASSWORD=CAMBIAR_ESTO
PROXY_MODE=true
WITHOUT_DEMO=all
LIST_DB=false
EOF

cat > .docker/db-access.env << 'EOF'
PGPASSWORD=CAMBIAR_ESTO
EOF

cat > .docker/db-creation.env << 'EOF'
POSTGRES_PASSWORD=CAMBIAR_ESTO
EOF

chmod 600 .docker/*.env

# Cambiar a producción
ln -sf prod.yaml docker-compose.yml

# Construir y iniciar
docker compose build
docker compose run --rm odoo git-aggregate
docker compose up -d

# Inicializar base de datos
docker compose exec odoo click-odoo-initdb -n acsm -m base,web,l10n_ar

# Ver logs
docker compose logs -f odoo
```

## 4. Verificación

```bash
# Verificar servicios
docker compose ps
docker compose logs odoo

# Verificar Traefik
cd ~/doodba-projects
docker compose -f inverseproxy.yaml logs traefik | grep letsencrypt

# Probar en navegador
# https://gestion.aeroclubsanmartin.com.ar
```

## 5. Comandos de Mantenimiento Diario

### Ver logs

```bash
cd ~/doodba-projects/do-acsm
docker compose logs -f odoo                    # Logs en tiempo real
docker compose logs --tail=100 odoo            # Últimas 100 líneas
```

### Reiniciar servicios

```bash
docker compose restart odoo                    # Solo Odoo
docker compose down && docker compose up -d    # Todo
```

### Backup manual

```bash
# Base de datos
docker compose exec -T db pg_dump -U odoo -d acsm > backup_$(date +%Y%m%d).sql

# Filestore
docker compose exec odoo tar czf - /var/lib/odoo > filestore_$(date +%Y%m%d).tar.gz
```

### Actualizar Odoo

```bash
# Backup primero!
docker compose down
git pull
docker compose run --rm odoo git-aggregate
docker compose build
docker compose up -d
docker compose exec odoo odoo -u all -d acsm --stop-after-init
```

### Instalar módulo nuevo

```bash
docker compose exec odoo odoo -i nombre_modulo -d acsm --stop-after-init
docker compose restart odoo
```

### Acceder al shell de Odoo

```bash
docker compose exec odoo bash
```

### Acceder a PostgreSQL

```bash
docker compose exec db psql -U odoo -d acsm
```

## 6. Troubleshooting Rápido

### Error 502 Bad Gateway

```bash
# Ver si Odoo está corriendo
docker compose ps
docker compose logs odoo

# Reiniciar
docker compose restart odoo
```

### Sin certificado SSL

```bash
# Ver logs de Traefik
cd ~/doodba-projects
docker compose -f inverseproxy.yaml logs traefik

# Verificar DNS
dig gestion.aeroclubsanmartin.com.ar +short

# Verificar red
docker network inspect inverseproxy_shared
```

### Base de datos no existe

```bash
docker compose exec odoo click-odoo-initdb -n acsm -m base
```

### Error de permisos en filestore

```bash
docker compose exec odoo chown -R odoo:odoo /var/lib/odoo
docker compose restart odoo
```

## 7. Monitoreo

### Ver uso de recursos

```bash
docker stats

# Ver espacio en disco
df -h
docker system df
```

### Ver certificados SSL

```bash
cd ~/doodba-projects
docker compose -f inverseproxy.yaml exec traefik cat /letsencrypt/acme.json | jq
```

## 8. Script de Backup Automático

```bash
cat > ~/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/home/$(whoami)/backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR
cd ~/doodba-projects/do-acsm
docker compose exec -T db pg_dump -U odoo -d acsm | gzip > $BACKUP_DIR/db_$DATE.sql.gz
docker compose exec odoo tar czf - /var/lib/odoo > $BACKUP_DIR/filestore_$DATE.tar.gz
find $BACKUP_DIR -name "*.gz" -mtime +7 -delete
echo "Backup completado: $DATE"
EOF

chmod +x ~/backup.sh

# Probar
~/backup.sh

# Agregar a crontab (diario a las 2 AM)
(crontab -l 2>/dev/null; echo "0 2 * * * /home/$(whoami)/backup.sh >> /home/$(whoami)/backup.log 2>&1") | crontab -
```

## 9. Comandos de Emergencia

### Detener todo

```bash
cd ~/doodba-projects/do-acsm
docker compose down
cd ~/doodba-projects
docker compose -f inverseproxy.yaml down
```

### Limpiar todo (CUIDADO: Borra datos)

```bash
docker compose down -v  # Borra volúmenes
docker system prune -a  # Limpia imágenes no usadas
```

### Restaurar backup

```bash
# Base de datos
docker compose exec -T db psql -U odoo < backup.sql

# Filestore
docker compose exec odoo bash -c "cd /var/lib/odoo && tar xzf -" < filestore.tar.gz
docker compose exec odoo chown -R odoo:odoo /var/lib/odoo
docker compose restart odoo
```

---

## Checklist Pre-Deployment

- [ ] DNS configurado (A record para el dominio)
- [ ] Puertos 80, 443, 22 abiertos en firewall
- [ ] Docker instalado en servidor
- [ ] Email configurado para Let's Encrypt
- [ ] Contraseñas seguras en archivos .env
- [ ] Traefik corriendo
- [ ] Red inverseproxy_shared creada

## Checklist Post-Deployment

- [ ] https://dominio.com funciona sin advertencias SSL
- [ ] Odoo responde correctamente
- [ ] Base de datos inicializada
- [ ] Logs sin errores críticos
- [ ] Backup automático configurado
- [ ] Documentación actualizada con credenciales

---

**Nota**: Este documento es un resumen. Para instrucciones detalladas, troubleshooting
completo y explicaciones, consulta `GUIA_DEPLOYMENT_PRODUCCION.md`.
