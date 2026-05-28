#!/bin/bash
#
# Script de Deployment Automatizado para Doodba/Odoo
# Uso: ./deploy.sh [opcion]
#
# Opciones:
#   setup-traefik    - Configura e inicia Traefik
#   setup-odoo       - Configura e inicia Odoo
#   start            - Inicia los servicios
#   stop             - Detiene los servicios
#   restart          - Reinicia los servicios
#   logs             - Muestra logs de Odoo
#   backup           - Crea backup de DB y filestore
#   update           - Actualiza Odoo
#   status           - Muestra estado de los servicios
#

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funciones de utilidad
error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    exit 1
}

success() {
    echo -e "${GREEN}✓ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

info() {
    echo -e "ℹ $1"
}

# Verificar que estamos en el directorio correcto
check_directory() {
    if [[ ! -f "prod.yaml" ]]; then
        error "Este script debe ejecutarse desde el directorio raíz del proyecto (donde está prod.yaml)"
    fi
}

# Setup Traefik
setup_traefik() {
    info "Configurando Traefik con Let's Encrypt..."

    cd ~/doodba-projects

    if [[ ! -f "inverseproxy.yaml" ]]; then
        error "Archivo inverseproxy.yaml no encontrado. Cópialo desde docs/inverseproxy.yaml"
    fi

    if [[ ! -f ".env" ]]; then
        warning ".env no encontrado, creando desde ejemplo..."
        read -p "Ingresa tu email para Let's Encrypt: " email
        echo "LETSENCRYPT_EMAIL=$email" > .env
        success ".env creado"
    fi

    info "Iniciando Traefik..."
    docker compose -f inverseproxy.yaml up -d

    success "Traefik iniciado correctamente"
    info "Verificando red..."
    docker network ls | grep inverseproxy_shared || error "Red inverseproxy_shared no creada"
    success "Red inverseproxy_shared OK"

    info "Ver logs: docker compose -f inverseproxy.yaml logs -f traefik"
}

# Setup Odoo
setup_odoo() {
    check_directory

    info "Configurando Odoo para producción..."

    # Verificar archivos de configuración
    if [[ ! -d ".docker" ]]; then
        mkdir -p .docker
        success "Directorio .docker creado"
    fi

    if [[ ! -f ".docker/odoo.env" ]]; then
        warning "Archivo .docker/odoo.env no encontrado"
        info "Creando desde ejemplo..."

        if [[ -f "docs/odoo.env.example" ]]; then
            cp docs/odoo.env.example .docker/odoo.env

            read -sp "Ingresa password de admin de Odoo: " admin_pass
            echo
            read -sp "Ingresa password de PostgreSQL: " db_pass
            echo

            sed -i "s/CAMBIAR_ESTO_POR_PASSWORD_SEGURO/$admin_pass/" .docker/odoo.env
            sed -i "s/CAMBIAR_ESTO_POR_PASSWORD_DB_SEGURO/$db_pass/" .docker/odoo.env

            echo "PGPASSWORD=$db_pass" > .docker/db-access.env
            echo "POSTGRES_PASSWORD=$db_pass" > .docker/db-creation.env

            chmod 600 .docker/*.env

            success "Archivos .env creados"
        else
            error "Archivo docs/odoo.env.example no encontrado"
        fi
    fi

    # Cambiar a producción
    if [[ -L "docker-compose.yml" ]]; then
        rm docker-compose.yml
    fi
    ln -sf prod.yaml docker-compose.yml
    success "docker-compose.yml apunta a prod.yaml"

    # Build
    info "Construyendo imágenes..."
    docker compose build
    success "Imágenes construidas"

    # Git aggregate
    info "Descargando módulos con git-aggregate..."
    docker compose run --rm odoo git-aggregate
    success "Módulos descargados"

    # Iniciar servicios
    info "Iniciando servicios..."
    docker compose up -d
    success "Servicios iniciados"

    # Esperar un momento
    sleep 5

    # Verificar estado
    docker compose ps

    info "Odoo configurado. Inicializa la base de datos con:"
    echo "  docker compose exec odoo click-odoo-initdb -n acsm -m base,web,l10n_ar"
}

# Start services
start_services() {
    check_directory
    docker compose up -d
    success "Servicios iniciados"
    docker compose ps
}

# Stop services
stop_services() {
    check_directory
    docker compose down
    success "Servicios detenidos"
}

# Restart services
restart_services() {
    check_directory
    docker compose restart odoo
    success "Odoo reiniciado"
}

# Show logs
show_logs() {
    check_directory
    docker compose logs -f odoo
}

# Backup
create_backup() {
    check_directory

    BACKUP_DIR=~/backups
    DATE=$(date +%Y%m%d_%H%M%S)

    mkdir -p $BACKUP_DIR

    info "Creando backup de base de datos..."
    docker compose exec -T db pg_dump -U odoo -d acsm | gzip > $BACKUP_DIR/db_$DATE.sql.gz
    success "Backup DB: $BACKUP_DIR/db_$DATE.sql.gz"

    info "Creando backup de filestore..."
    docker compose exec odoo tar czf - /var/lib/odoo > $BACKUP_DIR/filestore_$DATE.tar.gz
    success "Backup filestore: $BACKUP_DIR/filestore_$DATE.tar.gz"

    success "Backup completado: $DATE"
}

# Update
update_odoo() {
    check_directory

    info "Actualizando Odoo..."

    # Backup primero
    warning "Creando backup antes de actualizar..."
    create_backup

    # Pull código
    info "Actualizando código..."
    git pull

    # Stop
    docker compose down

    # Update modules
    info "Actualizando módulos..."
    docker compose run --rm odoo git-aggregate

    # Rebuild
    info "Reconstruyendo imágenes..."
    docker compose build

    # Start
    docker compose up -d

    # Update modules in Odoo
    info "Actualizando módulos en Odoo..."
    docker compose exec odoo odoo -u all -d acsm --stop-after-init

    # Restart
    docker compose restart odoo

    success "Odoo actualizado"
}

# Status
show_status() {
    info "Estado de Traefik:"
    cd ~/doodba-projects
    docker compose -f inverseproxy.yaml ps

    info "Estado de Odoo:"
    cd ~/doodba-projects/do-acsm
    docker compose ps

    info "Redes:"
    docker network ls | grep inverseproxy_shared
}

# Main
case "${1:-}" in
    setup-traefik)
        setup_traefik
        ;;
    setup-odoo)
        setup_odoo
        ;;
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    logs)
        show_logs
        ;;
    backup)
        create_backup
        ;;
    update)
        update_odoo
        ;;
    status)
        show_status
        ;;
    *)
        echo "Script de Deployment Automatizado para Doodba/Odoo"
        echo ""
        echo "Uso: $0 [opcion]"
        echo ""
        echo "Opciones:"
        echo "  setup-traefik    - Configura e inicia Traefik"
        echo "  setup-odoo       - Configura e inicia Odoo"
        echo "  start            - Inicia los servicios"
        echo "  stop             - Detiene los servicios"
        echo "  restart          - Reinicia los servicios"
        echo "  logs             - Muestra logs de Odoo"
        echo "  backup           - Crea backup de DB y filestore"
        echo "  update           - Actualiza Odoo"
        echo "  status           - Muestra estado de los servicios"
        exit 1
        ;;
esac
