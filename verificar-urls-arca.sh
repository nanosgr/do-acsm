#!/bin/bash
# Script para verificar si el módulo l10n_ar_afipws_urls está instalado
# y si las URLs de ARCA están configuradas correctamente

set -e

echo "=========================================="
echo "VERIFICACIÓN URLs ARCA en Odoo"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar si docker-compose está corriendo
if ! docker-compose ps | grep -q "Up"; then
    echo -e "${RED}✗ ERROR: Odoo no está corriendo${NC}"
    echo "  Ejecuta: docker-compose up -d"
    exit 1
fi

echo -e "${GREEN}✓ Odoo está corriendo${NC}"
echo ""

# Obtener nombre de la base de datos desde el archivo .env o pedir al usuario
if [ -f ".env" ]; then
    DB_NAME=$(grep "^PGDATABASE=" .env | cut -d'=' -f2)
fi

if [ -z "$DB_NAME" ]; then
    echo "Ingresa el nombre de tu base de datos:"
    read -r DB_NAME
fi

echo "Base de datos: $DB_NAME"
echo ""

# Verificar si el módulo está instalado
echo "Verificando si el módulo l10n_ar_afipws_urls está instalado..."
echo ""

MODULE_STATE=$(docker-compose run --rm -T odoo odoo shell -d "$DB_NAME" --stop-after-init <<'PYTHON' 2>/dev/null
import sys
try:
    module = env['ir.module.module'].search([('name', '=', 'l10n_ar_afipws_urls')], limit=1)
    if module:
        print(f"STATE:{module.state}")
        print(f"VERSION:{module.latest_version or 'N/A'}")
    else:
        print("STATE:not_found")
except Exception as e:
    print(f"ERROR:{str(e)}")
    sys.exit(1)
PYTHON
)

STATE=$(echo "$MODULE_STATE" | grep "^STATE:" | cut -d':' -f2)
VERSION=$(echo "$MODULE_STATE" | grep "^VERSION:" | cut -d':' -f2)

case "$STATE" in
    "installed")
        echo -e "${GREEN}✓ Módulo INSTALADO${NC}"
        echo "  Versión: $VERSION"
        ;;
    "uninstalled")
        echo -e "${YELLOW}⚠ Módulo NO instalado (pero disponible)${NC}"
        echo "  Debes instalarlo desde: Apps → Buscar 'l10n_ar_afipws_urls' → Instalar"
        echo ""
        echo "O ejecutar:"
        echo "  docker-compose run --rm odoo odoo -i l10n_ar_afipws_urls -d $DB_NAME --stop-after-init"
        ;;
    "to upgrade")
        echo -e "${YELLOW}⚠ Módulo pendiente de ACTUALIZACIÓN${NC}"
        echo "  Actualízalo desde: Apps → Buscar 'l10n_ar_afipws_urls' → Actualizar"
        echo ""
        echo "O ejecutar:"
        echo "  docker-compose run --rm odoo odoo -u l10n_ar_afipws_urls -d $DB_NAME --stop-after-init"
        ;;
    "not_found")
        echo -e "${RED}✗ Módulo NO ENCONTRADO${NC}"
        echo "  El módulo no está en el path de Odoo"
        echo "  Verifica que existe en: odoo/custom/src/private/l10n_ar_afipws_urls"
        exit 1
        ;;
    *)
        echo -e "${YELLOW}Estado desconocido: $STATE${NC}"
        ;;
esac

echo ""

# Si está instalado, verificar las URLs
if [ "$STATE" = "installed" ]; then
    echo "Verificando URLs configuradas..."
    echo ""

    URLS_CHECK=$(docker-compose run --rm -T odoo odoo shell -d "$DB_NAME" --stop-after-init <<'PYTHON' 2>/dev/null
import sys
try:
    configs = env['afipws.url.config'].search([])

    urls_afip = []
    urls_arca = []

    for config in configs:
        if 'afip.gov.ar' in config.url or 'afip.gob.ar' in config.url:
            urls_afip.append(f"{config.service_name}|{config.environment_type}|{config.url}")
        elif 'arca.gov.ar' in config.url or 'arca.gob.ar' in config.url:
            urls_arca.append(f"{config.service_name}|{config.environment_type}|{config.url}")

    print(f"AFIP_COUNT:{len(urls_afip)}")
    print(f"ARCA_COUNT:{len(urls_arca)}")

    if urls_afip:
        print("AFIP_URLS_START")
        for url in urls_afip:
            print(url)
        print("AFIP_URLS_END")

    if urls_arca:
        print("ARCA_URLS_START")
        for url in urls_arca[:3]:  # Solo las primeras 3 como ejemplo
            print(url)
        print("ARCA_URLS_END")

except Exception as e:
    print(f"ERROR:{str(e)}")
    sys.exit(1)
PYTHON
)

    AFIP_COUNT=$(echo "$URLS_CHECK" | grep "^AFIP_COUNT:" | cut -d':' -f2)
    ARCA_COUNT=$(echo "$URLS_CHECK" | grep "^ARCA_COUNT:" | cut -d':' -f2)

    if [ "$AFIP_COUNT" = "0" ] && [ "$ARCA_COUNT" -gt "0" ]; then
        echo -e "${GREEN}✓ URLs correctamente actualizadas a ARCA${NC}"
        echo "  Total de URLs con ARCA: $ARCA_COUNT"
        echo ""
        echo "  Ejemplos:"
        echo "$URLS_CHECK" | sed -n '/ARCA_URLS_START/,/ARCA_URLS_END/p' | grep -v "ARCA_URLS" | while IFS='|' read -r service env url; do
            echo "    - $service ($env): $url"
        done
    elif [ "$AFIP_COUNT" -gt "0" ]; then
        echo -e "${RED}✗ Aún hay URLs con dominio AFIP antiguo${NC}"
        echo "  URLs con AFIP: $AFIP_COUNT"
        echo "  URLs con ARCA: $ARCA_COUNT"
        echo ""
        echo "  URLs que necesitan actualización:"
        echo "$URLS_CHECK" | sed -n '/AFIP_URLS_START/,/AFIP_URLS_END/p' | grep -v "AFIP_URLS" | while IFS='|' read -r service env url; do
            echo "    - $service ($env): $url"
        done
        echo ""
        echo "  Debes actualizar el módulo o modificar las URLs manualmente"
    else
        echo -e "${YELLOW}⚠ No se encontraron URLs configuradas${NC}"
        echo "  El módulo está instalado pero no hay datos en afipws.url.config"
    fi
fi

echo ""
echo "=========================================="
echo "FIN DE LA VERIFICACIÓN"
echo "=========================================="
