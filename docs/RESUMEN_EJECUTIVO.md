# Resumen Ejecutivo - Deployment a Producción

## Tu problema

Tienes configurado el DNS (`*.aeroclubsanmartin.com.ar`) pero cuando accedes a
`https://gestion.aeroclubsanmartin.com.ar` aparece el cartel de riesgo de seguridad.

## La causa

**Falta Traefik con Let's Encrypt** en tu servidor VPS. Tu `prod.yaml` está configurado
para usar Traefik, pero Traefik no está corriendo en el servidor.

## La solución (5 minutos)

### En el servidor VPS:

```bash
# 1. Copiar archivo de Traefik
scp docs/inverseproxy.yaml usuario@IP_SERVIDOR:~/doodba-projects/

# 2. Conectarse al servidor
ssh usuario@IP_SERVIDOR

# 3. Configurar email para Let's Encrypt
cd ~/doodba-projects
echo "LETSENCRYPT_EMAIL=tu_email@aeroclubsanmartin.com.ar" > .env

# 4. Iniciar Traefik
docker compose -f inverseproxy.yaml up -d

# 5. Verificar
docker ps | grep traefik
docker network ls | grep inverseproxy_shared

# 6. Reiniciar Odoo (si ya estaba corriendo)
cd ~/doodba-projects/do-acsm
docker compose restart odoo

# 7. Ver logs para confirmar que se obtiene el certificado
cd ~/doodba-projects
docker compose -f inverseproxy.yaml logs -f traefik
# Buscar: "Certificate obtained for gestion.aeroclubsanmartin.com.ar"
```

### Resultado esperado:

En 1-2 minutos, `https://gestion.aeroclubsanmartin.com.ar` debe cargar con HTTPS verde
(sin advertencias).

## Si no funciona

1. **Verificar DNS**:

   ```bash
   dig gestion.aeroclubsanmartin.com.ar +short
   # Debe devolver la IP de tu servidor
   ```

2. **Verificar puertos**:

   ```bash
   sudo ufw status
   # Puertos 80 y 443 deben estar abiertos
   ```

3. **Ver logs de error**:

   ```bash
   docker compose -f inverseproxy.yaml logs traefik | grep -i error
   ```

4. **Consultar troubleshooting**: Lee `docs/TROUBLESHOOTING_SSL.md`

## Documentación completa

- **Primera vez**: Lee `docs/GUIA_DEPLOYMENT_PRODUCCION.md`
- **Referencia rápida**: `docs/COMANDOS_RAPIDOS_DEPLOYMENT.md`
- **Problemas SSL**: `docs/TROUBLESHOOTING_SSL.md`
- **Índice**: `docs/README.md`

## Arquitectura

```
Internet
   ↓
Traefik (puerto 80/443)
   ↓ Red: inverseproxy_shared
   ↓
Odoo (puerto 8069)
   ↓
PostgreSQL (puerto 5432)
```

**Traefik**:

- Recibe todas las peticiones HTTPS
- Obtiene certificados SSL automáticamente de Let's Encrypt
- Redirige tráfico a Odoo

**Let's Encrypt**:

- Servicio gratuito de certificados SSL
- Renovación automática cada 90 días
- Requiere que los puertos 80 y 443 estén accesibles desde internet

## Comandos esenciales

```bash
# Estado
docker ps                                          # Ver contenedores
docker compose -f inverseproxy.yaml ps             # Estado de Traefik
cd ~/doodba-projects/do-acsm && docker compose ps  # Estado de Odoo

# Logs
docker compose -f inverseproxy.yaml logs -f traefik    # Logs de Traefik
cd ~/doodba-projects/do-acsm && docker compose logs -f odoo  # Logs de Odoo

# Reiniciar
docker compose -f inverseproxy.yaml restart        # Reiniciar Traefik
cd ~/doodba-projects/do-acsm && docker compose restart odoo  # Reiniciar Odoo
```

## Próximos pasos

Una vez que HTTPS funcione:

1. **Configurar backups automáticos**: Ver `docs/GUIA_DEPLOYMENT_PRODUCCION.md` sección
   "Backups"
2. **Documentar credenciales**: Guardar passwords en un lugar seguro
3. **Configurar monitoreo**: Logs, alertas, etc.
4. **Revisar seguridad**: Firewall, accesos SSH, etc.

---

**TL;DR**: Copia `docs/inverseproxy.yaml` al servidor, configura el email, ejecuta
`docker compose -f inverseproxy.yaml up -d`, espera 1-2 minutos, y HTTPS funcionará.
