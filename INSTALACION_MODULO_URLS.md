# Instalación del Módulo l10n_ar_afipws_urls

## Resumen

Se ha creado el módulo **l10n_ar_afipws_urls** que extiende `l10n_ar_afipws` para
permitir configurar las URLs de los webservices de AFIP desde la interfaz de Odoo.

## Confirmación de tu Problema

✅ **CONFIRMADO**: Las URLs de AFIP están hardcodeadas en el módulo `l10n_ar_afipws`

**Ubicación**:
`odoo/custom/src/ingadhoc-odoo-argentina-ce/l10n_ar_afipws/models/afipws_connection.py`

- Línea 78: `https://wsaahomo.afip.gov.ar/ws/services/LoginCms` (WSAA Homologación)
- Línea 76: `https://wsaa.afip.gov.ar/ws/services/LoginCms` (WSAA Producción)
- Líneas 88-103: URLs de otros webservices (WS Padrón, WSFECred, etc.)

## Solución Implementada

### Módulo Creado

**Ubicación**: `odoo/custom/src/private/l10n_ar_afipws_urls/`

**Estructura**:

```
l10n_ar_afipws_urls/
├── __init__.py
├── __manifest__.py
├── README.md
├── models/
│   ├── __init__.py
│   ├── afipws_url_config.py      # Modelo para almacenar URLs
│   └── afipws_connection.py      # Extiende conexión para usar URLs config
├── views/
│   ├── afipws_url_config_views.xml  # Vistas de configuración
│   └── afipws_menuitem.xml          # Menú
├── data/
│   └── afipws_url_config_data.xml   # URLs precargadas de AFIP
└── security/
    └── ir.model.access.csv          # Permisos de acceso
```

### Características

✅ URLs configurables desde la interfaz (Settings > AFIP > Configuración de URLs)

✅ Soporte para todos los webservices:

- WSAA (Autenticación)
- WSFE, WSMTXCA, WSFEX, WSBFE (Facturación)
- WSFECred (Factura Crédito MiPyME)
- WS Padrón (A4, A5, A10, A100)

✅ Entornos separados (Producción / Homologación)

✅ Fallback automático a URLs hardcodeadas si no hay configuración

✅ URLs de AFIP precargadas al instalar

✅ Activar/Desactivar configuraciones sin eliminarlas

## Pasos de Instalación

### 1. El módulo ya está en el lugar correcto

```bash
# Ya creado en:
odoo/custom/src/private/l10n_ar_afipws_urls/
```

### 2. Actualizar lista de módulos en Odoo

**Opción A: Desde la línea de comandos**

```bash
# Reiniciar Odoo con actualización de módulos
docker-compose restart odoo
```

**Opción B: Desde la interfaz**

1. Activar modo desarrollador (Settings > Activate Developer Mode)
2. Ir a Apps
3. Click en "Update Apps List"
4. Confirmar

### 3. Instalar el módulo

1. Ir a **Apps**
2. Quitar el filtro "Apps" para ver todos los módulos
3. Buscar: **"AFIP Webservices - URLs Configurables"** o **"l10n_ar_afipws_urls"**
4. Click en **Instalar**

### 4. Verificar instalación

1. Ir a **Settings**
2. Navegar a **AFIP > Configuración de URLs**
3. Deberías ver las URLs precargadas de AFIP

## Uso del Módulo

### Ver URLs configuradas

1. **Settings > AFIP > Configuración de URLs**
2. Verás una lista con todas las URLs de AFIP (Producción y Homologación)

### Modificar una URL existente

Ejemplo: Si AFIP cambia la URL de WSAA Homologación

1. Ir a **Settings > AFIP > Configuración de URLs**
2. Buscar el registro: **"WSAA - Autenticación y Autorización - Homologación"**
3. Abrir el registro
4. Editar el campo **URL**
5. Cambiar de: `https://wsaahomo.afip.gov.ar/ws/services/LoginCms`
6. A la nueva URL que AFIP proporcione
7. **Guardar**

### Crear una nueva configuración

Si AFIP lanza un nuevo webservice:

1. Click en **Crear**
2. Seleccionar **Servicio** (si no está en la lista, se puede agregar editando el
   código)
3. Seleccionar **Entorno** (Producción o Homologación)
4. Ingresar la **URL** completa
5. Agregar **Descripción** (opcional)
6. **Guardar**

### Activar/Desactivar una URL

Use el toggle "Activo/Inactivo" para temporalmente deshabilitar una configuración sin
eliminarla.

## Solución al Error Actual

### Error que estabas experimentando:

```
Could not connect. This is the what we received:
httplib2.error.ServerNotFoundError: Unable to find the server at wsaahomo.afip.gov.ar
```

### Posibles causas:

1. **Problema de DNS**: El servidor no puede resolver `wsaahomo.afip.gov.ar`
2. **Problema de red**: No hay conectividad con AFIP
3. **URL incorrecta**: AFIP cambió la URL y necesita actualizarse

### Solución con el nuevo módulo:

1. **Verificar conectividad**:

   ```bash
   # Desde el contenedor de Odoo
   docker-compose exec odoo ping wsaahomo.afip.gov.ar
   docker-compose exec odoo curl -I https://wsaahomo.afip.gov.ar/ws/services/LoginCms
   ```

2. **Si la URL es incorrecta**: Actualizar desde la interfaz sin modificar código

3. **Si hay problema de DNS**: Podría ser necesario configurar DNS en el contenedor

4. **Si AFIP cambió la URL**:
   - Buscar la nueva URL en la documentación de AFIP
   - Actualizar en **Settings > AFIP > Configuración de URLs**
   - No necesitas modificar código ni reinstalar módulos

## URLs Actuales de AFIP (Precargadas)

### WSAA - Autenticación

| Entorno      | URL                                               |
| ------------ | ------------------------------------------------- |
| Producción   | https://wsaa.afip.gov.ar/ws/services/LoginCms     |
| Homologación | https://wsaahomo.afip.gov.ar/ws/services/LoginCms |

### WSFE - Factura Electrónica

| Entorno      | URL                                                     |
| ------------ | ------------------------------------------------------- |
| Producción   | https://servicios1.afip.gov.ar/wsfev1/service.asmx?WSDL |
| Homologación | https://wswhomo.afip.gov.ar/wsfev1/service.asmx?WSDL    |

### WSFECred - Factura de Crédito MiPyME

| Entorno      | URL                                                           |
| ------------ | ------------------------------------------------------------- |
| Producción   | https://serviciosjava.afip.gob.ar/wsfecred/FECredService?wsdl |
| Homologación | https://fwshomo.afip.gov.ar/wsfecred/FECredService?wsdl       |

### WS Padrón A5

| Entorno      | URL                                                                     |
| ------------ | ----------------------------------------------------------------------- |
| Producción   | https://aws.afip.gov.ar/sr-padron/webservices/personaServiceA5?wsdl     |
| Homologación | https://awshomo.afip.gov.ar/sr-padron/webservices/personaServiceA5?wsdl |

_Ver todas las URLs en `data/afipws_url_config_data.xml`_

## Ventajas del Módulo

### Antes (sin el módulo)

```python
# Código hardcodeado en afipws_connection.py
def get_afip_login_url(self, environment_type):
    if environment_type == "production":
        afip_login_url = "https://wsaa.afip.gov.ar/ws/services/LoginCms"
    else:
        afip_login_url = "https://wsaahomo.afip.gov.ar/ws/services/LoginCms"
    return afip_login_url
```

**Si AFIP cambia la URL:**

1. ❌ Modificar código fuente
2. ❌ Reiniciar Odoo
3. ❌ Riesgo de romper otros módulos
4. ❌ Difícil de mantener en múltiples ambientes

### Ahora (con el módulo)

**Si AFIP cambia la URL:**

1. ✅ Ir a Settings > AFIP > Configuración de URLs
2. ✅ Editar la URL
3. ✅ Guardar
4. ✅ Listo (sin reiniciar ni modificar código)

## Verificación de Funcionamiento

### Paso 1: Verificar que las URLs configuradas se usen

1. Ir a **Settings > AFIP > Conexiones**
2. Abrir una conexión existente o crear una nueva
3. Verificar los campos computados:
   - **AFIP Login URL**: Debe mostrar la URL configurada
   - **AFIP WS URL**: Debe mostrar la URL configurada

### Paso 2: Revisar logs

Al conectar a AFIP, deberías ver en los logs:

```
INFO: URL obtenida desde configuración para wsaa (homologation):
https://wsaahomo.afip.gov.ar/ws/services/LoginCms
```

Si NO hay configuración, verás:

```
WARNING: Usando URL hardcodeada para wsaa (homologation).
Configure las URLs en Settings > AFIP > Configuración de URLs
```

### Paso 3: Probar facturación

1. Crear una factura
2. Validarla
3. Si se conecta exitosamente a AFIP, el módulo está funcionando correctamente

## Troubleshooting

### El módulo no aparece en Apps

**Causa**: La lista de módulos no se actualizó

**Solución**:

```bash
# Reiniciar Odoo
docker-compose restart odoo

# O actualizar lista de módulos desde la interfaz
# Settings > Activate Developer Mode > Apps > Update Apps List
```

### Error al instalar: "Module not found"

**Causa**: El módulo no está en el path de addons

**Verificar**:

```bash
# Debe existir
ls odoo/custom/src/private/l10n_ar_afipws_urls/

# Verificar que __manifest__.py existe
cat odoo/custom/src/private/l10n_ar_afipws_urls/__manifest__.py
```

### Las URLs configuradas no se están usando

**Verificar**:

1. Que el módulo esté instalado (Apps > Buscar "l10n_ar_afipws_urls" > Debe decir
   "Instalado")
2. Que las configuraciones estén activas (Settings > AFIP > Configuración de URLs >
   Campo "Activo")
3. Revisar logs de Odoo para ver qué URL se está usando

### Error: "Ya existe una configuración para este servicio y entorno"

**Causa**: Constraint SQL impide duplicados

**Solución**: Editar la configuración existente en lugar de crear una nueva

## Próximos Pasos

1. ✅ **Instalar el módulo** en tu ambiente de desarrollo
2. ✅ **Verificar** que las URLs se cargan correctamente
3. ✅ **Probar** conexión a AFIP
4. ✅ **Actualizar URLs** si es necesario para solucionar tu error actual
5. ✅ **Documentar** cualquier URL nueva que AFIP proporcione

## Recursos

- **README del módulo**: `odoo/custom/src/private/l10n_ar_afipws_urls/README.md`
- **Código fuente**: `odoo/custom/src/private/l10n_ar_afipws_urls/`
- **Datos de URLs**:
  `odoo/custom/src/private/l10n_ar_afipws_urls/data/afipws_url_config_data.xml`

## Soporte

Si tienes problemas con la instalación o uso del módulo, revisa:

1. Los logs de Odoo
2. El README del módulo
3. La documentación de AFIP

---

**Autor**: Sebastian **Fecha**: 2025-12-27 **Versión**: 1.0.0
