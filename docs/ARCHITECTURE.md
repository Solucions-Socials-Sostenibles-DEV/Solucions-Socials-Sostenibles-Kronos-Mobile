# 🏗️ Arquitectura - SSS Kronos Mobile

## 📋 Contexto del Proyecto

Este proyecto es la aplicación móvil Flutter para la gestión de **Hojas de Ruta** del sistema SSS Kronos. Se desarrolla como un repositorio separado del proyecto Desktop (Electron/React) pero comparte la misma base de datos y backend (Supabase).

## 🔗 Repositorios Relacionados

- **Desktop App**: `Solucions-Socials-Sostenibles-Kronos` (Electron/React)
- **Mobile App**: `Kronos_Mobile` (Flutter) - Este repositorio

## 🎯 Objetivo

Desarrollar una aplicación móvil multiplataforma (iOS/Android) que permita:
- ✅ Gestionar Hojas de Ruta desde dispositivos móviles
- ✅ Actualizar checklist en tiempo real
- ✅ Ver y editar información de personal
- ✅ Firmar hojas de ruta digitalmente
- ✅ Sincronización automática con la aplicación Desktop

## 🏛️ Arquitectura

### Backend Compartido

```
┌─────────────────┐         ┌─────────────────┐
│  Desktop App    │         │   Mobile App     │
│  (Electron)     │         │   (Flutter)      │
└────────┬────────┘         └────────┬────────┘
         │                            │
         └────────────┬───────────────┘
                      │
              ┌───────▼────────┐
              │    Supabase     │
              │  (PostgreSQL)   │
              └─────────────────┘
```

### Stack Tecnológico

- **Frontend**: Flutter (Dart)
- **Backend**: Supabase (PostgreSQL + Auth + Storage)
- **Autenticación**: Supabase Auth (compartida con Desktop)
- **Base de Datos**: PostgreSQL en Supabase (compartida)

## 📊 Estructura de Base de Datos

### Tablas Principales

#### `hojas_ruta`
Tabla principal que almacena la información básica de cada hoja de ruta.

**Campos clave:**
- `id` (UUID)
- `fecha_servicio` (DATE)
- `cliente` (TEXT)
- `contacto` (TEXT)
- `direccion` (TEXT)
- `transportista` (TEXT)
- `responsable` (TEXT)
- `num_personas` (INTEGER)
- `estado` (TEXT) - valores: 'preparacion', 'en_camino', 'montaje', 'servicio', 'recogida', 'completado'
- `firma_info` (JSONB) - información de firma digital
- `horarios` (JSONB) - horarios del servicio
- `notas` (TEXT[])
- `created_by` (UUID) - referencia a user_profiles

#### `hojas_ruta_personal`
Asignación de personal y horas trabajadas.

**Campos clave:**
- `id` (UUID)
- `hoja_ruta_id` (UUID) - FK a hojas_ruta
- `nombre` (TEXT)
- `horas` (DECIMAL)
- `empleado_id` (TEXT) - ID de Holded (opcional)

#### `hojas_ruta_checklist`
Tareas del checklist organizadas por tipo y fase.

**Campos clave:**
- `id` (UUID)
- `hoja_ruta_id` (UUID) - FK a hojas_ruta
- `tipo` (TEXT) - 'general', 'equipamiento', 'menus', 'bebidas'
- `fase` (TEXT) - 'preEvento', 'duranteEvento', 'postEvento' (solo para tipo 'general')
- `tarea_id` (TEXT)
- `task` (TEXT)
- `completed` (BOOLEAN)
- `assigned_to` (TEXT)
- `priority` (TEXT) - 'alta', 'media', 'baja'

#### `hojas_ruta_equipamiento`
Items de equipamiento requeridos.

#### `hojas_ruta_menus`
Menús y sus items.

#### `hojas_ruta_bebidas`
Bebidas requeridas.

### Scripts SQL

Los scripts de creación de tablas están en:
- `database/create_hojas_ruta_tables.sql`
- `database/rls_policies_hojas_ruta_FIXED.sql`

## 🔧 Servicios a Implementar

### HojaRutaService (Dart)

Equivalente a `hojaRutaSupabaseService.js` del proyecto Desktop.

**Métodos principales a implementar:**

```dart
class HojaRutaService {
  // Obtener todas las hojas de ruta
  Future<List<HojaRuta>> getHojasRuta();
  
  // Obtener una hoja de ruta por ID
  Future<HojaRuta?> getHojaRuta(String id);
  
  // Obtener la última hoja de ruta
  Future<HojaRuta?> getUltimaHojaRuta();
  
  // Obtener histórico
  Future<List<HojaRuta>> getHistorico();
  
  // Actualizar tarea del checklist
  Future<void> actualizarTareaChecklist(
    String hojaId,
    String tipo,
    String? fase,
    String tareaId,
    bool completed,
    String assignedTo,
  );
  
  // Cambiar estado del servicio
  Future<void> cambiarEstadoServicio(
    String hojaId,
    String nuevoEstado,
  );
  
  // Firmar hoja de ruta
  Future<HojaRuta> firmarHojaRuta(
    String hojaId,
    Map<String, dynamic> firmaData,
    String firmadoPor,
  );
  
  // Obtener estadísticas del checklist
  Future<Map<String, dynamic>> obtenerEstadisticasChecklist(String hojaId);
  
  // Actualizar horas de personal
  Future<void> actualizarHorasPersonal(
    String hojaId,
    List<Map<String, dynamic>> horasPersonal,
  );
}
```

## 📱 Estructura de Pantallas

### Pantallas Principales

1. **LoginScreen**
   - Autenticación con Supabase Auth
   - Mismo sistema de usuarios que Desktop

2. **HojaRutaListScreen**
   - Lista de todas las hojas de ruta
   - Filtros por fecha, estado, cliente
   - Búsqueda

3. **HojaRutaDetailScreen**
   - Vista detallada de una hoja de ruta
   - Información general (cliente, fecha, dirección, etc.)
   - Secciones:
     - Información básica
     - Personal asignado
     - Checklist
     - Horarios
     - Equipamiento
     - Menús
     - Bebidas

4. **ChecklistScreen**
   - Vista enfocada en el checklist
   - Tabs por tipo: General, Equipamiento, Menús, Bebidas
   - Sub-tabs para General: Pre-Evento, Durante Evento, Post-Evento
   - Toggle de tareas
   - Asignación de responsables

5. **PersonalScreen**
   - Gestión de personal asignado
   - Edición de horas (solo para roles: jefe/admin/administrador)

6. **FirmaScreen**
   - Captura de firma digital
   - Confirmación antes de firmar

## 🔐 Autenticación y Permisos

### Roles de Usuario

- **admin/administrador/jefe**: Acceso completo, pueden editar horas
- **user**: Acceso limitado, no pueden editar horas

### Row Level Security (RLS)

Las políticas RLS están configuradas en Supabase:
- Usuarios autenticados pueden ver todas las hojas de ruta
- Solo el creador o admin puede actualizar
- Solo admin puede eliminar

## 🔄 Sincronización en Tiempo Real

### Supabase Realtime

Usar Supabase Realtime para actualizaciones instantáneas:

```dart
// Escuchar cambios en checklist
supabase
  .from('hojas_ruta_checklist')
  .stream(primaryKey: ['id'])
  .eq('hoja_ruta_id', hojaId)
  .listen((data) {
    // Actualizar UI automáticamente
  });
```

## 📦 Dependencias Principales

```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.0.0
  provider: ^6.0.0  # State management
  intl: ^0.18.0      # Formateo de fechas
  signature: ^5.0.0  # Firma digital
  file_picker: ^6.0.0 # Selección de archivos (si se implementa subida)
```

## 🎨 Diseño y UI

### Principios de Diseño

- **Consistencia**: Mantener coherencia visual con Desktop cuando sea posible
- **Mobile-first**: Optimizado para pantallas táctiles
- **Offline-first**: Considerar modo offline con sincronización posterior
- **Feedback visual**: Indicadores claros de estado y acciones

### Temas

- Soporte para tema claro/oscuro
- Colores consistentes con la marca

## 🚀 Plan de Implementación

### Fase 1: Setup y Autenticación (Semana 1)
- [x] Crear repositorio
- [x] Copiar scripts SQL
- [ ] Configurar Supabase Flutter SDK
- [ ] Implementar LoginScreen
- [ ] Configurar autenticación

### Fase 2: Funcionalidades Core (Semanas 2-3)
- [ ] Crear modelos de datos (HojaRuta, ChecklistItem, etc.)
- [ ] Implementar HojaRutaService
- [ ] Crear HojaRutaListScreen
- [ ] Crear HojaRutaDetailScreen
- [ ] Implementar actualización de checklist

### Fase 3: Funcionalidades Avanzadas (Semanas 4-5)
- [ ] Implementar ChecklistScreen completo
- [ ] Gestión de personal
- [ ] Firma digital
- [ ] Realtime updates

### Fase 4: Optimización y Testing (Semana 6)
- [ ] Modo offline
- [ ] Optimización de rendimiento
- [ ] Testing
- [ ] Preparación para release

## 📝 Notas de Desarrollo

### Referencias del Código Desktop

El código de referencia está en:
- `src/services/hojaRutaSupabaseService.js` - Lógica de servicios
- `src/components/HojaRutaPage.jsx` - Componente principal
- `src/components/ChecklistSection.jsx` - Lógica de checklist
- `src/components/PersonalSection.jsx` - Gestión de personal

### Configuración de Supabase

Las credenciales de Supabase están en:
- Desktop: `src/config/supabase.js`
- Mobile: Crear `lib/config/supabase_config.dart` con las mismas credenciales

**IMPORTANTE**: No committear las keys directamente. Usar variables de entorno.

## 🔍 Decisiones de Arquitectura

### ¿Por qué Flutter?

- Multiplataforma (iOS + Android con un solo código)
- Buen rendimiento nativo
- SDK oficial de Supabase
- Buen ecosistema y comunidad

### ¿Por qué repositorio separado?

- Separación clara de tecnologías
- CI/CD independiente
- Mejor organización
- Evita conflictos de herramientas

### ¿Por qué compartir Supabase?

- Misma base de datos = sincronización automática
- Misma autenticación = usuarios compartidos
- No necesitas backend adicional
- RLS ya configurado

## 📚 Recursos

- [Supabase Flutter Documentation](https://supabase.com/docs/reference/dart/introduction)
- [Flutter Documentation](https://docs.flutter.dev/)
- [Desktop App Repository](../KRONOS%20DESKTOP/Solucions-Socials-Sostenibles-Kronos)

---

**Última actualización**: 2025-11-06
**Contexto de conversación**: Chat de Cursor sobre arquitectura y setup inicial

