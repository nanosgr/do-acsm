# Arquitectura de Webservices AFIP en Odoo

## Documento de Análisis Técnico Completo

**Fecha**: 2025-12-24 **Proyecto**: do-acsm (Doodba Projects) **Módulos Analizados**:
l10n_ar_afipws, l10n_ar_afipws_fe, l10n_ar **Fuentes**: Código Odoo, Ejemplos AFIP
oficiales (VB.NET, PowerShell), PyAFIPWS

---

## Tabla de Contenidos

1. [Introducción](#introducción)
2. [Arquitectura General](#arquitectura-general)
3. [Jerarquía de Módulos](#jerarquía-de-módulos)
4. [Flujo de Autenticación WSAA](#flujo-de-autenticación-wsaa)
5. [Implementación de Webservices](#implementación-de-webservices)
6. [Patrones de Diseño](#patrones-de-diseño)
7. [Gestión de Certificados](#gestión-de-certificados)
8. [Facturación Electrónica](#facturación-electrónica)
9. [Referencias Técnicas](#referencias-técnicas)

---

## Introducción

Este documento describe la arquitectura completa de integración con los webservices de
AFIP (Administración Federal de Ingresos Públicos) en Odoo, específicamente para el
contexto argentino. La implementación utiliza la biblioteca PyAFIPWS para comunicarse
con los servicios SOAP de AFIP.

### Propósito

- Documentar la arquitectura multicapa de localización argentina
- Explicar el flujo de autenticación y autorización (WSAA)
- Detallar la implementación de facturación electrónica
- Proporcionar ejemplos prácticos de uso

### Scope

**Incluye**:

- Módulo base l10n_ar_afipws (Webservices AFIP)
- Módulo l10n_ar_afipws_fe (Facturación Electrónica)
- Integración con PyAFIPWS
- Gestión de certificados digitales
- Consulta de padrón AFIP

**No incluye**:

- Detalles de implementación de otros módulos de localización (POS, compras, etc.)
- Configuración de infraestructura de servidores
- Aspectos legales o regulatorios

---

## Arquitectura General

### Diagrama de Capas

```
┌──────────────────────────────────────────────────────────────────┐
│                    CAPA DE APLICACIÓN                            │
│                                                                  │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐      │
│  │  POS AFIP FE   │  │   Reportes AR  │  │   UX Mejoras   │      │
│  │ (l10n_ar_pos_  │  │ (l10n_ar_      │  │  (l10n_ar_ux)  │      │
│  │  afipws_fe)    │  │  reports)      │  │                │      │
│  └────────┬───────┘  └────────────────┘  └────────────────┘      │
└───────────┼──────────────────────────────────────────────────────┘
            │
┌───────────▼──────────────────────────────────────────────────────┐
│               CAPA DE FACTURACIÓN ELECTRÓNICA                    │
│                                                                  │
│  ┌──────────────────────────────────────────────────────┐        │
│  │   l10n_ar_afipws_fe (Facturación Electrónica)        │        │
│  │   - AccountMove (campos CAE, QR, resultados)         │        │
│  │   - AccountMoveWs (lógica WS)                        │        │
│  │   - AccountJournal (configuración diarios)           │        │
│  │   - Wizards (validación movimientos)                 │        │
│  └───────────────────────┬──────────────────────────────┘        │
└─────────────────────────┼────────────────────────────────────────┘
                          │
┌─────────────────────────▼────────────────────────────────────────┐
│            CAPA DE WEBSERVICES AFIP (Base)                       │
│                                                                  │
│  ┌──────────────────────────────────────────────────────┐        │
│  │   l10n_ar_afipws (Webservices AFIP)                  │        │
│  │   - AfipwsConnection (gestión conexiones)            │        │
│  │   - AfipwsCertificate (certificados X509)            │        │
│  │   - AfipwsCertificateAlias (DN/aliases)              │        │
│  │   - ResCompany (autenticación WSAA)                  │        │
│  │   - ResPartner (consulta padrón)                     │        │
│  └───────────────────────┬──────────────────────────────┘        │
└─────────────────────────┼────────────────────────────────────────┘
                          │
┌─────────────────────────▼────────────────────────────────────────┐
│            BIBLIOTECA PyAFIPWS (Python)                          │
│                                                                  │
│  ┌──────────────────────────────────────────────────────┐        │
│  │   PyAFIPWS - Wrapper Python de WS AFIP               │        │
│  │   - WSAA (autenticación)                             │        │
│  │   - WSFE, WSMTXCA, WSFEX (facturación)               │        │
│  │   - WSFECred (facturas de crédito)                   │        │
│  │   - WSSrPadronA4/A5/A10/A100 (consulta padrón)       │        │
│  └───────────────────────┬──────────────────────────────┘        │
└─────────────────────────┼────────────────────────────────────────┘
                          │ (pysimplesoap, OpenSSL)
┌─────────────────────────▼────────────────────────────────────────┐
│         WEBSERVICES AFIP (SOAP/XML over HTTPS)                   │
│                                                                  │
│  ┌──────────────────────────────────────────────────────┐        │
│  │   Entornos AFIP:                                     │        │
│  │   - Production: wsaa.afip.gov.ar, aws.afip.gov.ar    │        │
│  │   - Homologación: wsaahomo.afip.gov.ar               │        │
│  │                                                      │        │
│  │   Servicios:                                         │        │
│  │   - WSAA (Login CMS)                                 │        │
│  │   - WSFE (Factura Electrónica)                       │        │
│  │   - WSMTXCA (Factura Multipropósito)                 │        │
│  │   - WSFEX (Factura Exportación)                      │        │
│  │   - WSFECred (Factura de Crédito)                    │        │
│  │   - WS Padrón (Consulta contribuyentes)              │        │
│  └──────────────────────────────────────────────────────┘        │
└──────────────────────────────────────────────────────────────────┘
```

---

## Jerarquía de Módulos

### Dependencias y Relaciones

```
Odoo Core: account
    │
    ├─→ l10n_latam_base (LATAM Base)
    │   └─→ l10n_latam_invoice_document (Documentos LATAM)
    │
    └─→ l10n_ar (Argentina Base) [v18.0.1.0.0]
        ├── Chart of Accounts (3 templates: RI, EX, Monotributo)
        ├── Tipos de documentos AFIP
        ├── Responsabilidades IVA
        ├── Impuestos configurados
        └── Datos de partner y moneda
        │
        ├─→ l10n_ar_ux (UX Enhancement) [auto_install: True]
        │   └── Mejoras de experiencia de usuario
        │
        ├─→ l10n_ar_bank (Bancos Argentinos) [auto_install: True]
        │   └── Datos de bancos argentinos
        │
        └─→ l10n_ar_afipws (AFIP Webservices Base) [v18.0.1.0.0]
            ├── Dependencias Python: pyafipws, OpenSSL, pysimplesoap
            ├── 6 modelos principales
            ├── 2 wizards
            ├── Gestión de certificados digitales
            └── Conexiones a AFIP
            │
            └─→ l10n_ar_afipws_fe (Facturación Electrónica) [v18.0.2.0.0]
                ├── Dependencia: account_debit_note
                ├── 7 modelos (1,364 líneas)
                ├── Campos AFIP: CAE, QR, resultados
                └── Integración con WSFE/WSMTXCA/WSFEX/WSFECred
                │
                └─→ l10n_ar_pos_afipws_fe (POS + FE) [v18.0.1.0.0]
                    ├── Dependencia: point_of_sale
                    └── Facturación electrónica en POS
```

### Estructura de Directorios l10n_ar_afipws

```
l10n_ar_afipws/
├── __manifest__.py                # Declaración del módulo
├── __init__.py
│
├── models/                        # 6 modelos principales
│   ├── __init__.py
│   ├── afipws_certificate_alias.py    (199 líneas)
│   ├── afipws_certificate.py          (133 líneas)
│   ├── afipws_connection.py           (189 líneas)
│   ├── res_company.py                 (256 líneas) ⭐
│   ├── res_config_settings.py         (16 líneas)
│   └── res_partner.py                 (138 líneas)
│
├── wizard/                        # Asistentes
│   ├── __init__.py
│   ├── upload_certificate_wizard.py
│   └── res_partner_update_from_padron_wizard.py
│
├── views/                         # Vistas XML
│   ├── afipws_menuitem.xml
│   ├── afipws_certificate_view.xml
│   ├── afipws_certificate_alias_view.xml
│   ├── afipws_connection_view.xml
│   ├── res_config_settings.xml
│   └── res_partner.xml
│
├── security/                      # Seguridad y permisos
│   ├── ir.model.access.csv            (10 reglas de acceso)
│   └── security.xml
│
├── data/                          # Datos iniciales
│   └── ir.actions.url_data.xml
│
└── demo/                          # Datos de demostración
    ├── certificate_demo.xml
    └── parameter_demo.xml
```

### Estructura de Directorios l10n_ar_afipws_fe

```
l10n_ar_afipws_fe/
├── __manifest__.py
├── __init__.py
│
├── models/                        # 7 archivos (1,364 líneas)
│   ├── __init__.py
│   ├── account_move.py                (340 líneas) - Campos AFIP
│   ├── account_move_ws.py             (592 líneas) ⭐ - Lógica WS
│   ├── account_journal.py             (92 líneas)
│   ├── account_journal_ws.py          (196 líneas) - Métodos WS
│   ├── afipws_connection.py           (97 líneas)
│   ├── res_company.py                 (11 líneas)
│   └── res_config_settings.py         (25 líneas)
│
├── wizard/
│   └── account_validate_account_move.py
│
├── views/                         # 4 vistas principales
│   ├── account_journal_view.xml
│   ├── account_move_view.xml
│   ├── res_config_settings.xml
│   └── account_move_templates.xml
│
└── security/
    └── ir.model.access.csv
```

---

## Flujo de Autenticación WSAA

### ¿Qué es WSAA?

WSAA (Web Service de Autenticación y Autorización) es el servicio de AFIP que permite a
las aplicaciones obtener credenciales de acceso (Token y Sign) para consumir otros
webservices de AFIP. Es el **único punto de entrada** para autenticación en todos los
servicios de AFIP.

### Diagrama de Flujo Completo

```
┌─────────────────────────────────────────────────────────────────────┐
│                        PASO 1: Preparación                          │
│                                                                      │
│  ┌──────────────────┐                                               │
│  │  Certificado     │  ┌────────────────┐                          │
│  │  X509 + Key      │  │  Servicio ID   │                          │
│  │  (PEM format)    │  │  (ej: "wsfe")  │                          │
│  └────────┬─────────┘  └────────┬───────┘                          │
│           │                     │                                   │
│           └──────────┬──────────┘                                   │
└──────────────────────┼──────────────────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────────────────┐
│                PASO 2: Crear TRA (Ticket de Acceso Remoto)          │
│                                                                      │
│  Generar XML LoginTicketRequest:                                    │
│                                                                      │
│  <?xml version="1.0" encoding="UTF-8"?>                             │
│  <loginTicketRequest>                                               │
│    <header>                                                         │
│      <uniqueId>1234567890</uniqueId>                               │
│      <generationTime>2025-12-24T10:00:00-03:00</generationTime>    │
│      <expirationTime>2025-12-24T22:00:00-03:00</expirationTime>    │
│    </header>                                                        │
│    <service>wsfe</service>                                          │
│  </loginTicketRequest>                                              │
│                                                                      │
│  Valores importantes:                                               │
│  - uniqueId: Identificador único del requerimiento                  │
│  - generationTime: Now - 10 minutos (tolerancia reloj)              │
│  - expirationTime: Now + 10 minutos (puede ser hasta 12 horas)     │
│  - service: ID del servicio (wsfe, wsmtxca, wsfex, etc.)           │
└──────────────────────┬──────────────────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────────────────┐
│            PASO 3: Firmar TRA con Certificado (CMS)                 │
│                                                                      │
│  Proceso de firma:                                                  │
│  1. Convertir XML a bytes (UTF-8)                                   │
│  2. Crear objeto ContentInfo con los bytes                          │
│  3. Crear objeto SignedCms                                          │
│  4. Crear CmsSigner con el certificado X509                         │
│  5. Firmar usando PKCS#7                                            │
│  6. Encodear resultado en Base64                                    │
│                                                                      │
│  Resultado: CMS firmado en Base64                                   │
│                                                                      │
│  En .NET:                                                           │
│    SignedCms.ComputeSignature(cmsSigner)                            │
│                                                                      │
│  En PowerShell/OpenSSL:                                             │
│    openssl cms -sign -in TRA.xml -signer cert.crt -inkey key.pem   │
│            -nodetach -outform der | openssl base64                  │
│                                                                      │
│  En Python (PyAFIPWS):                                              │
│    wsaa.CreateTRA(service, ttl)                                     │
│    wsaa.SignTRA(certificate_pem, privatekey_pem)                    │
└──────────────────────┬──────────────────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────────────────┐
│               PASO 4: Invocar LoginCms (WSAA)                       │
│                                                                      │
│  SOAP Request:                                                      │
│  POST https://wsaahomo.afip.gov.ar/ws/services/LoginCms             │
│                                                                      │
│  <soapenv:Envelope>                                                 │
│    <soapenv:Body>                                                   │
│      <loginCms xmlns="http://wsaa.view.sua.dvadac...">              │
│        <in0>BASE64_CMS_FIRMADO_AQUI</in0>                          │
│      </loginCms>                                                    │
│    </soapenv:Body>                                                  │
│  </soapenv:Envelope>                                                │
│                                                                      │
│  URLs por entorno:                                                  │
│  - Production:    https://wsaa.afip.gov.ar/ws/services/LoginCms     │
│  - Homologación:  https://wsaahomo.afip.gov.ar/ws/services/LoginCms │
└──────────────────────┬──────────────────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────────────────┐
│            PASO 5: Recibir LoginTicketResponse                      │
│                                                                      │
│  SOAP Response (XML escapado dentro del SOAP):                      │
│                                                                      │
│  <loginCmsReturn>&lt;?xml version="1.0"?&gt;                        │
│  &lt;loginTicketResponse version="1.0"&gt;                          │
│    &lt;header&gt;                                                   │
│      &lt;source&gt;CN=wsaahomo, O=AFIP...&lt;/source&gt;           │
│      &lt;destination&gt;CUIT 20123456789...&lt;/destination&gt;    │
│      &lt;uniqueId&gt;1234567890&lt;/uniqueId&gt;                   │
│      &lt;generationTime&gt;...&lt;/generationTime&gt;              │
│      &lt;expirationTime&gt;...&lt;/expirationTime&gt;              │
│    &lt;/header&gt;                                                  │
│    &lt;credentials&gt;                                              │
│      &lt;token&gt;BASE64_TOKEN_AQUI&lt;/token&gt;                  │
│      &lt;sign&gt;BASE64_SIGNATURE_AQUI&lt;/sign&gt;                │
│    &lt;/credentials&gt;                                             │
│  &lt;/loginTicketResponse&gt;                                       │
│  </loginCmsReturn>                                                  │
│                                                                      │
│  Importante:                                                        │
│  - El XML está escapado (&lt; → <, &gt; → >)                       │
│  - Debe decodificarse antes de parsearlo                            │
│  - Token válido por 12 horas (default: 5 horas en Odoo)            │
└──────────────────────┬──────────────────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────────────────┐
│          PASO 6: Parsear y Extraer Credenciales                     │
│                                                                      │
│  Python (html.unescape):                                            │
│    import html                                                      │
│    decoded_xml = html.unescape(escaped_xml)                         │
│    root = ET.fromstring(decoded_xml)                                │
│    token = root.find('.//token').text                               │
│    sign = root.find('.//sign').text                                 │
│                                                                      │
│  Almacenar en AfipwsConnection:                                     │
│    - uniqueid                                                       │
│    - generationtime                                                 │
│    - expirationtime                                                 │
│    - token                                                          │
│    - sign                                                           │
│                                                                      │
│  Cache local (opcional):                                            │
│    wsaa.InstallDir/cache/{md5_hash}.xml                             │
└──────────────────────┬──────────────────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────────────────┐
│         PASO 7: Usar Token y Sign en otros Webservices             │
│                                                                      │
│  Cada request a WSFE, WSMTXCA, WSFEX, etc. incluye:                │
│                                                                      │
│  <soapenv:Envelope>                                                 │
│    <soapenv:Body>                                                   │
│      <FECAESolicitar>                                               │
│        <Auth>                                                       │
│          <Token>TOKEN_DESDE_WSAA</Token>                            │
│          <Sign>SIGN_DESDE_WSAA</Sign>                               │
│          <Cuit>20123456789</Cuit>                                   │
│        </Auth>                                                      │
│        <FeCAEReq>                                                   │
│          <!-- Datos de la factura -->                               │
│        </FeCAEReq>                                                  │
│      </FECAESolicitar>                                              │
│    </soapenv:Body>                                                  │
│  </soapenv:Envelope>                                                │
│                                                                      │
│  Si Token/Sign vencen o son inválidos: repetir desde PASO 1        │
└─────────────────────────────────────────────────────────────────────┘
```

### Implementación en Odoo (ResCompany.authenticate)

**Archivo**: `l10n_ar_afipws/models/res_company.py:256`

```python
def authenticate(self, service, afipws_connection_id, environment_type):
    """
    Autentica con WSAA y crea una conexión

    Args:
        service: ID del servicio (wsfe, wsmtxca, wsfex, etc.)
        afipws_connection_id: ID de conexión existente (para reuso)
        environment_type: 'production' o 'homologation'

    Returns:
        AfipwsConnection record con token y sign válidos
    """
    self.ensure_one()

    # 1. Obtener certificado y clave privada
    certificate, private_key = self.get_key_and_certificate(environment_type)

    # 2. Inicializar PyAFIPWS WSAA
    wsaa = WSAA()

    # 3. Crear TRA (Ticket de Acceso Remoto)
    tra = wsaa.CreateTRA(service=service, ttl=18000)  # 5 horas

    # 4. Firmar TRA con certificado
    cms = wsaa.SignTRA(tra, certificate, private_key)

    # 5. Invocar LoginCms
    wsaa_url = self._get_wsaa_url(environment_type)
    wsaa.Conectar(url=wsaa_url)
    wsaa.LoginCMS(cms)

    # 6. Verificar errores
    if wsaa.Excepcion:
        raise UserError(_('AFIP Error: %s') % wsaa.Excepcion)

    # 7. Crear/actualizar conexión
    connection_vals = {
        'company_id': self.id,
        'type': environment_type,
        'afip_ws': service,
        'uniqueid': wsaa.UniqueId,
        'generationtime': datetime.strptime(wsaa.GenerationTime, '%Y-%m-%dT%H:%M:%S'),
        'expirationtime': datetime.strptime(wsaa.ExpirationTime, '%Y-%m-%dT%H:%M:%S'),
        'token': wsaa.Token,
        'sign': wsaa.Sign,
    }

    if afipws_connection_id:
        connection = afipws_connection_id
        connection.write(connection_vals)
    else:
        connection = self.env['afipws.connection'].create(connection_vals)

    return connection
```

### Comparativa de Implementaciones

| Aspecto               | VB.NET (AFIP Oficial) | PowerShell (AFIP Oficial) | Python (PyAFIPWS/Odoo)    |
| --------------------- | --------------------- | ------------------------- | ------------------------- |
| **Crear TRA**         | XmlDocument manual    | XmlDocument manual        | `wsaa.CreateTRA()`        |
| **Firmar CMS**        | SignedCms.NET         | OpenSSL CLI               | `wsaa.SignTRA()`          |
| **Invocar WSAA**      | Web Reference SOAP    | New-WebServiceProxy       | `wsaa.LoginCMS()`         |
| **Parsear respuesta** | XmlDocument           | Automático                | Automático                |
| **Cache**             | No implementado       | Archivos locales          | Opcionalmente en archivos |
| **Complejidad**       | Alta (200+ líneas)    | Media (75 líneas)         | Baja (abstracción)        |

---

## Implementación de Webservices

### Webservices Disponibles en l10n_ar_afipws

#### 1. WS Padrón (Consulta de Contribuyentes)

**Propósito**: Consultar datos del padrón de contribuyentes de AFIP.

**Servicios**:

- `ws_sr_padron_a4`: Alcance 4 (datos básicos)
- `ws_sr_padron_a5`: Alcance 5 (datos extendidos)
- `ws_sr_padron_a10`: Alcance 10
- `ws_sr_padron_a100`: Alcance 100

**URLs** (definidas en `afipws_connection.py:189`):

```python
# Production
'ws_sr_padron_a5': 'https://aws.afip.gov.ar/sr-padron/webservices/personaServiceA5?wsdl'

# Homologation
'ws_sr_padron_a5': 'https://awshomo.afip.gov.ar/sr-padron/webservices/personaServiceA5?wsdl'
```

**Implementación en ResPartner** (`res_partner.py:138`):

```python
def get_data_from_padron_afip(self, cuit):
    """
    Consulta datos del contribuyente en el padrón AFIP

    Args:
        cuit: CUIT a consultar

    Returns:
        dict con datos del contribuyente
    """
    connection = self.env.company.get_connection('ws_sr_padron_a5')
    ws = connection._get_ws()

    ws.Consultar(cuit)

    if ws.Excepcion:
        raise UserError(_('AFIP Error: %s') % ws.Excepcion)

    return {
        'name': ws.nombre,
        'vat': ws.cuit,
        'l10n_ar_afip_responsibility_type_id': self._get_l10n_ar_afip_responsibility_type_id(ws.impuestos),
        'street': ws.direccion,
        'city': ws.localidad,
        'state_id': self._get_state_id(ws.provincia),
        'zip': ws.cod_postal,
        'mipyme_required': ws.actividad_monotributo,
        'last_update_census': fields.Date.today(),
    }
```

#### 2. WSFECred (Facturas de Crédito Electrónicas MiPyME)

**Propósito**: Emitir facturas de crédito electrónicas para MiPyMEs.

**URLs** (definidas en `afipws_connection.py`):

```python
# Production
'wsfecred': 'https://serviciosjava.afip.gob.ar/wsfecred/FECredService?wsdl'

# Homologation
'wsfecred': 'https://fwshomo.afip.gov.ar/wsfecred/FECredService?wsdl'
```

### Webservices de Facturación Electrónica (l10n_ar_afipws_fe)

#### 3. WSFE (Factura Electrónica - Régimen General)

**Propósito**: Servicio principal de facturación electrónica para el régimen general.

**Tipos de comprobantes soportados**:

- Factura A (código 1)
- Factura B (código 6)
- Factura C (código 11)
- Notas de crédito/débito

**Método principal** (`account_move_ws.py:34-57`):

```python
def wsfe_pyafipws_create_invoice(self, ws, invoice_info):
    """
    Crea una factura en WSFE usando PyAFIPWS

    Args:
        ws: Objeto PyAFIPWS WSFE
        invoice_info: dict con datos de la factura
    """
    ws.CrearFactura(
        concepto=invoice_info["concepto"],               # 1=Productos, 2=Servicios, 3=Ambos
        tipo_doc=invoice_info["tipo_doc"],               # 80=CUIT, 96=DNI, 99=Consumidor Final
        nro_doc=invoice_info["nro_doc"],                 # Número documento cliente
        tipo_cbte=invoice_info["doc_afip_code"],         # Código tipo comprobante AFIP
        punto_vta=invoice_info["pos_number"],            # Punto de venta
        cbt_desde=invoice_info["cbt_desde"],             # Número comprobante
        cbt_hasta=invoice_info["cbt_hasta"],             # Número comprobante (mismo)
        imp_total=invoice_info["imp_total"],             # Importe total
        imp_tot_conc=invoice_info["imp_tot_conc"],       # Importe no gravado
        imp_neto=invoice_info["imp_neto"],               # Importe neto gravado
        imp_iva=invoice_info["imp_iva"],                 # Importe IVA
        imp_trib=invoice_info["imp_trib"],               # Otros tributos
        imp_op_ex=invoice_info["imp_op_ex"],             # Importe exento
        fecha_cbte=invoice_info["fecha_cbte"],           # Fecha comprobante (YYYYMMDD)
        fecha_venc_pago=invoice_info["fecha_venc_pago"], # Fecha vencimiento pago
        fecha_serv_desde=invoice_info["fecha_serv_desde"], # Fecha servicio desde
        fecha_serv_hasta=invoice_info["fecha_serv_hasta"], # Fecha servicio hasta
        moneda_id=invoice_info["moneda_id"],             # Código moneda AFIP
        moneda_ctz=invoice_info["moneda_ctz"],           # Cotización moneda
        cancela_misma_moneda_ext=invoice_info["cancela_misma_moneda_ext"],
        condicion_iva_receptor_id=invoice_info["condicion_iva_receptor_id"],
    )
```

**Agregar información complementaria** (`account_move_ws.py:179-209`):

```python
def wsfe_invoice_add_info(self, ws, invoice_info):
    """
    Agrega información adicional a la factura WSFE
    """
    # Factura de crédito electrónica MiPyME
    if invoice_info["mipyme_fce"]:
        # CBU del cliente
        ws.AgregarOpcional(opcional_id=2101, valor=self.partner_bank_id.acc_number)
        # Tipo de transmisión
        transmission_type = self.env["ir.config_parameter"].sudo().get_param(
            "l10n_ar_afipws_fe.fce_transmission", ""
        )
        if transmission_type:
            ws.AgregarOpcional(opcional_id=27, valor=transmission_type)

    # Comprobantes asociados (notas de crédito/débito)
    if invoice_info["CbteAsoc"]:
        doc_number_parts = self._l10n_ar_get_document_number_parts(
            invoice_info["CbteAsoc"].l10n_latam_document_number,
            invoice_info["CbteAsoc"].l10n_latam_document_type_id.code,
        )
        ws.AgregarCmpAsoc(
            tipo=invoice_info["CbteAsoc"].l10n_latam_document_type_id.code,
            pto_vta=doc_number_parts["point_of_sale"],
            nro=doc_number_parts["invoice_number"],
            cuit=self.company_id.vat,
            fecha=invoice_info["CbteAsoc"].invoice_date.strftime("%Y%m%d"),
        )

    # Agregar IVA y tributos
    self.pyafipws_add_tax(ws)
```

**Agregar IVA** (`account_move_ws.py:150-153`):

```python
def pyafipws_add_tax(self, ws):
    """
    Agrega alícuotas de IVA a la factura
    """
    vat_items = self._get_vat()
    for item in vat_items:
        ws.AgregarIva(
            iva_id=item["Id"],        # Código alícuota AFIP (3=0%, 4=10.5%, 5=21%, etc.)
            base_imp=item["BaseImp"], # Base imponible
            importe=item["Importe"]   # Importe IVA
        )
```

**Autorizar factura** (método continúa en líneas siguientes):

```python
def wsfe_request_autorization(self, ws):
    """
    Solicita autorización a AFIP (CAE)
    """
    ws.CAESolicitar()

    if ws.Excepcion:
        raise UserError(_('AFIP Error: %s') % ws.Excepcion)

    return {
        'afip_auth_code': ws.CAE,                    # CAE (Código de Autorización Electrónico)
        'afip_auth_code_due': ws.Vencimiento,        # Fecha vencimiento CAE
        'afip_result': ws.Resultado,                 # A=Aceptado, R=Rechazado, O=Observado
        'afip_message': '\n'.join(ws.Obs or []),     # Observaciones
        'afip_xml_request': ws.XmlRequest,           # XML request enviado
        'afip_xml_response': ws.XmlResponse,         # XML response recibido
    }
```

#### 4. WSMTXCA (Factura Multipropósito)

**Propósito**: Servicio de facturación con detalle de items (más completo que WSFE).

**Diferencias con WSFE**:

- Permite detalle línea por línea de items
- Soporta observaciones generales
- Mayor información de subtotales

**Método** (`account_move_ws.py:59-83`):

```python
def wsmtxca_pyafipws_create_invoice(self, ws, invoice_info):
    ws.CrearFactura(
        # Similar a WSFE pero con campos adicionales:
        imp_subtotal=invoice_info["imp_subtotal"],  # Subtotal antes de impuestos
        obs_generales=invoice_info["obs_generales"], # Observaciones
        # ... resto de campos
    )
```

#### 5. WSFEX (Factura de Exportación)

**Propósito**: Facturación para operaciones de exportación.

**Características especiales**:

- Requiere datos de comercio exterior
- Información de incoterms
- País de destino
- Forma de pago internacional

**Método** (`account_move_ws.py:85-110`):

```python
def wsfex_pyafipws_create_invoice(self, ws, invoice_info):
    ws.CrearFactura(
        tipo_cbte=invoice_info["doc_afip_code"],
        punto_vta=invoice_info["pos_number"],
        cbte_nro=invoice_info["cbte_nro"],
        fecha_cbte=invoice_info["fecha_cbte"],
        imp_total=invoice_info["imp_total"],
        tipo_expo=invoice_info["tipo_expo"],          # Tipo exportación (1=definitiva, etc.)
        permiso_existente=invoice_info["permiso_existente"], # S/N
        pais_dst_cmp=invoice_info["pais_dst_cmp"],    # País destino (código AFIP)
        nombre_cliente=invoice_info["nombre_cliente"],
        cuit_pais_cliente=invoice_info["cuit_pais_cliente"],
        domicilio_cliente=invoice_info["domicilio_cliente"],
        id_impositivo=invoice_info["id_impositivo"],  # ID fiscal extranjero
        moneda_id=invoice_info["moneda_id"],
        moneda_ctz=invoice_info["moneda_ctz"],
        obs_comerciales=invoice_info["obs_comerciales"],
        obs_generales=invoice_info["obs_generales"],
        forma_pago=invoice_info["forma_pago"],
        incoterms=invoice_info["incoterms"],          # Código incoterm
        idioma_cbte=invoice_info["idioma_cbte"],      # 1=Español, 2=Inglés, 3=Portugués
        incoterms_ds=invoice_info["incoterms_ds"],    # Descripción incoterm
        fecha_pago=invoice_info["fecha_pago"],
        # ...
    )
```

#### 6. WSBFE (Factura de Exportación - Bono Fiscal)

**Propósito**: Facturación con bonos fiscales.

**Método** (`account_move_ws.py:112-136`):

```python
def wsbfe_pyafipws_create_invoice(self, ws, invoice_info):
    ws.CrearFactura(
        tipo_doc=invoice_info["tipo_doc"],
        nro_doc=invoice_info["nro_doc"],
        zona=invoice_info["zona"],                    # Zona económica
        tipo_cbte=invoice_info["doc_afip_code"],
        punto_vta=invoice_info["pos_number"],
        cbte_nro=invoice_info["cbte_nro"],
        fecha_cbte=invoice_info["fecha_cbte"],
        imp_total=invoice_info["imp_total"],
        imp_neto=invoice_info["imp_neto"],
        imp_iva=invoice_info["imp_iva"],
        imp_tot_conc=invoice_info["imp_tot_conc"],
        impto_liq_rni=invoice_info["impto_liq_rni"],  # Impuesto RNI
        imp_op_ex=invoice_info["imp_op_ex"],
        imp_perc=invoice_info["imp_perc"],            # Percepciones
        imp_iibb=invoice_info["imp_iibb"],            # Ingresos Brutos
        imp_perc_mun=invoice_info["imp_perc_mun"],    # Percepciones municipales
        imp_internos=invoice_info["imp_internos"],    # Impuestos internos
        moneda_id=invoice_info["moneda_id"],
        moneda_ctz=invoice_info["moneda_ctz"],
        fecha_venc_pago=invoice_info["fecha_venc_pago"],
        # ...
    )
```

### Patrón de Delegación Dinámica

Todos los webservices siguen el mismo patrón de delegación:

```python
def pyafipws_create_invoice(self, ws, invoice_info):
    """
    Método delegador que llama al método específico según el WS
    """
    afip_ws = self.journal_id.afip_ws  # ej: 'wsfe', 'wsmtxca', etc.

    # Buscar método específico: {afip_ws}_pyafipws_create_invoice
    method_name = f"{afip_ws}_pyafipws_create_invoice"

    if hasattr(self, method_name):
        return getattr(self, method_name)(ws, invoice_info)
    else:
        return _("AFIP WS %s not implemented") % afip_ws
```

Este patrón permite:

- Extensibilidad: Agregar nuevos WS sin modificar código existente
- Mantenibilidad: Cada WS tiene su lógica aislada
- Consistencia: Misma interfaz para todos los WS

---

## Patrones de Diseño

### 1. Patrón Prototype (Herencia de Modelos)

Odoo utiliza herencia de prototipos para extender modelos existentes sin crear nuevas
tablas.

```python
# En l10n_ar_afipws/models/res_company.py
class ResCompany(models.Model):
    _inherit = "res.company"  # Extiende el modelo existente

    # Agrega campos AFIP
    alias_ids = fields.One2many('afipws.certificate_alias', 'company_id')
    connection_ids = fields.One2many('afipws.connection', 'company_id')

    # Agrega métodos AFIP
    def get_connection(self, afip_ws):
        """Obtiene o crea una conexión AFIP"""
        pass

    def authenticate(self, service, connection_id, environment_type):
        """Autentica con WSAA"""
        pass
```

**Ventajas**:

- No duplica datos
- Mantiene relaciones existentes
- Permite desinstalar el módulo sin pérdida de datos base

### 2. Patrón Strategy (Delegación de Webservices)

Cada webservice tiene su propia estrategia de creación de facturas.

```python
# Delegador (Context)
def pyafipws_create_invoice(self, ws, invoice_info):
    afip_ws = self.journal_id.afip_ws
    method_name = f"{afip_ws}_pyafipws_create_invoice"

    if hasattr(self, method_name):
        # Delega a la estrategia específica
        return getattr(self, method_name)(ws, invoice_info)
    else:
        return _("AFIP WS %s not implemented") % afip_ws

# Estrategias concretas
def wsfe_pyafipws_create_invoice(self, ws, invoice_info):
    # Estrategia para WSFE
    ws.CrearFactura(...)

def wsmtxca_pyafipws_create_invoice(self, ws, invoice_info):
    # Estrategia para WSMTXCA
    ws.CrearFactura(...)

def wsfex_pyafipws_create_invoice(self, ws, invoice_info):
    # Estrategia para WSFEX
    ws.CrearFactura(...)
```

**Ventajas**:

- Fácil agregar nuevos webservices
- Código de cada WS aislado
- Testing independiente por WS

### 3. Patrón Template Method (Flujo de Facturación)

El flujo de facturación sigue un template method con pasos definidos.

```python
def action_post(self):
    """
    Template method para validar y autorizar facturas
    """
    # 1. Validaciones previas
    self._check_invoice_data()

    # 2. Obtener próximo número
    next_number = self._get_next_invoice_number()

    # 3. Crear factura en PyAFIPWS
    ws = self._get_ws_connection()
    self.pyafipws_create_invoice(ws, invoice_info)  # HOOK

    # 4. Agregar información complementaria
    self.pyafipws_add_info(ws, afip_ws, invoice_info)  # HOOK

    # 5. Solicitar autorización
    result = self.pyafipws_request_autorization(ws, afip_ws)  # HOOK

    # 6. Procesar resultado
    self._process_afip_result(result)

    # 7. Generar QR y PDF
    self._generate_qr_code()

    return super().action_post()
```

Los métodos marcados como HOOK son puntos de extensión implementados por cada
webservice.

### 4. Patrón Factory (Creación de Conexiones)

```python
# En afipws_connection.py
class AfipwsConnection(models.Model):
    _name = "afipws.connection"

    def _get_ws(self):
        """
        Factory method: crea el objeto WS apropiado según afip_ws
        """
        # Importar clase PyAFIPWS correspondiente
        if self.afip_ws == 'wsfe':
            from pyafipws.wsfe import WSFE
            ws = WSFE()
        elif self.afip_ws == 'wsmtxca':
            from pyafipws.wsmtxca import WSMTXCA
            ws = WSMTXCA()
        elif self.afip_ws == 'wsfex':
            from pyafipws.wsfex import WSFEX
            ws = WSFEX()
        elif self.afip_ws == 'ws_sr_padron_a5':
            from pyafipws.ws_sr_padron_a5 import WSSrPadronA5
            ws = WSSrPadronA5()
        else:
            raise UserError(_('AFIP WS %s not supported') % self.afip_ws)

        # Configurar WS
        ws.Token = self.token
        ws.Sign = self.sign
        ws.Cuit = self.company_id.vat
        ws.Conectar(url=self.get_afip_ws_url(self.afip_ws, self.type))

        return ws
```

### 5. Patrón Singleton (Caché de Conexiones)

```python
# En res_company.py
def get_connection(self, afip_ws):
    """
    Obtiene o crea una conexión AFIP (singleton por servicio)
    """
    self.ensure_one()

    # Buscar conexión existente y válida
    connection = self.connection_ids.filtered(
        lambda c: c.afip_ws == afip_ws
        and c.type == self._get_environment_type()
        and c.expirationtime > fields.Datetime.now()
    )

    if connection:
        # Reutilizar conexión existente
        return connection[0]
    else:
        # Crear nueva conexión
        return self.authenticate(afip_ws, None, self._get_environment_type())
```

### 6. Patrón Chain of Responsibility (Búsqueda de Certificados)

```python
def get_key_and_certificate(self, environment_type):
    """
    Chain of Responsibility: busca certificados en orden de prioridad
    """
    self.ensure_one()

    # 1. Handler: Buscar en base de datos
    certificate = self.alias_ids.filtered(
        lambda a: a.type == environment_type and a.state == 'confirmed'
    ).certificate_id

    if certificate:
        return certificate.crt, certificate.key

    # 2. Handler: Buscar en archivos de configuración
    config = tools.config
    if environment_type == 'production':
        key_file = config.get('afip_prod_pkey_file')
        cert_file = config.get('afip_prod_cert_file')
    else:
        key_file = config.get('afip_homo_pkey_file')
        cert_file = config.get('afip_homo_cert_file')

    if key_file and cert_file:
        with open(key_file, 'r') as f:
            private_key = f.read()
        with open(cert_file, 'r') as f:
            certificate = f.read()
        return certificate, private_key

    # 3. No se encontró: Error
    raise UserError(_('No certificate found for %s') % environment_type)
```

---

## Gestión de Certificados

### Tipos de Certificados AFIP

AFIP requiere certificados X.509 para firmar las solicitudes de autenticación (TRA).

**Requisitos**:

- Formato: X.509 PEM
- Incluye: Clave pública + Clave privada
- Algoritmo: RSA 2048 bits (mínimo)
- Validez: Hasta 3 años
- Emisor: AFIP (después de generar CSR y subirlo en portal AFIP)

### Flujo de Generación de Certificados

```
┌─────────────────────────────────────────────────────────────────┐
│                  PASO 1: Generar Clave Privada                  │
│                                                                  │
│  OpenSSL:                                                        │
│    openssl genrsa -out private.key 2048                          │
│                                                                  │
│  En Odoo (AfipwsCertificateAlias.generate_key):                 │
│    from OpenSSL import crypto                                    │
│    key = crypto.PKey()                                           │
│    key.generate_key(crypto.TYPE_RSA, 2048)                       │
│    pem = crypto.dump_privatekey(crypto.FILETYPE_PEM, key)        │
└───────────────────────────┬─────────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────────┐
│            PASO 2: Crear CSR (Certificate Signing Request)      │
│                                                                  │
│  OpenSSL:                                                        │
│    openssl req -new -key private.key -out request.csr \         │
│      -subj "/C=AR/O=EMPRESA/CN=CUIT/serialNumber=CUIT..."       │
│                                                                  │
│  Campos importantes del Distinguished Name (DN):                │
│    - C (Country): AR                                            │
│    - O (Organization): Razón social                             │
│    - CN (Common Name): Alias/nombre                             │
│    - serialNumber: CUIT 20123456789                             │
│                                                                  │
│  En Odoo (AfipwsCertificateAlias.action_create_certificate_request): │
│    req = crypto.X509Req()                                        │
│    req.get_subject().C = "AR"                                    │
│    req.get_subject().O = self.company_id.name                    │
│    req.get_subject().CN = self.name                              │
│    req.get_subject().serialNumber = "CUIT " + self.company_id.vat│
│    req.set_pubkey(key)                                           │
│    req.sign(key, "sha256")                                       │
│    csr_pem = crypto.dump_certificate_request(                    │
│        crypto.FILETYPE_PEM, req                                  │
│    )                                                             │
└───────────────────────────┬─────────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────────┐
│                 PASO 3: Subir CSR al Portal AFIP                │
│                                                                  │
│  1. Ingresar a https://www.afip.gob.ar                           │
│  2. Login con CUIT y Clave Fiscal (nivel 3 o superior)          │
│  3. Ir a "Administrador de Relaciones de Clave Fiscal"          │
│  4. Sistema > Administrar Certificados Digitales                │
│  5. Crear Nueva Solicitud                                       │
│  6. Pegar el contenido del CSR (.csr)                           │
│  7. Especificar servicios que usará el certificado:             │
│     - wsfe (Factura Electrónica)                                │
│     - wsmtxca (Factura Multipropósito)                          │
│     - wsfex (Factura Exportación)                               │
│     - etc.                                                      │
│  8. AFIP valida y firma el certificado                          │
│  9. Descargar certificado firmado (.crt)                        │
└───────────────────────────┬─────────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────────┐
│          PASO 4: Importar Certificado Firmado a Odoo            │
│                                                                  │
│  Opción A: Vía interfaz Odoo                                    │
│    1. Settings > AFIP > Certificates                             │
│    2. Upload certificate wizard                                  │
│    3. Cargar .crt (certificado) y .key (clave privada)          │
│                                                                  │
│  Opción B: Vía archivos de configuración                        │
│    En odoo.conf:                                                │
│    [options]                                                    │
│    afip_homo_pkey_file = /path/to/homo_private.key              │
│    afip_homo_cert_file = /path/to/homo_certificate.crt          │
│    afip_prod_pkey_file = /path/to/prod_private.key              │
│    afip_prod_cert_file = /path/to/prod_certificate.crt          │
│                                                                  │
│  El certificado se almacena en:                                 │
│    - DB: afipws_certificate (PEM text)                          │
│    - File: Referenciado por config                              │
└───────────────────────────┬─────────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────────┐
│               PASO 5: Confirmar y Activar Certificado           │
│                                                                  │
│  En Odoo:                                                        │
│    - Estado: draft → confirmed                                   │
│    - Validar formato PEM                                         │
│    - Verificar que no esté vencido                              │
│    - Asociar con alias de entorno (production/homologation)     │
└─────────────────────────────────────────────────────────────────┘
```

### Modelo AfipwsCertificateAlias

**Propósito**: Gestiona los datos del Distinguished Name (DN) para generar certificados.

**Archivo**: `l10n_ar_afipws/models/afipws_certificate_alias.py:199`

**Campos principales**:

```python
class AfipwsCertificateAlias(models.Model):
    _name = "afipws.certificate_alias"
    _description = "AFIP Certificate Alias"

    name = fields.Char(required=True)  # Alias/CN
    company_id = fields.Many2one('res.company', required=True)
    type = fields.Selection([
        ('production', 'Production'),
        ('homologation', 'Homologation')
    ], required=True)
    state = fields.Selection([
        ('draft', 'Draft'),
        ('confirmed', 'Confirmed'),
        ('cancel', 'Cancelled')
    ], default='draft')

    # Datos DN
    country = fields.Char(default='AR')
    state_name = fields.Char()
    locality = fields.Char()
    organization = fields.Char()  # Razón social
    organizational_unit = fields.Char()
    common_name = fields.Char()  # CN
    serial_number = fields.Char()  # CUIT

    # Clave privada
    private_key = fields.Text()

    # CSR generado
    csr = fields.Text(readonly=True)

    # Certificado asociado
    certificate_id = fields.Many2one('afipws.certificate')
```

**Métodos principales**:

```python
def generate_key(self):
    """
    Genera clave privada RSA 2048 bits
    """
    from OpenSSL import crypto

    key = crypto.PKey()
    key.generate_key(crypto.TYPE_RSA, 2048)
    pem = crypto.dump_privatekey(crypto.FILETYPE_PEM, key)

    self.write({'private_key': pem.decode('utf-8')})
    return True

def action_create_certificate_request(self):
    """
    Crea CSR (Certificate Signing Request)
    """
    from OpenSSL import crypto

    # Cargar clave privada
    key = crypto.load_privatekey(
        crypto.FILETYPE_PEM,
        self.private_key.encode('utf-8')
    )

    # Crear request
    req = crypto.X509Req()
    subject = req.get_subject()

    subject.C = self.country or 'AR'
    subject.ST = self.state_name or ''
    subject.L = self.locality or ''
    subject.O = self.organization or self.company_id.name
    subject.OU = self.organizational_unit or ''
    subject.CN = self.common_name or self.name
    subject.serialNumber = f"CUIT {self.company_id.vat}"

    # Firmar con clave privada
    req.set_pubkey(key)
    req.sign(key, 'sha256')

    # Exportar a PEM
    csr_pem = crypto.dump_certificate_request(
        crypto.FILETYPE_PEM, req
    ).decode('utf-8')

    self.write({'csr': csr_pem})
    return True
```

### Modelo AfipwsCertificate

**Propósito**: Almacena certificados X.509 firmados por AFIP.

**Archivo**: `l10n_ar_afipws/models/afipws_certificate.py:133`

**Campos principales**:

```python
class AfipwsCertificate(models.Model):
    _name = "afipws.certificate"
    _description = "AFIP Certificate"

    name = fields.Char(required=True)
    alias_id = fields.Many2one('afipws.certificate_alias', required=True)
    state = fields.Selection([
        ('draft', 'Draft'),
        ('confirmed', 'Confirmed'),
        ('cancel', 'Cancelled')
    ], default='draft')

    # Certificado en formato PEM
    crt = fields.Text(required=True, help="Certificate in PEM format")

    # Clave privada en formato PEM
    key = fields.Text(required=True, help="Private key in PEM format")

    # Fechas del certificado
    date_from = fields.Datetime(readonly=True)
    date_to = fields.Datetime(readonly=True)
```

**Métodos principales**:

```python
def verify_crt(self):
    """
    Verifica el certificado y extrae información
    """
    from OpenSSL import crypto
    from datetime import datetime

    try:
        cert = crypto.load_certificate(
            crypto.FILETYPE_PEM,
            self.crt.encode('utf-8')
        )

        # Extraer fechas
        not_before = datetime.strptime(
            cert.get_notBefore().decode('utf-8'),
            '%Y%m%d%H%M%SZ'
        )
        not_after = datetime.strptime(
            cert.get_notAfter().decode('utf-8'),
            '%Y%m%d%H%M%SZ'
        )

        self.write({
            'date_from': not_before,
            'date_to': not_after,
        })

        # Verificar que no esté vencido
        if datetime.now() > not_after:
            raise UserError(_('Certificate is expired'))

        return True

    except Exception as e:
        raise UserError(_('Invalid certificate: %s') % str(e))

def get_certificate(self):
    """
    Retorna certificado y clave privada
    """
    self.ensure_one()
    return self.crt, self.key
```

### Seguridad de Certificados

**Niveles de acceso** (definidos en `security/ir.model.access.csv`):

| Modelo                   | Grupo        | Create | Read | Write | Delete |
| ------------------------ | ------------ | ------ | ---- | ----- | ------ |
| afipws.certificate       | group_system | ✓      | ✓    | ✓     | ✓      |
| afipws.certificate       | group_user   | -      | ✓    | -     | -      |
| afipws.certificate_alias | group_system | ✓      | ✓    | ✓     | ✓      |
| afipws.certificate_alias | group_user   | -      | ✓    | -     | -      |

**Recomendaciones de seguridad**:

1. **No versionar certificados**: Nunca incluir archivos .key o .crt en Git
2. **Usar variables de entorno**: Para rutas de archivos en producción
3. **Restringir permisos de archivo**: `chmod 600` para archivos de certificados
4. **Backup encriptado**: Guardar backups de certificados en formato encriptado
5. **Renovación proactiva**: Renovar certificados 1 mes antes del vencimiento
6. **Separar entornos**: Certificados diferentes para homologación y producción

---

## Facturación Electrónica

### Flujo Completo de Facturación

```
┌─────────────────────────────────────────────────────────────────┐
│           USUARIO: Crear factura en Odoo                        │
│  - Cliente, productos, impuestos                                │
│  - Tipo de documento AFIP (Factura A/B/C)                       │
│  - Punto de venta configurado                                   │
└───────────────────────┬─────────────────────────────────────────┘
                        │
┌───────────────────────▼─────────────────────────────────────────┐
│         ODOO: Validar factura (action_post)                     │
│  1. Validar datos obligatorios                                  │
│  2. Verificar diario con AFIP habilitado                        │
│  3. Obtener próximo número de factura                           │
│  4. Preparar datos para envío a AFIP                            │
└───────────────────────┬─────────────────────────────────────────┘
                        │
┌───────────────────────▼─────────────────────────────────────────┐
│       ODOO: Preparar invoice_info (dict con datos)              │
│                                                                  │
│  invoice_info = {                                               │
│    'doc_afip_code': 1,         # Código tipo comprobante        │
│    'pos_number': 1,            # Punto de venta                 │
│    'cbt_desde': 123,           # Número factura                 │
│    'concepto': 1,              # 1=Productos, 2=Servicios       │
│    'tipo_doc': 80,             # 80=CUIT, 96=DNI                │
│    'nro_doc': '20123456789',   # Número documento cliente       │
│    'imp_total': 1210.00,       # Total factura                  │
│    'imp_neto': 1000.00,        # Neto gravado                   │
│    'imp_iva': 210.00,          # IVA                            │
│    'imp_trib': 0.00,           # Otros tributos                 │
│    'imp_op_ex': 0.00,          # Exento                         │
│    'fecha_cbte': '20251224',   # Fecha comprobante              │
│    'moneda_id': 'PES',         # Código moneda AFIP             │
│    'moneda_ctz': 1.000,        # Cotización                     │
│    # ... más campos según WS                                    │
│  }                                                              │
└───────────────────────┬─────────────────────────────────────────┘
                        │
┌───────────────────────▼─────────────────────────────────────────┐
│        ODOO: Obtener conexión AFIP válida                       │
│                                                                  │
│  connection = company.get_connection('wsfe')                    │
│                                                                  │
│  Si no existe o está vencida:                                   │
│    → Autenticar con WSAA (ver flujo anterior)                   │
│    → Crear AfipwsConnection con token y sign                    │
│                                                                  │
│  Si existe y es válida:                                         │
│    → Reutilizar conexión                                        │
└───────────────────────┬─────────────────────────────────────────┘
                        │
┌───────────────────────▼─────────────────────────────────────────┐
│         ODOO: Obtener objeto PyAFIPWS                           │
│                                                                  │
│  ws = connection._get_ws()                                      │
│                                                                  │
│  # Factory crea objeto según afip_ws:                           │
│  if afip_ws == 'wsfe':                                          │
│      from pyafipws.wsfe import WSFE                             │
│      ws = WSFE()                                                │
│  elif afip_ws == 'wsmtxca':                                     │
│      from pyafipws.wsmtxca import WSMTXCA                       │
│      ws = WSMTXCA()                                             │
│  # ...                                                          │
│                                                                  │
│  # Configurar con credenciales:                                 │
│  ws.Token = connection.token                                    │
│  ws.Sign = connection.sign                                      │
│  ws.Cuit = company.vat                                          │
│  ws.Conectar(url=url_wsfe)                                      │
└───────────────────────┬─────────────────────────────────────────┘
                        │
┌───────────────────────▼─────────────────────────────────────────┐
│    PyAFIPWS: Crear factura (ws.CrearFactura)                    │
│                                                                  │
│  move.pyafipws_create_invoice(ws, invoice_info)                 │
│    ↓                                                            │
│  move.wsfe_pyafipws_create_invoice(ws, invoice_info)            │
│    ↓                                                            │
│  ws.CrearFactura(                                               │
│      concepto=1,                                                │
│      tipo_doc=80,                                               │
│      nro_doc='20123456789',                                     │
│      tipo_cbte=1,                                               │
│      punto_vta=1,                                               │
│      cbt_desde=123,                                             │
│      # ... todos los campos                                     │
│  )                                                              │
│                                                                  │
│  # PyAFIPWS construye request interno                           │
└───────────────────────┬─────────────────────────────────────────┘
                        │
┌───────────────────────▼─────────────────────────────────────────┐
│   PyAFIPWS: Agregar IVA y tributos (ws.AgregarIva)              │
│                                                                  │
│  move.pyafipws_add_tax(ws)                                      │
│                                                                  │
│  # IVA por alícuota:                                            │
│  for item in vat_items:                                         │
│      ws.AgregarIva(                                             │
│          id=5,          # Código alícuota (5 = 21%)             │
│          base_imp=1000, # Base imponible                        │
│          importe=210    # Importe IVA                           │
│      )                                                          │
│                                                                  │
│  # Otros tributos (percepciones, IIBB, etc.):                   │
│  for tax in not_vat_taxes:                                      │
│      ws.AgregarTributo(                                         │
│          tributo_id=99,                                         │
│          desc='Percepción IIBB',                                │
│          base_imp=1000,                                         │
│          alic=2.5,                                              │
│          importe=25                                             │
│      )                                                          │
└───────────────────────┬─────────────────────────────────────────┘
                        │
┌───────────────────────▼─────────────────────────────────────────┐
│  PyAFIPWS: Agregar info adicional (opcional)                    │
│                                                                  │
│  move.pyafipws_add_info(ws, afip_ws, invoice_info)              │
│    ↓                                                            │
│  move.wsfe_invoice_add_info(ws, invoice_info)                   │
│                                                                  │
│  # Factura de crédito MiPyME:                                   │
│  if mipyme_fce:                                                 │
│      ws.AgregarOpcional(2101, cbu_cliente)                      │
│      ws.AgregarOpcional(27, transmission_type)                  │
│                                                                  │
│  # Comprobantes asociados (NC/ND):                              │
│  if cbte_asoc:                                                  │
│      ws.AgregarCmpAsoc(                                         │
│          tipo=1,                                                │
│          punto_vta=1,                                           │
│          nro=100,                                               │
│          cuit='20123456789',                                    │
│          fecha='20251201'                                       │
│      )                                                          │
└───────────────────────┬─────────────────────────────────────────┘
                        │
┌───────────────────────▼─────────────────────────────────────────┐
│         PyAFIPWS: Solicitar CAE (ws.CAESolicitar)               │
│                                                                  │
│  move.pyafipws_request_autorization(ws, afip_ws)                │
│    ↓                                                            │
│  move.wsfe_request_autorization(ws)                             │
│    ↓                                                            │
│  ws.CAESolicitar()                                              │
│                                                                  │
│  # PyAFIPWS internamente:                                       │
│  1. Construye XML SOAP request                                  │
│  2. Incluye Token y Sign                                        │
│  3. Envía a WSFE vía HTTPS POST                                 │
│  4. Recibe SOAP response                                        │
│  5. Parsea XML de respuesta                                     │
└───────────────────────┬─────────────────────────────────────────┘
                        │
┌───────────────────────▼─────────────────────────────────────────┐
│             AFIP WSFE: Procesar solicitud                       │
│                                                                  │
│  1. Validar Token y Sign                                        │
│  2. Validar datos de factura:                                   │
│     - CUIT emisor autorizado                                    │
│     - Punto de venta habilitado                                 │
│     - Número correlativo                                        │
│     - Tipo comprobante permitido                                │
│     - Cliente válido                                            │
│     - Importes coherentes (total = neto + IVA + tributos)       │
│     - Fecha dentro de rango permitido                           │
│  3. Si todo OK:                                                 │
│     - Generar CAE (14 dígitos)                                  │
│     - Fecha vencimiento CAE (generalmente hoy + 10 días)        │
│     - Resultado = 'A' (Aceptado)                                │
│  4. Si hay errores:                                             │
│     - Resultado = 'R' (Rechazado)                               │
│     - Código y mensaje de error                                 │
│  5. Si hay observaciones:                                       │
│     - Resultado = 'O' (Observado con CAE)                       │
│     - CAE válido + observaciones                                │
└───────────────────────┬─────────────────────────────────────────┘
                        │
┌───────────────────────▼─────────────────────────────────────────┐
│          PyAFIPWS: Parsear respuesta AFIP                       │
│                                                                  │
│  Respuesta exitosa:                                             │
│    ws.CAE = '72081234567890'  # 14 dígitos                      │
│    ws.Vencimiento = '20260103' # YYYYMMDD                       │
│    ws.Resultado = 'A'                                           │
│    ws.Obs = []                                                  │
│    ws.ErrMsg = None                                             │
│                                                                  │
│  Respuesta con error:                                           │
│    ws.CAE = None                                                │
│    ws.Resultado = 'R'                                           │
│    ws.ErrMsg = 'Número de comprobante no correlativo'           │
│    ws.ErrCode = '10016'                                         │
│                                                                  │
│  XML Request/Response disponibles:                              │
│    ws.XmlRequest                                                │
│    ws.XmlResponse                                               │
└───────────────────────┬─────────────────────────────────────────┘
                        │
┌───────────────────────▼─────────────────────────────────────────┐
│           ODOO: Procesar resultado AFIP                         │
│                                                                  │
│  if ws.Excepcion:                                               │
│      raise UserError(ws.Excepcion)                              │
│                                                                  │
│  result = {                                                     │
│      'afip_auth_code': ws.CAE,                                  │
│      'afip_auth_code_due': datetime.strptime(                   │
│          ws.Vencimiento, '%Y%m%d'                               │
│      ),                                                         │
│      'afip_result': ws.Resultado,  # A/R/O                      │
│      'afip_message': '\n'.join(ws.Obs or []),                   │
│      'afip_xml_request': ws.XmlRequest,                         │
│      'afip_xml_response': ws.XmlResponse,                       │
│  }                                                              │
│                                                                  │
│  move.write(result)                                             │
└───────────────────────┬─────────────────────────────────────────┘
                        │
┌───────────────────────▼─────────────────────────────────────────┐
│            ODOO: Generar código QR (si aplicable)               │
│                                                                  │
│  QR contiene (según RG 4291):                                   │
│    {                                                            │
│      "ver": 1,                                                  │
│      "fecha": "2025-12-24",                                     │
│      "cuit": 20123456789,                                       │
│      "ptoVta": 1,                                               │
│      "tipoCmp": 1,                                              │
│      "nroCmp": 123,                                             │
│      "importe": 1210.00,                                        │
│      "moneda": "PES",                                           │
│      "ctz": 1.000,                                              │
│      "tipoDocRec": 80,                                          │
│      "nroDocRec": 20987654321,                                  │
│      "tipoCodAut": "E",  # E=CAE                                │
│      "codAut": 72081234567890                                   │
│    }                                                            │
│                                                                  │
│  URL base64: https://www.afip.gob.ar/fe/qr/?p={base64(json)}    │
│                                                                  │
│  move.afip_qr_code = qr_url                                     │
└───────────────────────┬─────────────────────────────────────────┘
                        │
┌───────────────────────▼─────────────────────────────────────────┐
│                ODOO: Factura validada y lista                   │
│                                                                  │
│  Estado: draft → posted                                         │
│  Número: 00001-00000123                                         │
│  CAE: 72081234567890                                            │
│  Vencimiento CAE: 2026-01-03                                    │
│  Resultado AFIP: A (Aceptado)                                   │
│                                                                  │
│  El usuario puede:                                              │
│  - Imprimir factura (PDF con CAE y QR)                          │
│  - Enviar por email al cliente                                  │
│  - Registrar pago                                               │
└─────────────────────────────────────────────────────────────────┘
```

### Campos AFIP en AccountMove

**Archivo**: `l10n_ar_afipws_fe/models/account_move.py:340`

```python
class AccountMove(models.Model):
    _inherit = "account.move"

    # Modo de autorización AFIP
    afip_auth_mode = fields.Selection([
        ('CAE', 'CAE - Código de Autorización Electrónico'),
        ('CAI', 'CAI - Código de Autorización por Impresora'),
        ('CAEA', 'CAEA - Código de Autorización Electrónico Anticipado'),
    ], string="AFIP Authorization Mode", copy=False)

    # CAE (14 dígitos)
    afip_auth_code = fields.Char(
        string="CAE/CAI/CAEA Code",
        copy=False,
        help="Código de Autorización Electrónico, Código de Autorización "
             "por Impresora o Código de Autorización Electrónico Anticipado"
    )

    # Fecha de vencimiento del CAE
    afip_auth_code_due = fields.Date(
        string="CAE/CAI/CAEA Due Date",
        copy=False
    )

    # Resultado de AFIP (A/R/O)
    afip_result = fields.Selection([
        ('A', 'Aceptado'),
        ('R', 'Rechazado'),
        ('O', 'Observado'),
    ], string="AFIP Result", copy=False, readonly=True)

    # Mensajes/observaciones de AFIP
    afip_message = fields.Text(
        string="AFIP Message",
        copy=False,
        readonly=True
    )

    # XML Request enviado a AFIP
    afip_xml_request = fields.Text(
        string="AFIP XML Request",
        copy=False,
        readonly=True
    )

    # XML Response recibido de AFIP
    afip_xml_response = fields.Text(
        string="AFIP XML Response",
        copy=False,
        readonly=True
    )

    # Código QR (computado)
    afip_qr_code = fields.Char(
        string="AFIP QR Code",
        compute="_compute_afip_qr_code",
        help="URL del código QR para factura electrónica"
    )

    # Factura de crédito MiPyME
    afip_fce_es_anulacion = fields.Boolean(
        string="FCE es Anulación",
        help="Marca si la factura de crédito es una anulación"
    )

    # Moneda extranjera
    l10n_ar_payment_foreign_currency = fields.Selection([
        ('S', 'Sí'),
        ('N', 'No'),
    ], string="Payment in Foreign Currency")
```

### Ejemplo de XML Request/Response

**XML Request (WSFE CAESolicitar)**:

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<soapenv:Envelope
  xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
  xmlns:ar="http://ar.gov.afip.dif.FEV1/"
>
  <soapenv:Header />
  <soapenv:Body>
    <ar:FECAESolicitar>
      <ar:Auth>
        <ar:Token>PD94bWwgdmVyc2lvbj0iMS4w...</ar:Token>
        <ar:Sign>ef1vYWyQS6Z8SkjB0zb6...</ar:Sign>
        <ar:Cuit>20123456789</ar:Cuit>
      </ar:Auth>
      <ar:FeCAEReq>
        <ar:FeCabReq>
          <ar:CantReg>1</ar:CantReg>
          <ar:PtoVta>1</ar:PtoVta>
          <ar:CbteTipo>1</ar:CbteTipo>
        </ar:FeCabReq>
        <ar:FeDetReq>
          <ar:FECAEDetRequest>
            <ar:Concepto>1</ar:Concepto>
            <ar:DocTipo>80</ar:DocTipo>
            <ar:DocNro>20987654321</ar:DocNro>
            <ar:CbteDesde>123</ar:CbteDesde>
            <ar:CbteHasta>123</ar:CbteHasta>
            <ar:CbteFch>20251224</ar:CbteFch>
            <ar:ImpTotal>1210.00</ar:ImpTotal>
            <ar:ImpTotConc>0.00</ar:ImpTotConc>
            <ar:ImpNeto>1000.00</ar:ImpNeto>
            <ar:ImpOpEx>0.00</ar:ImpOpEx>
            <ar:ImpIVA>210.00</ar:ImpIVA>
            <ar:ImpTrib>0.00</ar:ImpTrib>
            <ar:MonId>PES</ar:MonId>
            <ar:MonCotiz>1.000</ar:MonCotiz>
            <ar:Iva>
              <ar:AlicIva>
                <ar:Id>5</ar:Id>
                <ar:BaseImp>1000.00</ar:BaseImp>
                <ar:Importe>210.00</ar:Importe>
              </ar:AlicIva>
            </ar:Iva>
          </ar:FECAEDetRequest>
        </ar:FeDetReq>
      </ar:FeCAEReq>
    </ar:FECAESolicitar>
  </soapenv:Body>
</soapenv:Envelope>
```

**XML Response (WSFE CAESolicitar)**:

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<soap:Envelope
  xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
  xmlns:ar="http://ar.gov.afip.dif.FEV1/"
>
  <soap:Body>
    <ar:FECAESolicitarResponse>
      <ar:FECAESolicitarResult>
        <ar:FeCabResp>
          <ar:Cuit>20123456789</ar:Cuit>
          <ar:PtoVta>1</ar:PtoVta>
          <ar:CbteTipo>1</ar:CbteTipo>
          <ar:FchProceso>20251224</ar:FchProceso>
          <ar:CantReg>1</ar:CantReg>
          <ar:Resultado>A</ar:Resultado>
        </ar:FeCabResp>
        <ar:FeDetResp>
          <ar:FECAEDetResponse>
            <ar:Concepto>1</ar:Concepto>
            <ar:DocTipo>80</ar:DocTipo>
            <ar:DocNro>20987654321</ar:DocNro>
            <ar:CbteDesde>123</ar:CbteDesde>
            <ar:CbteHasta>123</ar:CbteHasta>
            <ar:CbteFch>20251224</ar:CbteFch>
            <ar:Resultado>A</ar:Resultado>
            <ar:CAE>72081234567890</ar:CAE>
            <ar:CAEFchVto>20260103</ar:CAEFchVto>
          </ar:FECAEDetResponse>
        </ar:FeDetResp>
      </ar:FECAESolicitarResult>
    </ar:FECAESolicitarResponse>
  </soap:Body>
</soap:Envelope>
```

---

## Referencias Técnicas

### Archivos Clave del Proyecto

#### l10n_ar_afipws (Base Webservices)

| Archivo                              | Líneas | Descripción                                  |
| ------------------------------------ | ------ | -------------------------------------------- |
| `models/afipws_connection.py`        | 189    | Gestión de conexiones AFIP                   |
| `models/res_company.py`              | 256    | Autenticación WSAA, búsqueda de certificados |
| `models/afipws_certificate_alias.py` | 199    | Gestión de DN y generación de CSR            |
| `models/afipws_certificate.py`       | 133    | Almacenamiento de certificados X509          |
| `models/res_partner.py`              | 138    | Consulta padrón AFIP                         |
| `models/res_config_settings.py`      | 16     | Configuración de entorno (prod/homo)         |

#### l10n_ar_afipws_fe (Facturación Electrónica)

| Archivo                                   | Líneas | Descripción                          |
| ----------------------------------------- | ------ | ------------------------------------ |
| `models/account_move_ws.py`               | 592    | ⭐ Lógica de integración con WS AFIP |
| `models/account_move.py`                  | 340    | Campos AFIP: CAE, QR, resultados     |
| `models/account_journal_ws.py`            | 196    | Métodos WS específicos de diarios    |
| `models/account_journal.py`               | 92     | Configuración AFIP en diarios        |
| `models/afipws_connection.py`             | 97     | URLs de WS de facturación            |
| `wizard/account_validate_account_move.py` | -      | Wizard de validación                 |

#### Ejemplos AFIP Oficiales (arcaws)

| Archivo                                                                   | Lenguaje   | Descripción                                    |
| ------------------------------------------------------------------------- | ---------- | ---------------------------------------------- |
| `dev-wsaa-cliente-dotnet-vb/source/ClienteLoginCms_VB/ClienteLoginCms.vb` | VB.NET     | Cliente WSAA completo (449 líneas)             |
| `dev-wsaa-cliente-powershell/source/wsaa-cliente.ps1`                     | PowerShell | Cliente WSAA usando OpenSSL (75 líneas)        |
| `claves_privadas/parse_soap_example.py`                                   | Python     | Ejemplo de parseo de XML escapado (152 líneas) |

### URLs de Webservices AFIP

#### Producción

| Servicio                   | URL                                                                  |
| -------------------------- | -------------------------------------------------------------------- |
| WSAA (Autenticación)       | https://wsaa.afip.gov.ar/ws/services/LoginCms?WSDL                   |
| WSFE (Factura Electrónica) | https://servicios1.afip.gov.ar/wsfev1/service.asmx?WSDL              |
| WSMTXCA (Multipropósito)   | https://serviciosjava.afip.gob.ar/wsmtxca/services/MTXCAService?wsdl |
| WSFEX (Exportación)        | https://servicios1.afip.gov.ar/wsfexv1/service.asmx?WSDL             |
| WSFECred (Factura Crédito) | https://serviciosjava.afip.gob.ar/wsfecred/FECredService?wsdl        |
| WS Padrón A5               | https://aws.afip.gov.ar/sr-padron/webservices/personaServiceA5?wsdl  |

#### Homologación

| Servicio                   | URL                                                                     |
| -------------------------- | ----------------------------------------------------------------------- |
| WSAA (Autenticación)       | https://wsaahomo.afip.gov.ar/ws/services/LoginCms?WSDL                  |
| WSFE (Factura Electrónica) | https://wswhomo.afip.gov.ar/wsfev1/service.asmx?WSDL                    |
| WSMTXCA (Multipropósito)   | https://fwshomo.afip.gov.ar/wsmtxca/services/MTXCAService?wsdl          |
| WSFEX (Exportación)        | https://wswhomo.afip.gov.ar/wsfexv1/service.asmx?WSDL                   |
| WSFECred (Factura Crédito) | https://fwshomo.afip.gov.ar/wsfecred/FECredService?wsdl                 |
| WS Padrón A5               | https://awshomo.afip.gov.ar/sr-padron/webservices/personaServiceA5?wsdl |

### Dependencias Python

**Requeridas por l10n_ar_afipws**:

```python
external_dependencies = {
    'python': [
        'pyafipws',       # Biblioteca principal de WS AFIP
        'OpenSSL',        # Manejo de certificados X509
        'pysimplesoap',   # Cliente SOAP usado por pyafipws
    ],
}
```

**Instalación**:

```bash
pip install pyafipws PyOpenSSL pysimplesoap
```

### Códigos AFIP Importantes

#### Tipos de Comprobante (Factura A)

| Código | Descripción                   |
| ------ | ----------------------------- |
| 1      | Factura A                     |
| 2      | Nota de Débito A              |
| 3      | Nota de Crédito A             |
| 6      | Factura B                     |
| 7      | Nota de Débito B              |
| 8      | Nota de Crédito B             |
| 11     | Factura C                     |
| 12     | Nota de Débito C              |
| 13     | Nota de Crédito C             |
| 19     | Factura E (Exportación)       |
| 201    | Factura de Crédito A (MiPyME) |
| 206    | Factura de Crédito B (MiPyME) |
| 211    | Factura de Crédito C (MiPyME) |

#### Tipos de Documento

| Código | Descripción                  |
| ------ | ---------------------------- |
| 80     | CUIT                         |
| 86     | CUIL                         |
| 87     | CDI (Cédula de Identidad)    |
| 89     | LE (Libreta de Enrolamiento) |
| 90     | LC (Libreta Cívica)          |
| 91     | CI Extranjera                |
| 94     | Pasaporte                    |
| 96     | DNI                          |
| 99     | Consumidor Final             |

#### Tipos de Concepto

| Código | Descripción           |
| ------ | --------------------- |
| 1      | Productos             |
| 2      | Servicios             |
| 3      | Productos y Servicios |

#### Alícuotas de IVA

| Código | Alícuota | Descripción |
| ------ | -------- | ----------- |
| 3      | 0%       | No gravado  |
| 4      | 10.5%    | IVA 10.5%   |
| 5      | 21%      | IVA 21%     |
| 6      | 27%      | IVA 27%     |
| 8      | 5%       | IVA 5%      |
| 9      | 2.5%     | IVA 2.5%    |

#### Monedas

| Código | Descripción                        |
| ------ | ---------------------------------- |
| PES    | Peso Argentino                     |
| DOL    | Dólar Estadounidense               |
| 060    | Euro                               |
| 002    | Dólar Estadounidense (alternativo) |

### Documentación Oficial AFIP

**Manuales** (disponibles en `/arcaws/`):

- `WSASS_manual.pdf`: Manual de WSAA (Autenticación y Autorización)
- `wsfev1-RG-4291.pdf`: Manual de WSFE v1 (Resolución General 4291)

**Portales AFIP**:

- Administrador de Relaciones: https://www.afip.gob.ar/
- Portal AFIP Desarrolladores: https://www.afip.gob.ar/ws/
- Consulta de comprobantes: https://www.afip.gob.ar/fe/qr/

### Glosario de Términos

| Término    | Significado                                                                 |
| ---------- | --------------------------------------------------------------------------- |
| **AFIP**   | Administración Federal de Ingresos Públicos                                 |
| **ARCA**   | Agencia de Recaudación y Control Aduanero (nuevo nombre de AFIP desde 2024) |
| **WSAA**   | WebService de Autenticación y Autorización                                  |
| **WSFE**   | WebService de Factura Electrónica                                           |
| **CAE**    | Código de Autorización Electrónico (14 dígitos)                             |
| **CAI**    | Código de Autorización por Impresora                                        |
| **CAEA**   | Código de Autorización Electrónico Anticipado                               |
| **TRA**    | Ticket de Acceso Remoto (XML firmado para WSAA)                             |
| **CMS**    | Cryptographic Message Syntax (PKCS#7)                                       |
| **CSR**    | Certificate Signing Request                                                 |
| **DN**     | Distinguished Name (nombre X.509)                                           |
| **FCE**    | Factura de Crédito Electrónica (MiPyME)                                     |
| **MiPyME** | Micro, Pequeña y Mediana Empresa                                            |
| **CUIT**   | Clave Única de Identificación Tributaria                                    |
| **CUIL**   | Código Único de Identificación Laboral                                      |
| **DNI**    | Documento Nacional de Identidad                                             |
| **IVA**    | Impuesto al Valor Agregado                                                  |
| **IIBB**   | Impuesto sobre los Ingresos Brutos                                          |
| **RG**     | Resolución General (normativa AFIP)                                         |

---

## Conclusiones

### Arquitectura Multicapa Bien Definida

La implementación de webservices AFIP en Odoo sigue una arquitectura de capas claramente
definida:

1. **Capa AFIP**: Webservices SOAP/XML sobre HTTPS
2. **Capa PyAFIPWS**: Wrapper Python que abstrae la complejidad SOAP
3. **Capa Base (l10n_ar_afipws)**: Autenticación, certificados, conexiones
4. **Capa Funcional (l10n_ar_afipws_fe)**: Lógica de facturación electrónica
5. **Capa Aplicación**: POS, Reportes, UX específicas

### Patrones de Diseño Sólidos

- **Strategy**: Diferentes webservices con interfaz común
- **Template Method**: Flujo de facturación estandarizado
- **Factory**: Creación de objetos PyAFIPWS según tipo de WS
- **Singleton**: Caché de conexiones AFIP
- **Chain of Responsibility**: Búsqueda de certificados en múltiples fuentes

### Extensibilidad y Mantenibilidad

- Fácil agregar nuevos webservices sin modificar código existente
- Métodos claramente separados por responsabilidad
- Código bien documentado y estructurado
- Testing independiente por componente

### Seguridad

- Gestión robusta de certificados X.509
- Separación de entornos (producción/homologación)
- Control de acceso granular
- Almacenamiento seguro de credenciales

### Buenas Prácticas Observadas

1. **Herencia sobre composición** para extender modelos Odoo
2. **Delegación dinámica** para soportar múltiples WS
3. **Separación de concerns** (datos vs. lógica WS)
4. **Abstracción de PyAFIPWS** (no acoplar directamente a Odoo)
5. **Logging y debugging** (almacenar XML request/response)

---

**Fin del Documento**

Elaborado por: Claude Sonnet 4.5 Proyecto: do-acsm Versión: 1.0 Fecha: 2025-12-24
