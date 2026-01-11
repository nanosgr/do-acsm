[![Doodba deployment](https://img.shields.io/badge/deployment-doodba-informational)](https://github.com/Tecnativa/doodba)
[![Last template update](https://img.shields.io/badge/last%20template%20update-v9.0.5-informational)](https://github.com/Tecnativa/doodba-copier-template/tree/v9.0.5)
[![Odoo](https://img.shields.io/badge/odoo-v18.0-a3478a)](https://github.com/odoo/odoo/tree/18.0)
[![Deployment data](https://img.shields.io/badge/%F0%9F%8C%90%20prod-gestion.aeroclubsanmartin.com.ar-green)](http://gestion.aeroclubsanmartin.com.ar)
[![BSL-1.0 license](https://img.shields.io/badge/license-BSL--1.0-success})](LICENSE)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://pre-commit.com/)

# acsm - a Doodba deployment

Odoo 18.0 deployment for Aero Club San Martín (Argentina) with Argentine localization
and AFIP webservices integration.

**Production URL**: https://gestion.aeroclubsanmartin.com.ar

## Quick Start

### Development

```bash
invoke develop              # First time setup
invoke start                # Start Odoo
invoke logs                 # View logs
```

### Production Deployment

For deploying to production with HTTPS/Let's Encrypt, see:

- **Quick solution**: [docs/RESUMEN_EJECUTIVO.md](docs/RESUMEN_EJECUTIVO.md)
- **Complete guide**:
  [docs/GUIA_DEPLOYMENT_PRODUCCION.md](docs/GUIA_DEPLOYMENT_PRODUCCION.md)
- **Quick reference**:
  [docs/COMANDOS_RAPIDOS_DEPLOYMENT.md](docs/COMANDOS_RAPIDOS_DEPLOYMENT.md)
- **SSL troubleshooting**: [docs/TROUBLESHOOTING_SSL.md](docs/TROUBLESHOOTING_SSL.md)

## Documentation

- [CLAUDE.md](CLAUDE.md) - Development guide for Claude Code
- [docs/README.md](docs/README.md) - Deployment documentation index
- [AFIP_WEBSERVICES_ARQUITECTURA.md](AFIP_WEBSERVICES_ARQUITECTURA.md) - AFIP
  webservices architecture

## Doodba Resources

This project is based on Doodba. Check upstream docs:

- [General Doodba docs](https://github.com/Tecnativa/doodba)
- [Doodba copier template docs](https://github.com/Tecnativa/doodba-copier-template)
- [Doodba QA docs](https://github.com/Tecnativa/doodba-qa)

## Credits

This project is maintained by: VikingoSoftware
