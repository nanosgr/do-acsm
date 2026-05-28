# Troubleshooting SSL y Let's Encrypt

Guía específica para resolver problemas con certificados SSL y Let's Encrypt en
deployments de Doodba.

## Síntomas Comunes

### 1. "Tu conexión no es privada" / "Riesgo de Seguridad"

**Síntoma**: El navegador muestra advertencia de seguridad al acceder a
https://gestion.aeroclubsanmartin.com.ar

**Causas posibles**:

- Certificado SSL no se generó
- Traefik no está corriendo
- DNS no está propagado correctamente
- Dominio mal configurado en prod.yaml

### 2. "Bad Gateway 502"

**Síntoma**: Error 502 al acceder al sitio

**Causas posibles**:

- Odoo no está corriendo
- Odoo no está conectado a la red inverseproxy_shared
- Error en configuración de labels de Traefik

### 3. "404 Page Not Found"

**Síntoma**: Página 404 de Traefik

**Causas posibles**:

- Labels de Traefik mal configurados
- Dominio no coincide con los labels

## Diagnóstico Paso a Paso

### Paso 1: Verificar DNS

```bash
# Verificar que el DNS apunta a tu servidor
dig gestion.aeroclubsanmartin.com.ar +short
# Debe devolver la IP de tu servidor

# Verificar desde diferentes servidores DNS
nslookup gestion.aeroclubsanmartin.com.ar 8.8.8.8
nslookup gestion.aeroclubsanmartin.com.ar 1.1.1.1

# Verificar propagación DNS
# Visitar: https://dnschecker.org
```

**Solución si falla**: Esperar a que el DNS se propague (hasta 24h) o verificar
configuración en el panel del proveedor.

### Paso 2: Verificar Puertos

```bash
# En el servidor VPS
sudo netstat -tlnp | grep ':80\|:443'

# Debe mostrar:
# tcp6       0      0 :::80       :::*       LISTEN      docker-proxy
# tcp6       0      0 :::443      :::*       LISTEN      docker-proxy
```

**Solución si falla**:

```bash
# Verificar firewall
sudo ufw status

# Abrir puertos si están cerrados
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

### Paso 3: Verificar Traefik

```bash
# Verificar que Traefik está corriendo
cd ~/doodba-projects
docker compose -f inverseproxy.yaml ps

# Debe mostrar:
# traefik   running   0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp
```

**Solución si falla**:

```bash
# Ver logs de error
docker compose -f inverseproxy.yaml logs traefik

# Reiniciar Traefik
docker compose -f inverseproxy.yaml down
docker compose -f inverseproxy.yaml up -d
```

### Paso 4: Verificar Certificado Let's Encrypt

```bash
# Ver logs de Let's Encrypt en Traefik
cd ~/doodba-projects
docker compose -f inverseproxy.yaml logs traefik | grep -i "acme\|letsencrypt\|certificate"

# Buscar líneas como:
# "Obtaining certificate for gestion.aeroclubsanmartin.com.ar"
# "Certificate obtained for gestion.aeroclubsanmartin.com.ar"
```

**Solución si no se obtiene certificado**:

```bash
# 1. Verificar que el email está configurado
cat .env
# Debe contener: LETSENCRYPT_EMAIL=tu_email@dominio.com

# 2. Verificar el archivo acme.json
docker compose -f inverseproxy.yaml exec traefik ls -la /letsencrypt/
# Debe existir acme.json con permisos 600

# 3. Ver contenido de certificados
docker compose -f inverseproxy.yaml exec traefik cat /letsencrypt/acme.json | jq
```

### Paso 5: Verificar Red Docker

```bash
# Verificar que existe la red inverseproxy_shared
docker network ls | grep inverseproxy_shared

# Inspeccionar la red
docker network inspect inverseproxy_shared

# Debe mostrar:
# - El contenedor traefik
# - El contenedor odoo (do-acsm-odoo-1 o similar)
```

**Solución si Odoo no está en la red**:

```bash
cd ~/doodba-projects/do-acsm

# Verificar prod.yaml
grep -A10 "networks:" prod.yaml
# Debe incluir: inverseproxy_shared

# Reiniciar Odoo
docker compose down
docker compose up -d
```

### Paso 6: Verificar Labels de Traefik en Odoo

```bash
cd ~/doodba-projects/do-acsm

# Ver labels del contenedor Odoo
docker inspect $(docker compose ps -q odoo) | jq '.[0].Config.Labels'

# Verificar que incluye:
# - traefik.enable: "true"
# - traefik.http.routers.*.rule: Host(`gestion.aeroclubsanmartin.com.ar`)
# - traefik.http.routers.*.tls.certResolver: letsencrypt
```

**Solución si faltan labels**: Revisar prod.yaml:59,75,93,111 y verificar que
`tls.certResolver: letsencrypt` está presente.

## Problemas Específicos

### Error: Rate Limit de Let's Encrypt

**Síntoma**: Logs muestran "too many certificates already issued"

**Causa**: Has solicitado demasiados certificados en poco tiempo (límite: 5 por semana)

**Solución**:

```bash
# Usar servidor de staging para testing
cd ~/doodba-projects

# Editar inverseproxy.yaml y descomentar:
# - --certificatesresolvers.letsencrypt.acme.caserver=https://acme-staging-v02.api.letsencrypt.org/directory

# Borrar certificados existentes
docker compose -f inverseproxy.yaml down
docker volume rm traefik-certificates

# Reiniciar con staging
docker compose -f inverseproxy.yaml up -d

# Cuando funcione, volver a producción (comentar línea de staging)
```

### Error: Challenge Failed

**Síntoma**: "acme: error: 400 :: urn:ietf:params:acme:error:connection :: Connection
refused"

**Causa**: Let's Encrypt no puede acceder a tu servidor en el puerto 80

**Solución**:

```bash
# 1. Verificar que puerto 80 está accesible desde internet
curl -I http://gestion.aeroclubsanmartin.com.ar

# 2. Verificar firewall del VPS (no del proveedor)
sudo ufw status

# 3. Verificar firewall del proveedor de VPS
# Ir al panel de control y verificar reglas de seguridad/firewall
```

### Error: Invalid Domain

**Síntoma**: "acme: error: 400 :: urn:ietf:params:acme:error:dns :: DNS problem:
NXDOMAIN"

**Causa**: El dominio no resuelve correctamente

**Solución**:

```bash
# Verificar DNS
dig gestion.aeroclubsanmartin.com.ar +short

# Si no resuelve, verificar:
# 1. Registro A en el DNS apunta a la IP correcta
# 2. DNS ha propagado (puede tardar hasta 24h)
# 3. No hay typos en el dominio
```

### Error: Dominio con Barra Final

**Síntoma**: Certificado no se genera, o se genera para dominio incorrecto

**Causa**: Dominio configurado como `gestion.aeroclubsanmartin.com.ar/` (con barra
final)

**Solución**:

```bash
cd ~/doodba-projects/do-acsm

# Verificar prod.yaml
grep "aeroclubsanmartin" prod.yaml

# NO debe tener barra final:
# ✓ gestion.aeroclubsanmartin.com.ar
# ✗ gestion.aeroclubsanmartin.com.ar/

# Si tiene barra, editar prod.yaml y quitar todas las barras finales
# Luego reiniciar
docker compose down
docker compose up -d
```

## Comandos Útiles de Diagnóstico

### Ver certificados instalados

```bash
cd ~/doodba-projects
docker compose -f inverseproxy.yaml exec traefik cat /letsencrypt/acme.json | jq '.letsencrypt.Certificates[].domain'
```

### Forzar renovación de certificado

```bash
cd ~/doodba-projects

# Detener Traefik
docker compose -f inverseproxy.yaml down

# Borrar certificados
docker volume rm traefik-certificates

# Reiniciar Traefik
docker compose -f inverseproxy.yaml up -d

# Ver logs de obtención
docker compose -f inverseproxy.yaml logs -f traefik
```

### Verificar conectividad desde Let's Encrypt

```bash
# Probar HTTP challenge manualmente
curl -I http://gestion.aeroclubsanmartin.com.ar/.well-known/acme-challenge/test

# Debe devolver 404 de Traefik (no error de conexión)
```

### Ver todos los logs relacionados con SSL

```bash
# Logs de Traefik
cd ~/doodba-projects
docker compose -f inverseproxy.yaml logs traefik | grep -i "tls\|certificate\|acme\|letsencrypt"

# Logs de Odoo relacionados con proxy
cd ~/doodba-projects/do-acsm
docker compose logs odoo | grep -i "proxy\|redirect\|https"
```

## Checklist de Verificación SSL

Use esta lista para verificar que todo está configurado correctamente:

- [ ] DNS apunta a la IP correcta del servidor
- [ ] DNS ha propagado (verificar con dig/nslookup)
- [ ] Puertos 80 y 443 abiertos en firewall del servidor
- [ ] Puertos 80 y 443 abiertos en firewall del proveedor VPS
- [ ] Traefik corriendo (`docker ps | grep traefik`)
- [ ] Red `inverseproxy_shared` creada
- [ ] Email configurado en `.env` para Let's Encrypt
- [ ] Dominios en prod.yaml SIN barra final
- [ ] Labels de Traefik correctos en prod.yaml
- [ ] Odoo conectado a red `inverseproxy_shared`
- [ ] Odoo corriendo y respondiendo en puerto 8069
- [ ] Certificado obtenido (ver logs de Traefik)
- [ ] https://dominio.com carga sin advertencias

## Testing con Staging

Para evitar rate limits durante testing:

```bash
cd ~/doodba-projects

# 1. Editar inverseproxy.yaml
nano inverseproxy.yaml

# 2. Descomentar línea de staging:
# - --certificatesresolvers.letsencrypt.acme.caserver=https://acme-staging-v02.api.letsencrypt.org/directory

# 3. Limpiar certificados
docker compose -f inverseproxy.yaml down
docker volume rm traefik-certificates

# 4. Reiniciar
docker compose -f inverseproxy.yaml up -d

# 5. Probar (el navegador mostrará advertencia porque es staging)
# https://gestion.aeroclubsanmartin.com.ar

# 6. Cuando funcione, volver a producción
# Comentar línea de staging, limpiar certificados, reiniciar
```

## Soporte Adicional

Si después de seguir estos pasos aún tienes problemas:

1. Revisa los logs completos:

   ```bash
   cd ~/doodba-projects
   docker compose -f inverseproxy.yaml logs traefik > traefik.log
   cd ~/doodba-projects/do-acsm
   docker compose logs odoo > odoo.log
   ```

2. Verifica la configuración de red:

   ```bash
   docker network inspect inverseproxy_shared > network.json
   docker inspect $(docker compose ps -q odoo) > odoo-container.json
   ```

3. Consulta la documentación oficial:
   - [Traefik Let's Encrypt](https://doc.traefik.io/traefik/https/acme/)
   - [Let's Encrypt Rate Limits](https://letsencrypt.org/docs/rate-limits/)

---

**Nota**: Recuerda que los certificados de Let's Encrypt tienen una validez de 90 días y
se renuevan automáticamente. Traefik maneja esto automáticamente, no necesitas
intervención manual.
