# 🚀 Setup - SSS Kronos Mobile

## Prerrequisitos

- Flutter SDK instalado (versión 3.0 o superior)
- Dart SDK (incluido con Flutter)
- Android Studio / Xcode (para desarrollo móvil)
- Cuenta de Supabase con proyecto configurado

## Instalación Inicial

### 1. Clonar/Verificar Repositorio

```bash
cd "C:\Users\marca\OneDrive\Documentos\Code\SolucionsSocials\Kronos_Mobile"
```

### 2. Crear Proyecto Flutter (si aún no existe)

```bash
flutter create .
```

### 3. Instalar Dependencias

```bash
flutter pub get
```

## Configuración de Supabase

### 1. Obtener Credenciales

Las credenciales están en el proyecto Desktop:
- Archivo: `../KRONOS DESKTOP/Solucions-Socials-Sostenibles-Kronos/src/config/supabase.js`

### 2. Crear Archivo de Configuración

Crear `lib/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String url = 'https://zalnsacawwekmibhoiba.supabase.co';
  static const String anonKey = 'TU_ANON_KEY_AQUI';
  
  // IMPORTANTE: No committear keys directamente
  // Usar variables de entorno en producción
}
```

### 3. Inicializar Supabase

En `lib/main.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  
  runApp(MyApp());
}
```

## Estructura de Base de Datos

### Ejecutar Scripts SQL

Los scripts SQL ya están copiados en `database/`:
- `create_hojas_ruta_tables.sql`
- `rls_policies_hojas_ruta_FIXED.sql`

**Ejecutar en Supabase Dashboard > SQL Editor** si aún no están ejecutados.

## Verificar Conexión

### Test de Conexión

Crear un archivo de prueba `lib/test_connection.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> testConnection() async {
  try {
    final response = await Supabase.instance.client
        .from('hojas_ruta')
        .select('count')
        .count();
    
    print('✅ Conexión exitosa. Hojas de ruta: $response');
  } catch (e) {
    print('❌ Error de conexión: $e');
  }
}
```

## Estructura de Carpetas Recomendada

```
lib/
├── main.dart
├── config/
│   └── supabase_config.dart
├── models/
│   ├── hoja_ruta.dart
│   ├── checklist_item.dart
│   ├── personal.dart
│   └── ...
├── services/
│   └── hoja_ruta_service.dart
├── screens/
│   ├── auth/
│   │   └── login_screen.dart
│   └── hoja_ruta/
│       ├── hoja_ruta_list_screen.dart
│       ├── hoja_ruta_detail_screen.dart
│       └── checklist_screen.dart
├── widgets/
│   ├── checklist_item_widget.dart
│   └── personal_card_widget.dart
└── utils/
    └── date_formatter.dart
```

## Comandos Útiles

### Desarrollo

```bash
# Ejecutar en modo debug
flutter run

# Ejecutar en dispositivo específico
flutter run -d <device-id>

# Ver dispositivos disponibles
flutter devices

# Hot reload (presionar 'r' en la terminal)
# Hot restart (presionar 'R' en la terminal)
```

### Build

```bash
# Build APK para Android
flutter build apk

# Build para iOS
flutter build ios

# Build AppBundle para Play Store
flutter build appbundle
```

### Testing

```bash
# Ejecutar tests
flutter test

# Coverage
flutter test --coverage
```

## Variables de Entorno

### Desarrollo Local

Crear `.env` (añadir a `.gitignore`):

```
SUPABASE_URL=https://zalnsacawwekmibhoiba.supabase.co
SUPABASE_ANON_KEY=tu_key_aqui
```

Usar `flutter_dotenv` para cargar:

```yaml
dependencies:
  flutter_dotenv: ^5.0.0
```

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

await dotenv.load(fileName: ".env");
final url = dotenv.env['SUPABASE_URL'];
```

## Troubleshooting

### Error: "Supabase not initialized"

Asegúrate de llamar `Supabase.initialize()` antes de usar el cliente.

### Error: "RLS policy violation"

Verifica que:
1. El usuario esté autenticado
2. Las políticas RLS estén ejecutadas en Supabase
3. El usuario tenga los permisos correctos

### Error: "Connection refused"

Verifica:
1. Las credenciales de Supabase
2. La conexión a internet
3. Que el proyecto Supabase esté activo

## Próximos Pasos

1. ✅ Setup básico completado
2. ⏭️ Crear modelos de datos
3. ⏭️ Implementar HojaRutaService
4. ⏭️ Crear pantallas principales

Ver `ARCHITECTURE.md` para más detalles sobre la implementación.

---

**Nota**: Este documento se actualiza conforme avanza el desarrollo.

