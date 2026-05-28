# Instrucciones de Traducción - Módulo Aeroclub

## ✅ Cambios Completados

### 1. Código fuente traducido al inglés

Todos los archivos han sido traducidos al inglés:

**Archivos Python:**

- `models/flight_type.py` ✅
- `models/flight_booking.py` ✅
- `models/res_partner.py` ✅
- `wizard/flight_booking_complete_wizard.py` ✅

**Archivos XML:**

- `views/flight_booking_views.xml` ✅
- `views/menu_views.xml` ✅
- `wizard/flight_booking_complete_wizard_views.xml` ✅
- `data/flight_type_data.xml` ✅
- `security/security.xml` ✅

### 2. Archivos de traducción creados

**Ubicación:** `odoo/custom/src/private/aeroclub_flight_booking/i18n/`

- ✅ `es.po` - Español (España y general)
- ✅ `es_AR.po` - Español (Argentina)

## 📋 Pasos para Aplicar las Traducciones

### Paso 1: Actualizar el módulo

Si el módulo ya está instalado, necesitas actualizarlo:

```bash
# Opción A: Desde línea de comandos
invoke install -m aeroclub_flight_booking --update

# Opción B: Desde la interfaz de Odoo
# 1. Ir a Aplicaciones
# 2. Buscar "Aeroclub Flight Booking"
# 3. Click en el botón de actualizar (⟳)
```

### Paso 2: Cargar idiomas

Si aún no tienes español instalado en Odoo:

1. Ir a **Configuración > Traducciones > Cargar traducción**
2. Seleccionar idioma: **Spanish / Español**
3. Click en **Cargar**
4. Repetir para **Spanish (Argentina) / Español (AR)** si lo necesitas

### Paso 3: Actualizar traducciones del módulo

Después de instalar los idiomas:

```bash
# Actualizar traducciones desde línea de comandos
docker compose run --rm odoo click-odoo-update -m aeroclub_flight_booking

# O manualmente desde la interfaz:
# 1. Configuración > Traducciones > Actualizar traducciones
# 2. Seleccionar el idioma (es / es_AR)
# 3. Click en Actualizar
```

### Paso 4: Cambiar idioma del usuario

Para ver el módulo en español:

1. Click en tu nombre de usuario (esquina superior derecha)
2. **Preferencias**
3. Cambiar **Idioma** a **Español** o **Español (AR)**
4. **Guardar**
5. Refrescar la página (F5)

## 🔍 Verificación

Después de cambiar el idioma, verifica que las traducciones funcionen:

### Menús (deberían verse en español):

- **Aeroclub** → "Aeroclub"
- **Flights** → "Vuelos"
- **My Flights** → "Mis Vuelos"
- **Configuration** → "Configuración"

### En un formulario de vuelo:

- **Flight Data** → "Datos del Vuelo"
- **Student** → "Alumno"
- **Instructor** → "Instructor"
- **Complete Flight** → "Completar Vuelo"

### Botones:

- **Request Confirmation** → "Solicitar Confirmación"
- **Confirm Flight** → "Confirmar Vuelo"
- **Reject** → "Rechazar"

## 🔧 Solución de Problemas

### Las traducciones no aparecen

**Solución 1:** Actualizar módulo

```bash
invoke install -m aeroclub_flight_booking --update
```

**Solución 2:** Regenerar archivos .po

```bash
# Desde el contenedor de Odoo
docker compose run --rm odoo bash -c "odoo -d devel -u aeroclub_flight_booking --stop-after-init --i18n-export=/opt/odoo/custom/src/private/aeroclub_flight_booking/i18n/es.po --language=es_ES --modules=aeroclub_flight_booking"
```

**Solución 3:** Verificar que el idioma esté instalado

1. Ir a **Configuración > Traducciones > Idiomas**
2. Verificar que "Español" esté activo
3. Si no está, activarlo

### Algunas cadenas siguen en inglés

Esto puede pasar si:

1. La cadena no tiene `translate=True` en el campo (solo afecta a campos `Char` y
   `Text`)
2. La cadena está hardcodeada sin la función `_()`
3. El cache no se refrescó

**Solución:**

```bash
# Limpiar cache y reiniciar
invoke restart
```

## 📝 Agregar Nuevas Traducciones

Si necesitas traducir nuevos textos en el futuro:

### 1. En código Python:

```python
from odoo import _

# Envolver el texto con _()
raise UserError(_('This text will be translatable'))
```

### 2. En archivos XML:

Los textos en XML se traducen automáticamente si están en:

- Atributos `string=`
- Contenido de tags `<field name="name">`
- Placeholders

### 3. Actualizar archivos .po:

```bash
# Exportar traducciones actualizadas
docker compose run --rm odoo bash -c "odoo -d devel --stop-after-init --i18n-export=/tmp/es.po --language=es_ES --modules=aeroclub_flight_booking"

# Copiar el archivo actualizado
docker compose cp odoo:/tmp/es.po odoo/custom/src/private/aeroclub_flight_booking/i18n/es.po
```

### 4. Editar manualmente los .po:

Puedes editar los archivos .po directamente con cualquier editor de texto o usar
herramientas especializadas como:

- **Poedit** (GUI para editar .po files)
- **Lokalize** (KDE)
- Cualquier editor de texto

Formato:

```po
#: archivo.py:123
msgid "English text"
msgstr "Texto en español"
```

## 🌍 Diferencias entre es.po y es_AR.po

Actualmente ambos archivos son idénticos. Puedes personalizarlos si hay términos
específicos de Argentina:

**Ejemplos de diferencias regionales:**

| Término   | España (es) | Argentina (es_AR) |
| --------- | ----------- | ----------------- |
| Ordenador | Ordenador   | Computadora       |
| Móvil     | Móvil       | Celular           |
| Coche     | Coche       | Auto              |

Para este módulo de aeroclub, los términos técnicos son universales, por lo que no hay
diferencias significativas.

## 📚 Recursos

- **Documentación de Odoo sobre traducciones**:
  https://www.odoo.com/documentation/18.0/developer/reference/backend/translations.html
- **Formato .po (gettext)**:
  https://www.gnu.org/software/gettext/manual/html_node/PO-Files.html
- **Poedit (editor de traducciones)**: https://poedit.net/

## ✨ Resultado Final

Con estas traducciones, el módulo:

- ✅ Está en **inglés por defecto** (buenas prácticas)
- ✅ Se **traduce automáticamente** al español cuando el usuario cambia el idioma
- ✅ Soporta **español general (es)** y **español de Argentina (es_AR)**
- ✅ Todas las cadenas están traducidas (campos, botones, menús, mensajes de error,
  etc.)

---

**Nota:** Recuerda que después de modificar archivos .po, siempre debes actualizar el
módulo para que los cambios se apliquen.
