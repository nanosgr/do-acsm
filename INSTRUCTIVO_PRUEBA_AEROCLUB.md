# Instructivo de Prueba - Módulo Aeroclub Flight Booking

Este documento describe cómo configurar y probar el módulo de gestión de vuelos de
instrucción desde cero.

## Estado del Desarrollo

✅ **Completado:**

- Repositorios OCA agregados (calendar, sale-workflow, timesheet, server-ux)
- Módulo custom `aeroclub_flight_booking` creado en `odoo/custom/src/private/`
- Modelos, vistas, seguridad y workflows implementados
- Integración con módulos OCA base

## Pre-requisitos

1. **Base de datos limpia:** El entorno está reseteado con solo `base` y `web`
2. **Odoo corriendo:** Verificar con `invoke logs` o `docker-compose ps`
3. **Acceso al sistema:** http://localhost:18069

## Estado Actual del Sistema

- **Database:** `devel` (limpia, solo base + web)
- **Usuario Admin:** admin / admin
- **Módulos instalados:** base, web
- **Módulos por instalar:** resource_booking, sale_resource_booking,
  aeroclub_flight_booking

## Paso 1: Verificar Estado Inicial

Antes de comenzar, verificar que Odoo esté corriendo:

```bash
# Ver estado de los contenedores
docker-compose ps

# Ver logs en tiempo real (Ctrl+C para salir)
invoke logs

# O ver las últimas líneas
docker-compose logs --tail=50 odoo
```

Debería mostrar que Odoo está escuchando en el puerto 8069.

## Paso 2: Acceso Inicial a Odoo

1. Abrir navegador en: **http://localhost:18069**
2. Iniciar sesión:
   - **Usuario:** admin
   - **Password:** admin
3. Verificar que estás en la base de datos `devel`

## Paso 3: Instalar Módulos Base

Necesitamos instalar módulos estándar y OCA antes del módulo custom.

### 3.1. Módulos Estándar de Odoo

```bash
# Instalar módulos core necesarios
invoke install -m sale_management,contacts,fleet
```

**Módulos instalados:**

- `sale_management`: Gestión de ventas y órdenes
- `contacts`: Gestión de contactos/clientes
- `fleet`: Gestión de vehículos (aeronaves)

Esperar a que termine la instalación (ver logs con `invoke logs`).

### 3.2. Módulos OCA (Resource Booking)

```bash
# Instalar módulos OCA de reservas
invoke install -m resource_booking,sale_resource_booking
```

**Módulos instalados:**

- `resource_booking`: Sistema base de reservas de recursos
- `sale_resource_booking`: Integración de reservas con ventas

### 3.3. Verificar Instalación en UI

1. En Odoo, ir a **Aplicaciones** (menú principal)
2. Quitar filtro "Apps" para ver todos los módulos
3. Buscar "Resource Booking" - debería aparecer como **Instalado**
4. Buscar "Sales" - debería aparecer como **Instalado**

## Paso 4: Instalar Módulo Custom Aeroclub

### 4.1. Verificar que el módulo esté disponible

```bash
# Listar módulos en private
ls -la odoo/custom/src/private/aeroclub_flight_booking/

# Verificar el symlink en auto/addons
ls -la odoo/auto/addons/ | grep aeroclub
```

Deberías ver el symlink:
`aeroclub_flight_booking -> ../../custom/src/private/aeroclub_flight_booking`

Si no existe el symlink, reiniciar Odoo:

```bash
invoke restart
```

### 4.2. Instalar el módulo

```bash
invoke install -m aeroclub_flight_booking
```

Esperar a que termine la instalación (ver logs).

### 4.3. Verificar en UI

1. En Odoo, ir a **Aplicaciones**
2. Actualizar lista: botón "Update Apps List" (si aparece)
3. Buscar "Aeroclub"
4. Debería aparecer instalado
5. **Verificar que aparezca el menú "Aeroclub"** en el menú principal (junto a Sales,
   Contacts, etc.)

## Paso 5: Configuración Inicial (Datos Maestros)

### 5.1. Configurar Productos para Facturación

Los vuelos necesitan productos para generar órdenes de venta:

1. Ir a **Sales > Products > Products**
2. Click **Create**
3. Crear producto 1:

   - **Product Name:** Hora de Instrucción de Vuelo (Avión)
   - **Can be Sold:** ✅ Sí
   - **Product Type:** Service
   - **Invoicing Policy:** Delivered quantities
   - **Unit of Measure:** Unit (se facturará por horas)
   - **Sales Price:** 15000.00 (ejemplo: AR$ 15,000 por hora)
   - **Save**

4. Click **Create** nuevamente
5. Crear producto 2:
   - **Product Name:** Remolque de Planeador
   - **Can be Sold:** ✅ Sí
   - **Product Type:** Service
   - **Invoicing Policy:** Delivered quantities
   - **Unit of Measure:** Units
   - **Sales Price:** 8000.00 (ejemplo: AR$ 8,000 por remolque)
   - **Save**

### 5.2. Configurar Tipos de Instrucción (Instruction Types)

El módulo viene con 2 tipos preconfigurados, solo hay que asignar productos:

1. Ir a **Aeroclub > Configuration > Instruction Types**

   > **Nota:** Se accede desde el menú del módulo custom `aeroclub_flight_booking`, NO
   > desde "Resource Booking" de OCA.

2. Abrir **Airplane Instruction**:

   - **Name:** Airplane Instruction
   - **Code:** AIRPLANE (único, para identificación interna)
   - **Billing Unit:** Hour (factura por horas de vuelo)
   - **Product:** Seleccionar "Hora de Instrucción de Vuelo (Avión)"
   - **Unit Price:** Se autocompleta desde el producto
   - **Active:** ✅
   - **Save**

3. Abrir **Glider Instruction**:
   - **Name:** Glider Instruction
   - **Code:** GLIDER
   - **Billing Unit:** Tow (factura por remolques realizados)
   - **Product:** Seleccionar "Remolque de Planeador"
   - **Unit Price:** Se autocompleta desde el producto
   - **Active:** ✅
   - **Save**

**Campos importantes:**

- **Code:** Identificador único del tipo (usado internamente)
- **Billing Unit:** Define cómo se factura (Hour/Tow)
- **Product:** Producto que se usará en las órdenes de venta
- **Unit Price:** Precio por unidad (hora o remolque)

### 5.3. Configurar Instructores

Vamos a crear un instructor de prueba con usuario:

1. Ir a **Contacts > Contacts**
2. Click **Create**
3. Completar datos:

   - **Name:** Juan Pérez
   - **Company Type:** Individual
   - **Phone:** +54 11 1234-5678
   - **Email:** instructor@test.com
   - **Is Instructor:** ✅ Sí
   - **Instructor License Number:** INS-001
   - **Specialties:** Airplane, Glider (seleccionar ambos)
   - **Save**

4. Crear usuario de Odoo para el instructor:

   - En el formulario del contacto, tab **Settings**
   - Click **Grant portal access** o **Create User**
   - **Login:** instructor
   - **Password:** instructor (temporal)
   - **Access Rights:**
     - Sales: User: Own Documents Only
     - **Aeroclub: Instructor** ✅
   - **Save User**

5. Para crear más instructores, repetir el proceso

### 5.4. Configurar Alumnos

Vamos a crear un alumno de prueba con usuario:

1. Ir a **Contacts > Contacts**
2. Click **Create**
3. Completar datos:

   - **Name:** María García
   - **Company Type:** Individual
   - **Phone:** +54 11 8765-4321
   - **Email:** alumno@test.com
   - **Is Student:** ✅ Sí
   - **Student License Number:** ALU-001
   - **Student Level:** Beginner
   - **Save**

4. Crear usuario de Odoo para el alumno:

   - Tab **Settings**
   - Click **Grant portal access** o **Create User**
   - **Login:** alumno
   - **Password:** alumno (temporal)
   - **Access Rights:**
     - Sales: User: Own Documents Only
     - **Aeroclub: Student** ✅
   - **Save User**

5. Para crear más alumnos, repetir el proceso

### 5.5. Configurar Aeronaves (Fleet)

El módulo aeroclub usa el módulo Fleet de Odoo para gestionar aeronaves:

1. Ir a **Fleet > Configuration > Vehicle Model**
2. Click **Create** para crear modelo de avión:

   - **Model name:** Cessna 152
   - **Brand:** Create nuevo "Cessna"
   - **Vehicle Type:** Car (o crear "Aircraft")
   - **Save**

3. Click **Create** para crear modelo de planeador:

   - **Model name:** ASK-21
   - **Brand:** Create nuevo "Schleicher"
   - **Vehicle Type:** Car (o "Glider")
   - **Save**

4. Ir a **Fleet > Fleet**
5. Click **Create** para agregar avión:

   - **Vehicle:** Cessna 152 (seleccionar del dropdown)
   - **Driver:** Dejar vacío (son aeronaves del club)
   - **License Plate:** LV-ABC (matrícula argentina)
   - **Model:** Cessna 152
   - **Save**

6. Click **Create** para agregar planeador:
   - **Vehicle:** ASK-21
   - **License Plate:** LV-XYZ
   - **Model:** ASK-21
   - **Save**

### 5.6. ~~Configurar Booking Types~~ (NO NECESARIO)

**IMPORTANTE:** Esta sección está obsoleta. El módulo `aeroclub_flight_booking` **NO
utiliza** los "Booking Types" del módulo `resource_booking` de OCA.

**¿Qué usa en su lugar?**

- El módulo tiene su propio modelo: **`aeroclub.flight.type`** (Instruction Types)
- Ya configurado en la sección 5.2 anterior
- Ubicación: **Aeroclub > Configuration > Instruction Types**

**¿Por qué no se usan Booking Types de OCA?** El módulo aeroclub implementa una
arquitectura híbrida:

- Gestiona directamente los vehículos (módulo `fleet` de Odoo)
- Gestiona directamente los instructores (modelo `res.partner`)
- No usa el sistema `resource.resource` ni `resource.booking.combination` de
  `resource_booking`
- Define sus propios tipos de instrucción con lógica de facturación específica (por hora
  o por remolque)

**✓ Ya está configurado:** Si completaste la sección 5.2, puedes continuar con el
Paso 6.

## Paso 6: Flujo de Prueba Completo

### Escenario: Ciclo completo de un vuelo de instrucción

#### 6.1. Como Alumno - Solicitar Vuelo

1. **Cerrar sesión** del usuario admin (menú arriba derecha > Log out)
2. **Iniciar sesión** con:

   - User: `alumno`
   - Password: `alumno`

3. Ir a menú **Aeroclub > Flights > My Flights**
4. Click **Create** (botón New)
5. Completar formulario de solicitud:

   - **Name:** Vuelo de prueba 1 (o dejar que se autocomplete)
   - **Partner:** Debería autocompletar con "María García"
   - **Flight Type:** Seleccionar "Airplane Instruction"
   - **Instructor:** Seleccionar "Juan Pérez"
   - **Vehicle:** Seleccionar "Cessna 152 - LV-ABC"
   - **Start:** Seleccionar fecha y hora (ej: mañana a las 10:00)
   - **Duration:** 1.0 (1 hora)
   - **Notes:** "Primera clase de vuelo"

6. Click **Save** (disquete arriba)
7. Verificar que el estado sea "Draft"
8. Click botón **Request Instructor Confirmation**
9. Verificar que:
   - Estado cambió a "Pending Instructor Confirmation"
   - Aparecen botones: Cancel, Schedule (deshabilitados todavía)
   - Se creó una actividad para el instructor

#### 6.2. Como Instructor - Confirmar Vuelo

1. **Cerrar sesión** del alumno (Log out)
2. **Iniciar sesión** con:

   - User: `instructor`
   - Password: `instructor`

3. Ver las actividades pendientes:

   - Click en el **ícono de reloj** (Activities) arriba derecha
   - Debería aparecer: "Confirm flight instruction for María García"
   - O ir a **Aeroclub > Flights > Assigned Flights**

4. Click en el vuelo pendiente para abrirlo
5. Verificar información:

   - Partner: María García
   - Flight Type: Airplane Instruction
   - Instructor: Juan Pérez (yo)
   - Estado: Pending Instructor Confirmation

6. Opciones de botones disponibles:

   - ✅ **Confirm Flight** - Acepto dar la instrucción
   - ❌ **Reject Flight** - No puedo/quiero dar esta instrucción
   - 🔄 **Request Reassignment** - Pido que asignen otro instructor

7. Click botón **Confirm Flight**
8. Verificar que:
   - Estado cambió a "Instructor Confirmed"
   - Ahora está disponible el botón **Schedule**

#### 6.3. Agendar el Vuelo en Calendario

1. En el mismo vuelo (como instructor), click botón **Schedule**
2. Se abre el calendario de resource_booking
3. Seleccionar un slot disponible (click en una celda del calendario)
4. Confirmar la fecha/hora
5. Se crea una "meeting" (reunión calendario)
6. Verificar que:
   - Estado cambió a "Scheduled"
   - Aparece el campo "Meeting" con link a la reunión de calendario
   - Botón **Complete Flight** ahora está disponible

#### 6.4. Después del Vuelo - Completar y Registrar Datos Reales

**Simular que ya se realizó el vuelo (saltar al día siguiente virtualmente):**

1. Como instructor, mantener abierto el vuelo
2. Click botón **Complete Flight**
3. Se abre un wizard (ventana emergente)
4. Completar datos reales del vuelo:

   **Para vuelo de Avión:**

   - **Actual Duration (hours):** 1.2 (ejemplo: voló 1 hora 12 minutos)
   - **Notes:** "Buen desempeño, practicó aterrizajes y despegues"

   **Para vuelo de Planeador (si fuera el caso):**

   - **Number of Tows:** 2 (cantidad de remolques realizados)
   - **Notes:** "Practicó virajes y pérdida"

5. Click **Confirm** en el wizard
6. Verificar que:
   - Estado cambió a "Completed"
   - Campo "Actual Duration" muestra 1.2
   - Las notas se guardaron
   - Botón **Generate Sale Order** ahora está disponible

#### 6.5. Como Manager - Generar Facturación

1. **Cerrar sesión** del instructor
2. **Iniciar sesión** como admin:

   - User: `admin`
   - Password: `admin`

3. Ir a **Aeroclub > Flights > All Flights**
4. Buscar y abrir el vuelo completado (filtrar por estado "Completed")
5. Verificar datos:

   - Estado: Completed
   - Actual Duration: 1.2 hours
   - Flight Type: Airplane Instruction
   - Instructor: Juan Pérez
   - Partner: María García

6. Click botón **Generate Sale Order**
7. Se crea automáticamente una Sale Order:

   - Se abre el formulario de la orden
   - **Customer:** María García
   - **Order Lines:**
     - Product: Hora de Instrucción de Vuelo (Avión)
     - Quantity: 1.2 (horas reales)
     - Unit Price: 15,000.00
     - Subtotal: 18,000.00
   - Estado: Quotation

8. Click botón **Confirm** para confirmar la orden
9. Estado cambia a "Sales Order"
10. Click botón **Create Invoice**
11. Crear factura según flujo normal de Odoo

12. Volver al vuelo (menú breadcrumb o **Aeroclub > Flights**)
13. Verificar que:
    - Estado cambió a "Invoiced"
    - Campo "Sale Order" muestra link a la orden creada
    - Ya no se puede modificar el vuelo

## Paso 7: Verificaciones de Seguridad y Permisos

### 7.1. Verificar Permisos del Alumno

1. Iniciar sesión como `alumno`
2. Ir a **Aeroclub > Flights**
3. Verificar que:
   - ✅ Solo ve "My Flights" (no ve "All Flights")
   - ✅ Solo aparece su propio vuelo creado
   - ✅ Puede crear nuevos vuelos
   - ❌ NO puede ver vuelos de otros alumnos
   - ❌ NO puede acceder a Configuration

### 7.2. Verificar Permisos del Instructor

1. Iniciar sesión como `instructor`
2. Ir a **Aeroclub > Flights**
3. Verificar que:
   - ✅ Ve "My Flights" y "Assigned Flights"
   - ✅ Ve todos los vuelos donde es instructor
   - ✅ Puede confirmar/rechazar vuelos
   - ✅ Puede completar vuelos
   - ❌ NO puede generar Sale Orders (solo manager)
   - ❌ NO ve vuelos de otros instructores (a menos que sea manager también)

### 7.3. Verificar Permisos del Manager

1. Iniciar sesión como `admin`
2. Ir a **Aeroclub > Flights**
3. Verificar que:
   - ✅ Ve "All Flights"
   - ✅ Ve TODOS los vuelos del sistema
   - ✅ Puede generar Sale Orders
   - ✅ Accede a Configuration
   - ✅ Puede modificar Instruction Types, ver estadísticas, etc.

### 7.4. Verificar Estadísticas en Contacto de Alumno

1. Como admin, ir a **Contacts**
2. Abrir contacto "María García"
3. Verificar que existe pestaña/notebook **Aeroclub**
4. Ver información:
   - **Total Completed Flights:** 1
   - **Total Flight Hours:** 1.2
   - Botón **View Flights** que abre lista de todos sus vuelos
   - Lista de vuelos recientes (si hay widget/tree)

### 7.5. Verificar Estadísticas en Contacto de Instructor

1. Ir a contacto "Juan Pérez"
2. Pestaña **Aeroclub**
3. Ver:
   - **Total Flights Instructed:** 1
   - **Total Instruction Hours:** 1.2
   - Lista de vuelos donde fue instructor

## Paso 8: Pruebas Adicionales

### 8.1. Probar Rechazo de Vuelo

1. Como alumno, crear otro vuelo de instrucción
2. Solicitar confirmación
3. Como instructor, abrir el vuelo
4. Click **Reject Flight**
5. Verificar que estado cambia a "Rejected"
6. Verificar que ya no se puede modificar

### 8.2. Probar Reasignación de Instructor

1. Crear un segundo instructor (seguir pasos de 5.3)
2. Como alumno, crear vuelo asignado al primer instructor
3. Solicitar confirmación
4. Como primer instructor, click **Request Reassignment**
5. Como manager, abrir el vuelo
6. Cambiar campo "Instructor" al segundo instructor
7. Verificar que el segundo instructor recibe la notificación

### 8.3. Probar Vuelo de Planeador

1. Como alumno, crear vuelo con:
   - Flight Type: Glider Instruction
   - Vehicle: ASK-21 (planeador)
2. Seguir flujo completo
3. Al completar, ingresar "Number of Tows" en lugar de hours
4. Verificar que la Sale Order se genera con cantidad = número de remolques

### 8.4. Probar Cancelación

1. Crear un vuelo en estado "Scheduled"
2. Click botón **Cancel**
3. Verificar que:
   - No se puede volver a activar
   - No se puede completar
   - No se genera Sale Order

## Paso 9: Resetear para Nueva Prueba

Si necesitas empezar de cero:

```bash
# Opción 1: Resetear solo la base de datos
invoke resetdb -m base,web,sale_management,contacts,fleet,resource_booking,sale_resource_booking,aeroclub_flight_booking

# Opción 2: Resetear todo (más limpio)
invoke stop
invoke resetdb -m base,web
invoke start
# Luego seguir desde Paso 3
```

## Problemas Conocidos y Soluciones

### Error: Assets JavaScript corruptos

**Síntomas:** Consola del navegador muestra errores de archivos .js faltantes

**Solución:**

```bash
invoke stop
rm -rf odoo/auto/addons/.web_*/
invoke resetdb -m base,web
invoke start
```

### Error: Módulo no aparece en lista

**Solución:**

```bash
invoke restart
# En Odoo UI: Apps > Update Apps List
```

### Error: "Field X does not exist"

**Causa:** Módulos dependientes no instalados en orden correcto

**Solución:**

```bash
# Instalar en este orden específico:
invoke install -m sale_management
invoke install -m contacts
invoke install -m fleet
invoke install -m resource_booking
invoke install -m sale_resource_booking
invoke install -m aeroclub_flight_booking
```

### Error: "Access Denied" al crear vuelo

**Causa:** Usuario no tiene grupo correcto asignado

**Solución:**

1. Como admin, ir a Settings > Users & Companies > Users
2. Editar usuario del alumno/instructor
3. Verificar que tenga grupo "Aeroclub / Student" o "Aeroclub / Instructor"
4. Usuario debe **cerrar sesión y volver a iniciar** para que apliquen los cambios

### Error: No se puede generar Sale Order

**Causa:** Falta producto configurado en Instruction Type

**Solución:**

1. Ir a Aeroclub > Configuration > Instruction Types
2. Editar el tipo de instrucción
3. Asignar un producto válido
4. Guardar

### Error: Permisos no se actualizan

**Causa:** Caché de grupos/permisos no refrescado

**Solución:** El usuario afectado debe:

1. Cerrar sesión (Log out)
2. Cerrar navegador completamente
3. Abrir navegador nuevamente
4. Iniciar sesión

O como admin, actualizar el módulo:

```bash
docker-compose run --rm odoo odoo -d devel -u aeroclub_flight_booking --stop-after-init
invoke restart
```

## Estructura del Módulo

```
aeroclub_flight_booking/
├── __init__.py
├── __manifest__.py
├── README.md
├── models/
│   ├── __init__.py
│   ├── flight_booking.py      # Extiende resource.booking
│   ├── flight_type.py          # Tipos de instrucción
│   └── res_partner.py          # Extensión de contactos
├── views/
│   ├── flight_booking_views.xml
│   └── menu_views.xml
├── wizard/
│   ├── __init__.py
│   ├── flight_booking_complete_wizard.py
│   └── flight_booking_complete_wizard_views.xml
├── security/
│   ├── security.xml            # Grupos y reglas
│   └── ir.model.access.csv     # Permisos de modelos
├── data/
│   └── flight_type_data.xml    # Tipos por defecto
└── static/
    └── description/
```

## Resumen Rápido (Quick Start)

Para desarrolladores que ya conocen el sistema:

```bash
# 1. Limpiar y resetear
invoke stop
rm -rf odoo/auto/addons/.web_*/
invoke resetdb -m base,web
invoke start

# 2. Instalar dependencias
invoke install -m sale_management,contacts,fleet
invoke install -m resource_booking,sale_resource_booking

# 3. Instalar módulo custom
invoke install -m aeroclub_flight_booking

# 4. Acceder a UI
# http://localhost:18069
# admin / admin

# 5. Configurar datos maestros (ver Paso 5)
# 6. Probar flujo completo (ver Paso 6)
```

## Checklist de Configuración Mínima

- [ ] Productos creados (Hora de Instrucción, Remolque)
- [ ] Instruction Types configurados con productos (Aeroclub > Configuration >
      Instruction Types)
- [ ] Al menos 1 instructor con usuario y grupo
- [ ] Al menos 1 alumno con usuario y grupo
- [ ] Al menos 1 aeronave (avión o planeador) en Fleet

## Comandos Útiles

```bash
# Ver logs en tiempo real
invoke logs

# Reiniciar Odoo
invoke restart

# Actualizar módulo después de cambios en código
docker-compose run --rm odoo odoo -d devel -u aeroclub_flight_booking --stop-after-init
invoke restart

# Instalar módulo con tests
invoke test -m aeroclub_flight_booking

# Ver estado de contenedores
docker-compose ps

# Acceder a shell de Odoo
docker-compose run --rm odoo odoo shell -d devel

# Acceder a PostgreSQL
docker-compose exec db psql -U odoo devel
```

## Estructura del Módulo (Referencia)

```
aeroclub_flight_booking/
├── __init__.py
├── __manifest__.py                          # Dependencias y metadatos
├── README.md
├── models/
│   ├── __init__.py
│   ├── flight_booking.py                   # Modelo principal (extiende resource.booking)
│   ├── flight_type.py                      # Tipos de instrucción (avión/planeador)
│   └── res_partner.py                      # Extensión de contactos (instructores/alumnos)
├── views/
│   ├── flight_booking_views.xml            # Vistas de formulario, lista, calendario
│   ├── flight_type_views.xml               # Vistas de configuración de tipos
│   ├── res_partner_views.xml               # Vistas de instructores/alumnos
│   └── menu_views.xml                      # Menús y acciones
├── wizard/
│   ├── __init__.py
│   ├── flight_booking_complete_wizard.py   # Wizard para completar vuelo
│   └── flight_booking_complete_wizard_views.xml
├── security/
│   ├── security.xml                        # Grupos (Student, Instructor, Manager)
│   └── ir.model.access.csv                 # Permisos de lectura/escritura por modelo
├── data/
│   └── flight_type_data.xml                # Datos iniciales (tipos de vuelo)
└── static/
    └── description/
        ├── icon.png
        └── index.html
```

## Próximos Desarrollos

Las siguientes funcionalidades están planificadas pero NO implementadas aún:

- [ ] Gestión de combustible y tanques
- [ ] Facturación automática de almacenamiento de combustible
- [ ] Cuotas sociales de socios
- [ ] Mantenimiento preventivo de aeronaves
- [ ] Reportes estadísticos (horas por alumno, por instructor, por aeronave)
- [ ] Dashboard de actividad del aeroclub
- [ ] Portal web mejorado para alumnos (auto-booking)
- [ ] Integración con `base_tier_validation` para aprobaciones complejas
- [ ] Sistema de reserva de hangar
- [ ] Control de pagos y morosos

## Referencias y Documentación

- **Doodba Framework:** https://github.com/Tecnativa/doodba
- **OCA Calendar (resource_booking):** https://github.com/OCA/calendar
- **OCA Sale Workflow:** https://github.com/OCA/sale-workflow
- **Odoo 18 Documentation:** https://www.odoo.com/documentation/18.0/
- **Invoke Tasks:** Ver `tasks.py` en raíz del proyecto

## Soporte

Para consultas, problemas o reportar bugs:

- **Email:** gestion@aeroclubsanmartin.com.ar
- **Logs del sistema:** `invoke logs`
- **Documentación del proyecto:** Ver `CLAUDE.md` y `README.md`

---

**Versión:** 18.0.1.0.0 **Fecha última actualización:** 2026-02-02 **Odoo Version:**
18.0 **Licencia:** AGPL-3 **Autor:** Aero Club San Martín (Argentina) **URL
Producción:** http://gestion.aeroclubsanmartin.com.ar
