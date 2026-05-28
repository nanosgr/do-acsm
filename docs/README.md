# Documentación de Deployment - do-acsm

Este directorio contiene toda la documentación necesaria para hacer deployment del
proyecto Odoo de Aero Club San Martín a producción.

## Contenido

### Guías Principales

1. **GUIA_DEPLOYMENT_PRODUCCION.md**

   - Guía completa y detallada de deployment
   - Incluye pre-requisitos, configuración DNS, Traefik, Let's Encrypt
   - Troubleshooting y mantenimiento
   - **Leer primero si es tu primer deployment**

2. **COMANDOS_RAPIDOS_DEPLOYMENT.md**
   - Referencia rápida de comandos
   - Útil para deployments posteriores
   - Comandos de mantenimiento diario
   - Troubleshooting rápido

### Archivos de Configuración

3. **inverseproxy.yaml**
   - Configuración de Traefik con Let's Encrypt
   - Reverse proxy para HTTPS automático
   - **Debe ejecutarse ANTES de iniciar Odoo**
   - Comando: `docker compose -f inverseproxy.yaml up -d`

### Ejemplos de Variables de Entorno

4. **.env.example**

   - Variables de entorno para Traefik
   - Email para Let's Encrypt
   - Copiar a la raíz donde ejecutes `inverseproxy.yaml`

5. **odoo.env.example**

   - Variables de entorno para Odoo
   - Configuración de admin, SMTP, etc.
   - **Copiar a `.docker/odoo.env`**

6. **db-access.env.example**

   - Variables de acceso a PostgreSQL
   - **Copiar a `.docker/db-access.env`**

7. **db-creation.env.example**
   - Variables de creación de PostgreSQL
   - **Copiar a `.docker/db-creation.env`**

## Flujo de Deployment Rápido

### Primera vez (Setup completo)

1. Lee `GUIA_DEPLOYMENT_PRODUCCION.md` completa
2. Configura DNS
3. Prepara el servidor VPS
4. Copia `inverseproxy.yaml` al servidor
5. Configura `.env` para Traefik
6. Inicia Traefik
7. Clona el proyecto
8. Configura variables de entorno de Odoo
9. Inicia Odoo

### Deployments posteriores

Usa `COMANDOS_RAPIDOS_DEPLOYMENT.md` como referencia rápida.

## Estructura de Variables de Entorno

```
Servidor VPS:
~/doodba-projects/
├── .env                          # Variables para Traefik
├── inverseproxy.yaml             # Configuración de Traefik
└── do-acsm/
    ├── .docker/
    │   ├── odoo.env              # Variables de Odoo
    │   ├── db-access.env         # Acceso a DB
    │   └── db-creation.env       # Creación de DB
    ├── docker-compose.yml -> prod.yaml
    └── ...
```

## Comandos Esenciales

### En el servidor VPS

```bash
# 1. Iniciar Traefik (una sola vez)
cd ~/doodba-projects
docker compose -f inverseproxy.yaml up -d

# 2. Iniciar Odoo
cd ~/doodba-projects/do-acsm
docker compose up -d

# 3. Ver logs
docker compose logs -f odoo

# 4. Reiniciar
docker compose restart odoo
```

## Checklist Pre-Deployment

- [ ] DNS configurado y propagado
- [ ] Servidor con Docker instalado
- [ ] Puertos 80, 443, 22 abiertos
- [ ] Traefik configurado y corriendo
- [ ] Variables de entorno configuradas
- [ ] Contraseñas seguras generadas
- [ ] Email de Let's Encrypt configurado

## Soporte

Para problemas específicos:

1. Revisa logs: `docker compose logs -f odoo`
2. Consulta la sección de Troubleshooting en las guías
3. Verifica la configuración de red y Traefik
4. Consulta `CLAUDE.md` para comandos específicos de Odoo

## Seguridad

**IMPORTANTE**:

- Nunca commitear archivos `.env` a Git (ya están en `.gitignore`)
- Usar contraseñas seguras (mínimo 16 caracteres)
- Guardar las contraseñas en un gestor seguro
- Hacer backups regulares
- Configurar firewall correctamente

## Enlaces Útiles

- [Doodba Framework](https://github.com/Tecnativa/doodba)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Let's Encrypt](https://letsencrypt.org/)
- [Docker Compose](https://docs.docker.com/compose/)

---

**Última actualización**: 2026-01-11 **Proyecto**: do-acsm (Aero Club San Martín) **URL
Producción**: https://gestion.aeroclubsanmartin.com.ar
