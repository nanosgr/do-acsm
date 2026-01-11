# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in
this repository.

## Project Overview

This is **do-acsm**, an Odoo 18.0 deployment using the Doodba framework for Aero Club
San Martín (Argentina). It includes Argentine localization modules with AFIP (tax
authority) webservices integration for electronic invoicing and tax compliance.

**Production URL**: http://gestion.aeroclubsanmartin.com.ar

## Architecture

### Doodba Framework

This project uses [Doodba](https://github.com/Tecnativa/doodba), a Docker-based Odoo
deployment framework. Key characteristics:

- Docker Compose-based development and production environments
- Git aggregation system for managing Odoo addons from multiple repositories
- Task automation via Python Invoke (`tasks.py`)
- Pre-commit hooks for code quality

### Directory Structure

```
.
├── odoo/
│   ├── custom/
│   │   └── src/           # All source code (Odoo core + addons)
│   │       ├── odoo/      # Odoo core (OCB fork)
│   │       ├── private/   # Custom/private modules for this project
│   │       ├── ingadhoc-* # Argentine localization modules
│   │       └── */         # OCA and other community modules
│   └── auto/              # Auto-generated addons symlinks
├── tasks.py               # Invoke tasks (development commands)
├── common.yaml            # Common Docker Compose config
├── devel.yaml             # Development environment config
├── prod.yaml              # Production environment config
└── docker-compose.yml     # Symlink to devel.yaml
```

### Module Sources

Modules are aggregated from multiple Git repositories defined in
`odoo/custom/src/repos.yaml`:

- **odoo**: OCA's OCB (Odoo Community Backports) fork
- **ingadhoc-odoo-argentina**: Core Argentine localization
- **ingadhoc-odoo-argentina-ce**: Community Edition Argentine modules (includes AFIP
  webservices)
- **ingadhoc-account-\***: Accounting extensions
- **OCA modules**: web, server-ux, account-financial-tools, reporting-engine, etc.
- **private**: Custom modules specific to this deployment

### AFIP Webservices Integration

This deployment includes integration with AFIP (Argentine tax authority) webservices
for:

- **WSAA**: Authentication and authorization
- **WSFE/WSMTXCA/WSFEX**: Electronic invoicing
- **WSFECred**: Credit invoices for SMEs
- **WS Padrón (A5, A10, etc.)**: Taxpayer registry queries

**Key modules**:

- `l10n_ar_afipws`: Base AFIP webservices (connection, certificates, authentication)
- `l10n_ar_afipws_fe`: Electronic invoicing implementation
- `l10n_ar_afipws_urls`: Custom module for configurable AFIP webservice URLs

**Important**: AFIP webservices use X.509 certificates for authentication. See
`AFIP_WEBSERVICES_ARQUITECTURA.md` for detailed architecture documentation.

## Development Commands

All commands use Python Invoke. Run from project root.

### Environment Management

```bash
# Initial setup (first time only)
invoke develop              # Set up development environment
invoke git-aggregate        # Download Odoo core and all addons

# Start/stop Odoo
invoke start                # Start all services (detached)
invoke start --debugpy      # Start with Python debugger enabled
invoke stop                 # Stop all services
invoke restart              # Restart Odoo container
invoke logs                 # View container logs
```

### Module Development

```bash
# Install a module
invoke install -m module_name                    # Install specific module(s)
invoke install --cur-file path/to/module/file.py # Install module from current file path
invoke install --private                         # Install all private modules

# Uninstall a module
invoke uninstall -m module_name

# Update translations
invoke updatepot -m module_name  # Update .pot and .po files for a module
invoke updatepot --all          # Update all modules (slow)
```

### Testing

```bash
# Run tests for a module
invoke test -m module_name                    # Test specific module(s)
invoke test --cur-file path/to/module/file.py # Test module from current file path
invoke test --debugpy -m module_name          # Run tests with debugger attached
invoke test --private                         # Test all private modules

# Run tests in update mode instead of install mode
invoke test -m module_name --mode update
```

### Database Management

```bash
# Reset database with specific modules
invoke resetdb -m base,sale,account           # Reset with specific modules
invoke resetdb --private                      # Reset with all private modules
invoke resetdb --dependencies -m my_module   # Reset with only module dependencies

# Database snapshots
invoke snapshot                              # Create snapshot of current DB
invoke restore-snapshot                      # Restore latest snapshot
invoke restore-snapshot --snapshot-name <name> # Restore specific snapshot
```

### Docker Images

```bash
# Build Docker images
invoke img-build            # Build images
invoke img-build --no-pull  # Build without pulling base images
invoke img-pull             # Pull pre-built images
```

### Code Quality

```bash
# Lint and format code
invoke lint           # Run pre-commit on all files
invoke lint --verbose # Run with verbose output
```

### Scaffolding

```bash
# Create a new module
invoke scaffold my_new_module                    # Create in current directory
invoke scaffold my_new_module --path /some/path  # Create at specific path
```

## Development Workflow

### Working on a Custom Module

1. Create or navigate to module in `odoo/custom/src/private/`
2. Make code changes
3. Install/update the module: `invoke install -m my_module restart`
4. Run tests: `invoke test -m my_module`
5. Update translations if needed: `invoke updatepot -m my_module`
6. Lint code: `invoke lint`

### Adding New Dependencies

1. Edit `odoo/custom/src/repos.yaml` to add new repository
2. Run `invoke git-aggregate` to download
3. Edit `odoo/custom/src/addons.yaml` to include specific modules
4. Rebuild: `invoke stop && invoke start`

### Working with AFIP Webservices

- **Certificate management**: Certificates are stored in the database (model
  `afipws.certificate`)
- **URL configuration**: AFIP webservice URLs can be configured via Settings > AFIP >
  Configuración de URLs (module `l10n_ar_afipws_urls`)
- **Testing**: Use homologation environment certificates and URLs for testing
- **Reference**: See `AFIP_WEBSERVICES_ARQUITECTURA.md` for complete architecture
  details

## Python Environment

- **Odoo Version**: 18.0
- **Python Version**: 3.x (Python 3 for Odoo 11+)
- **Container**: All Python code runs inside Docker containers
- **Dependencies**: Managed via pip, defined in Odoo addon `__manifest__.py` files

## Docker Compose Environments

- **devel.yaml**: Development environment with debugging tools, auto-reload, local SMTP
  (MailHog), pgweb, etc.
- **prod.yaml**: Production configuration
- **test.yaml**: Testing environment
- **common.yaml**: Shared configuration (DB version, Odoo version, base services)

## Configuration

### Environment Variables

- `DOODBA_ENVIRONMENT`: Current environment (devel/prod)
- `INITIAL_LANG`: Initial language (es_AR for Argentina)
- `DOODBA_DEBUGPY_ENABLE`: Enable Python debugger (0/1)
- `PGDATABASE`: Database name (devel in dev, acsm in common)
- `UID`/`GID`: User/group IDs for file permissions
- `DOODBA_WITHOUT_DEMO`: Set to "all" to disable demo data

### Ports (Development)

- Odoo: http://localhost:18069
- pgweb (DB viewer): http://localhost:18081
- MailHog (SMTP): http://localhost:18025
- Debugger: Port varies by Odoo version (18899 for v18)

## Important Files

- `tasks.py`: All invoke task definitions
- `repos.yaml`: Git repositories to aggregate
- `addons.yaml`: Specific addons to include
- `common.yaml`, `devel.yaml`, `prod.yaml`: Docker Compose configurations
- `.pre-commit-config.yaml`: Pre-commit hooks configuration
- `AFIP_WEBSERVICES_ARQUITECTURA.md`: Detailed AFIP webservices architecture
- `INSTALACION_MODULO_URLS.md`: Documentation for l10n_ar_afipws_urls module

## VSCode Integration

Run `invoke write-code-workspace-file` to generate/update the `.code-workspace` file
with:

- Proper folder structure for multi-root workspace
- Python path mappings for debugging
- Launch configurations for Odoo debugging
- Task definitions for common operations

## Database Defaults

- **Development**: Database name is "devel"
- **Production**: Database name is "acsm"
- **User**: odoo
- **PostgreSQL Version**: 16

## Special Considerations

### Argentine Localization

- Primary language is Spanish (Argentina): `es_AR`
- Chart of accounts and fiscal positions are Argentina-specific
- AFIP integration requires valid certificates (different for homologation vs
  production)
- Tax ID validation follows Argentine CUIT/CUIL format

### Module Installation Order

When working with Argentine localization:

1. Install base accounting (`account`)
2. Install `l10n_ar` (base Argentine localization)
3. Install `l10n_ar_afipws` (AFIP webservices base)
4. Install `l10n_ar_afipws_fe` (electronic invoicing)
5. Install any custom modules that depend on the above

### Git Aggregation

- Use `invoke git-aggregate` after modifying `repos.yaml`
- Shallow clones are used by default for speed (depth=1)
- Some repos may need deeper history for PR merging
- Pre-commit hooks are automatically installed/uninstalled per repo

## Common Patterns

### Running Odoo CLI Commands

Use docker-compose run pattern:

```bash
docker compose run --rm odoo <odoo-command>
```

Examples in tasks.py:

- `docker compose run --rm odoo addons init -w module_name`
- `docker compose run --rm odoo click-odoo-initdb -n dbname -m modules`
- `docker compose run --rm odoo psql -tc 'SELECT ...'`

### File Permissions

- Containers run with UID/GID from environment variables
- All invoke tasks use `UID_ENV` for proper file ownership
- Auto-generated files (in `odoo/auto/`) should be writable by containers

### Testing AFIP Connectivity

Example scripts in project root (if present):

- Check WSAA authentication
- Query Padrón webservice
- Validate certificate configuration
