ARG ODOO_VERSION
FROM ghcr.io/tecnativa/doodba:${ODOO_VERSION}-onbuild

# pyafipws necesita escribir en su directorio cache para tokens WSAA
USER root
RUN python3 -c \
    "import pyafipws, os; cache=os.path.join(os.path.dirname(pyafipws.__file__),'cache'); os.makedirs(cache, exist_ok=True); os.chown(cache, 1000, 1000)"
USER odoo
