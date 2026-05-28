# Cambios - Integración con Fleet para Aeronaves

## Resumen

Se modificó el módulo `aeroclub_flight_booking` para integrar aeronaves como vehículos
usando el módulo Fleet de Odoo. Esta es una solución temporal que facilita la gestión
básica de aeronaves mientras se planifica la implementación completa del sistema de
Mantenimiento.

## Cambios Realizados

### 1. Dependencias (`__manifest__.py`)

Se agregó `fleet` a las dependencias del módulo:

```python
'depends': [
    'base',
    'fleet',  # ← NUEVO
    'resource_booking',
    'sale_resource_booking',
    'sale_management',
    'base_tier_validation',
    'hr_timesheet_begin_end',
],
```

### 2. Modelo (`models/flight_booking.py`)

Se agregó el campo `vehicle_id` para vincular reservas de vuelo con aeronaves:

```python
# Vehicle (Aircraft) integration
vehicle_id = fields.Many2one(
    comodel_name='fleet.vehicle',
    string='Aircraft',
    required=True,
    tracking=True,
    help='Aircraft assigned for this flight',
)
```

**Características:**

- Campo obligatorio (`required=True`)
- Con seguimiento de cambios (`tracking=True`)
- Vincula directamente a `fleet.vehicle`

### 3. Vistas (`views/flight_booking_views.xml`)

#### Vista de Formulario

- Se agregó el campo `vehicle_id` después del campo `type_id`
- Aparece antes del tipo de instrucción para mejor flujo visual

#### Vista de Lista/Tree

- Se agregó `vehicle_id` como campo opcional mostrado por defecto
- Permite ver rápidamente qué aeronave está asignada a cada vuelo

#### Vista de Calendario

- Se agregó `vehicle_id` para mostrar la aeronave en eventos del calendario
- Útil para ver disponibilidad de aeronaves por fecha

#### Vista de Kanban

- Se agregó `vehicle_id` en los campos disponibles
- Se muestra en el cuerpo de la tarjeta con ícono de avión
- Orden de presentación en la tarjeta:
  1. Alumno (student)
  2. **Aeronave (vehicle)** ← NUEVO
  3. Instructor
  4. Tipo de vuelo
  5. Hora de inicio

## Cómo Usar

### Actualizar el Módulo

```bash
docker-compose run --rm odoo odoo -d devel -u aeroclub_flight_booking --stop-after-init
```

### Crear Aeronaves en Fleet

Antes de poder crear reservas de vuelo, necesitas crear vehículos en el módulo Fleet:

1. Ir a **Fleet > Fleet > Vehicles**
2. Crear un nuevo vehículo
3. Campos importantes:
   - **License Plate**: Matrícula de la aeronave (ej: LV-XXX)
   - **Model**: Modelo de aeronave (crear primero en Fleet > Configuration > Models)
   - **Driver**: Puede dejarse vacío inicialmente

### Crear una Reserva de Vuelo

1. Ir a **Aeroclub > Flights > All Flights**
2. Crear nueva reserva
3. Ahora verás el campo **Aircraft** que es obligatorio
4. Seleccionar la aeronave del listado de vehículos
5. Completar los demás campos (instructor, tipo de instrucción, etc.)

## Próximos Pasos

### Paso 1: Agregar Tipo de Aeronave (Inmediato)

Después de probar esta integración básica, se agregará un campo personalizado a
`fleet.vehicle` para distinguir tipos de aeronave:

```python
aircraft_type = fields.Selection([
    ('airplane', 'Airplane'),
    ('glider', 'Glider'),
], string='Aircraft Type')
```

Esto permitirá:

- Filtrar aeronaves por tipo en las reservas
- Asociar automáticamente el tipo de instrucción según la aeronave
- Generar reportes separados por tipo de aeronave

### Paso 2: Validaciones y Dominios

Una vez agregado el tipo de aeronave, se pueden implementar validaciones:

```python
# En flight_booking.py
@api.onchange('vehicle_id')
def _onchange_vehicle_id(self):
    if self.vehicle_id:
        # Sugerir tipo de instrucción según tipo de aeronave
        if self.vehicle_id.aircraft_type == 'glider':
            self.flight_type_id = self.env.ref('aeroclub_flight_booking.flight_type_glider')
        elif self.vehicle_id.aircraft_type == 'airplane':
            self.flight_type_id = self.env.ref('aeroclub_flight_booking.flight_type_airplane')

# Agregar dominio en el campo vehicle_id
vehicle_id = fields.Many2one(
    comodel_name='fleet.vehicle',
    string='Aircraft',
    required=True,
    domain="[('aircraft_type', 'in', ['airplane', 'glider'])]",
    tracking=True,
)
```

### Paso 3: Módulos OCA Fleet Recomendados

Basado en el análisis en `ANALISIS_OCA_FLEET_MAINTENANCE.md`, considerar instalar:

**Corto plazo (con Fleet):**

1. `fleet_vehicle_category` - Categorías de aeronaves
2. `fleet_vehicle_ownership` - Propiedad de aeronaves (club vs socios)
3. `fleet_vehicle_inspection` - Inspecciones pre/post vuelo
4. `fleet_vehicle_service_kanban` - Gestión visual de mantenimiento
5. `fleet_vehicle_log_fuel` - Registro de combustible (solo aviones)

**Mediano plazo:** Evaluar migración a `maintenance` module con:

- `maintenance_equipment_usage` - Horas de vuelo
- `maintenance_plan` - Inspecciones programadas (50hr, 100hr, anual)
- `maintenance_equipment_status` - Estado de aeronavegabilidad
- `maintenance_stock` - Partes y consumibles

### Paso 4: Integración Completa con Maintenance

Ver documento `ANALISIS_OCA_FLEET_MAINTENANCE.md` sección 7 para roadmap completo de 12
semanas.

## Ventajas de esta Integración Temporal

### Ventajas Inmediatas:

1. ✅ **Gestión centralizada de aeronaves**: Todas en Fleet module
2. ✅ **Datos estructurados**: Modelo, año, características, fotos
3. ✅ **Tracking básico**: Historial de asignaciones
4. ✅ **Extensibilidad**: Fácil agregar campos personalizados
5. ✅ **Preparación para Maintenance**: Base sólida para futura migración

### Limitaciones Actuales:

- ❌ No hay tracking automático de horas de vuelo
- ❌ No hay gestión de mantenimiento preventivo
- ❌ No hay control de aeronavegabilidad
- ❌ No hay gestión de partes/consumibles

Estas limitaciones se resolverán en fases posteriores con módulos de Maintenance.

## Diferencias con Enfoque Anterior

### Antes (resource.booking puro):

```
Reserva → resource.resource (genérico)
```

- Recursos genéricos sin características específicas
- Sin datos estructurados de aeronaves
- Sin posibilidad de tracking de mantenimiento

### Ahora (con Fleet):

```
Reserva → fleet.vehicle (aeronave específica)
```

- Vehículos con datos completos (modelo, año, matrícula, etc.)
- Base para agregar tracking de horas de vuelo
- Preparado para integración con mantenimiento
- Posibilidad de gestionar contratos, seguros, etc.

### Futuro (con Maintenance):

```
Reserva → fleet.vehicle → maintenance.equipment
```

- Todo lo anterior +
- Tracking de horas de vuelo/ciclos
- Mantenimiento preventivo automático
- Gestión de partes y consumibles
- Estado de aeronavegabilidad
- Compliance regulatorio

## Estructura de Datos Recomendada en Fleet

### Modelos de Aeronave (fleet.vehicle.model)

**Ejemplos:**

- Cessna 172
- Piper PA-28
- Grob G103 Twin Astir (planeador)
- ASK 21 (planeador)

**Datos a completar por modelo:**

- Categoría: Avión / Planeador
- Fabricante (Brand): Cessna, Piper, Grob, etc.
- Configuración de asientos: 2, 4, etc.

### Vehículos Individuales (fleet.vehicle)

**Ejemplo para avión:**

- **License Plate**: LV-ABC
- **Model**: Cessna 172
- **Model Year**: 1980
- **Acquisition Date**: Fecha de compra/incorporación
- **Driver**: Puede dejarse vacío (se usa instructor_id en booking)

**Ejemplo para planeador:**

- **License Plate**: LV-XYZ
- **Model**: ASK 21
- **Model Year**: 1995
- **Driver**: Vacío

## Testing

### Verificar la Instalación

1. **Verificar dependencia de Fleet**:

   ```bash
   docker-compose run --rm odoo odoo shell -d devel
   >>> self.env['ir.module.module'].search([('name', '=', 'fleet')]).state
   # Debe retornar: 'installed'
   ```

2. **Crear aeronave de prueba**:

   - Fleet > Vehicles > Create
   - License Plate: LV-TEST
   - Model: Crear un modelo de prueba

3. **Crear reserva de vuelo**:

   - Aeroclub > Flights > Create
   - Verificar que campo Aircraft sea obligatorio
   - Seleccionar LV-TEST
   - Completar y guardar

4. **Verificar vistas**:
   - Lista: Ver que muestre columna Aircraft
   - Kanban: Ver tarjeta con ícono de avión + nombre de aeronave
   - Calendario: Ver evento con información de aeronave
   - Formulario: Ver campo Aircraft antes de Instruction Type

## Traducción

El campo `Aircraft` se traduce automáticamente a `Aeronave` en español mediante los
archivos:

- `i18n/es.po`
- `i18n/es_AR.po`

Si es necesario actualizar traducciones después de cambios:

```bash
# Exportar traducciones actualizadas
docker-compose run --rm odoo odoo -d devel --stop-after-init \
  --i18n-export=/tmp/es.po --language=es_ES --modules=aeroclub_flight_booking

# Copiar archivo actualizado
docker-compose cp odoo:/tmp/es.po \
  odoo/custom/src/private/aeroclub_flight_booking/i18n/es.po
```

## Notas Técnicas

### Por qué Fleet y no Maintenance directamente?

Como se explica en `ANALISIS_OCA_FLEET_MAINTENANCE.md`, el módulo Maintenance es
superior para aeronaves, pero:

1. **Fleet es más simple** para empezar: Interfaz familiar, menos configuración inicial
2. **Permite validar el flujo**: Probar la gestión de aeronaves antes de complejidad de
   maintenance
3. **Migración factible**: Datos de fleet.vehicle se pueden migrar a
   maintenance.equipment
4. **Aprendizaje progresivo**: Equipo se familiariza gradualmente con gestión de activos

### Campos de resource.booking que se mantienen

El módulo sigue heredando de `resource.booking`, por lo que mantiene:

- `resource_id`: Campo original (podría ocultarse en vistas si no se usa)
- `start`, `stop`: Fechas de inicio y fin
- `duration`: Duración en horas
- `state`: Estado de la reserva (draft, confirmed, canceled)
- `partner_id`: Participantes (alumnos)

### Campos nuevos específicos de vuelos

Agregados por `aeroclub_flight_booking`:

- `vehicle_id`: **NUEVO** - Aeronave asignada
- `flight_type_id`: Tipo de instrucción (avión/planeador)
- `instructor_id`: Instructor asignado
- `instructor_state`: Estado de confirmación del instructor
- `flight_completed`: Indica si el vuelo se completó
- `actual_duration`: Duración real para facturación
- `tow_count`: Cantidad de remolques (planeadores)
- `sale_order_id`: Orden de venta generada

## Conclusión

Esta integración con Fleet proporciona una base sólida para la gestión de aeronaves
mientras se planifica la implementación completa con módulos de Maintenance. Los
próximos pasos son:

1. ✅ **COMPLETADO**: Integración básica con Fleet
2. ⏭️ **SIGUIENTE**: Agregar campo `aircraft_type` a fleet.vehicle
3. ⏭️ **SIGUIENTE**: Implementar validaciones y filtros
4. ⏭️ **FUTURO**: Evaluar módulos OCA Fleet adicionales
5. ⏭️ **FUTURO**: Planificar migración a Maintenance module

Para más detalles sobre el análisis completo de módulos Fleet y Maintenance, ver:

- `ANALISIS_OCA_FLEET_MAINTENANCE.md`

---

**Fecha**: 2026-01-30 **Versión del módulo**: 18.0.1.0.0 **Estado**: Integración básica
completada, pendiente agregar tipo de aeronave
