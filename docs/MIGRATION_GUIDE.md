# 📋 Guía de Migración: Desktop → Mobile

Este documento mapea las funcionalidades del Desktop (JavaScript/React) a su equivalente en Mobile (Dart/Flutter).

## 🔄 Mapeo de Servicios

### hojaRutaSupabaseService.js → HojaRutaService (Dart)

| JavaScript (Desktop) | Dart (Mobile) | Estado |
|---------------------|---------------|--------|
| `getHojasRuta()` | `Future<List<HojaRuta>> getHojasRuta()` | ⏳ Pendiente |
| `getHojaRuta(id)` | `Future<HojaRuta?> getHojaRuta(String id)` | ⏳ Pendiente |
| `getUltimaHojaRuta()` | `Future<HojaRuta?> getUltimaHojaRuta()` | ⏳ Pendiente |
| `getHistorico()` | `Future<List<HojaRuta>> getHistorico()` | ⏳ Pendiente |
| `createHojaRuta(data, userId)` | `Future<HojaRuta> createHojaRuta(...)` | ⏳ Pendiente |
| `updateHojaRuta(id, updates)` | `Future<HojaRuta> updateHojaRuta(...)` | ⏳ Pendiente |
| `deleteHojaRuta(id)` | `Future<void> deleteHojaRuta(String id)` | ⏳ Pendiente |
| `firmarHojaRuta(id, firmaData, firmadoPor)` | `Future<HojaRuta> firmarHojaRuta(...)` | ⏳ Pendiente |
| `actualizarTareaChecklist(...)` | `Future<void> actualizarTareaChecklist(...)` | ⏳ Pendiente |
| `cambiarEstadoServicio(id, estado)` | `Future<void> cambiarEstadoServicio(...)` | ⏳ Pendiente |
| `obtenerEstadisticasChecklist(id)` | `Future<Map<String, dynamic>> obtenerEstadisticasChecklist(...)` | ⏳ Pendiente |
| `actualizarHorasPersonal(id, horas)` | `Future<void> actualizarHorasPersonal(...)` | ⏳ Pendiente |

## 📱 Mapeo de Componentes

### React Components → Flutter Screens/Widgets

| React Component | Flutter Equivalent | Notas |
|----------------|-------------------|-------|
| `HojaRutaPage` | `HojaRutaDetailScreen` | Pantalla principal |
| `HojaRutaListScreen` | Nueva pantalla | Lista de hojas |
| `ChecklistSection` | `ChecklistScreen` | Vista de checklist |
| `PersonalSection` | `PersonalScreen` | Gestión de personal |
| `HojaRutaUploadModal` | `UploadScreen` (opcional) | Subida de archivos |
| `HojaRutaEditModal` | `EditHojaRutaScreen` | Edición |
| `FirmaConfirmModal` | `FirmaScreen` | Firma digital |
| `HojaRutaViewModal` | Parte de `HojaRutaDetailScreen` | Vista detallada |

## 🔧 Mapeo de Funcionalidades

### Autenticación

**Desktop:**
```javascript
// src/components/AuthContext.jsx
import { supabase } from '../config/supabase';
```

**Mobile:**
```dart
// lib/services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;
```

### Consultas a Supabase

**Desktop:**
```javascript
const { data, error } = await supabase
  .from('hojas_ruta')
  .select('*')
  .eq('id', id)
  .single();
```

**Mobile:**
```dart
final response = await supabase
    .from('hojas_ruta')
    .select()
    .eq('id', id)
    .single()
    .execute();

if (response.error != null) {
  throw Exception(response.error!.message);
}
final data = response.data;
```

### Estado del Servicio

**Desktop:**
```javascript
const estados = {
  'preparacion': 'Preparación',
  'en_camino': 'En Camino',
  'montaje': 'Montaje',
  'servicio': 'Servicio',
  'recogida': 'Recogida',
  'completado': 'Completado'
};
```

**Mobile:**
```dart
enum EstadoServicio {
  preparacion('Preparación'),
  enCamino('En Camino'),
  montaje('Montaje'),
  servicio('Servicio'),
  recogida('Recogida'),
  completado('Completado');
  
  final String label;
  const EstadoServicio(this.label);
}
```

### Checklist - Estructura

**Desktop:**
```javascript
checklist: {
  general: {
    preEvento: [...],
    duranteEvento: [...],
    postEvento: [...]
  },
  equipamiento: [...],
  menus: [...],
  bebidas: [...]
}
```

**Mobile:**
```dart
class Checklist {
  final Map<String, List<ChecklistItem>> general;
  final List<ChecklistItem> equipamiento;
  final List<ChecklistItem> menus;
  final List<ChecklistItem> bebidas;
}
```

## 🎨 Mapeo de UI/UX

### Temas y Colores

**Desktop:**
- Usa `ThemeContext` con colores dinámicos
- Soporte para tema claro/oscuro

**Mobile:**
- Usar `ThemeData` de Flutter
- `ThemeMode.system` para seguir preferencias del sistema

### Animaciones

**Desktop:**
- `framer-motion` para animaciones

**Mobile:**
- `AnimatedContainer`, `Hero`, `PageRouteBuilder`
- O usar `flutter_animate` para animaciones más complejas

### Iconos

**Desktop:**
- `lucide-react`

**Mobile:**
- `lucide_flutter` (mismo set de iconos)
- O `flutter_svg` para iconos personalizados

## 📊 Estructura de Datos

### Modelo HojaRuta

**Desktop (JavaScript):**
```javascript
{
  id: string,
  fechaServicio: string,
  cliente: string,
  contacto: string,
  direccion: string,
  transportista: string,
  responsable: string,
  numPersonas: number,
  estado: string,
  firmaInfo: {
    firmado: boolean,
    firmadoPor: string,
    fechaFirma: string
  },
  horarios: {
    montaje: string,
    welcome: string,
    desayuno: string,
    comida: string,
    recogida: string
  },
  personal: [...],
  checklist: {...},
  equipamiento: [...],
  menus: [...],
  bebidas: [...]
}
```

**Mobile (Dart):**
```dart
class HojaRuta {
  final String id;
  final DateTime fechaServicio;
  final String cliente;
  final String? contacto;
  final String? direccion;
  final String? transportista;
  final String? responsable;
  final int numPersonas;
  final EstadoServicio estado;
  final FirmaInfo? firmaInfo;
  final Horarios horarios;
  final List<Personal> personal;
  final Checklist checklist;
  final List<Equipamiento> equipamiento;
  final List<Menu> menus;
  final List<Bebida> bebidas;
  
  // fromJson, toJson methods
}
```

## 🔐 Permisos y Roles

**Desktop:**
```javascript
const isJefe = ['jefe', 'admin', 'administrador'].includes(user.role?.toLowerCase());
```

**Mobile:**
```dart
bool get isJefe {
  final role = user?.role?.toLowerCase();
  return ['jefe', 'admin', 'administrador'].contains(role);
}
```

## 📝 Notas de Implementación

### Diferencias Clave

1. **Tipado**: Dart es fuertemente tipado, JavaScript no
2. **Null Safety**: Dart tiene null safety nativo
3. **Async/Await**: Similar sintaxis, pero manejo de errores diferente
4. **State Management**: Flutter usa Provider/Riverpod, React usa hooks/context

### Mejores Prácticas

1. **Modelos**: Crear clases Dart con `fromJson`/`toJson`
2. **Servicios**: Separar lógica de negocio en servicios
3. **Widgets**: Componentes reutilizables como widgets
4. **Error Handling**: Usar `try-catch` y `Result` types

## ✅ Checklist de Migración

- [ ] Configurar Supabase en Flutter
- [ ] Crear modelos de datos (HojaRuta, ChecklistItem, etc.)
- [ ] Implementar HojaRutaService
- [ ] Crear pantallas principales
- [ ] Implementar autenticación
- [ ] Implementar checklist
- [ ] Implementar gestión de personal
- [ ] Implementar firma digital
- [ ] Testing
- [ ] Preparar para release

---

**Última actualización**: 2025-11-06

