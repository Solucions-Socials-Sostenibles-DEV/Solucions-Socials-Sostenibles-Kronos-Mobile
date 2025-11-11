# 📱 SSS Kronos Mobile

Aplicación móvil Flutter para la gestión de **Hojas de Ruta** del sistema SSS Kronos.

## 🎯 Descripción

Esta aplicación permite gestionar hojas de ruta desde dispositivos móviles (iOS/Android), con sincronización en tiempo real con la aplicación Desktop mediante Supabase.

## 🔗 Repositorios Relacionados

- **[Desktop App](../KRONOS%20DESKTOP/Solucions-Socials-Sostenibles-Kronos)** - Aplicación Electron/React

## 🏗️ Arquitectura

- **Frontend**: Flutter (Dart)
- **Backend**: Supabase (PostgreSQL + Auth + Storage)
- **Base de Datos**: Compartida con Desktop App

Ver [ARCHITECTURE.md](docs/ARCHITECTURE.md) para más detalles.

## 🚀 Inicio Rápido

### Prerrequisitos

- Flutter SDK 3.35+ (Dart 3.9+)
- Cuenta de Supabase configurada
- Xcode (iOS) / Android SDK (Android)

### Instalación

```bash
# Clonar repositorio
git clone <repo-url> SSS-Kronos-Mobile
cd SSS-Kronos-Mobile/solucions_socials_kronos_mobile

# Instalar dependencias
flutter pub get

# Configurar Supabase
# Opción A (archivo): edita lib/config/supabase_config.dart con tu URL y anon key
# Opción B (flags): pásalos por línea de comandos con --dart-define

# Ejecutar
flutter run
```

Ver [SETUP.md](docs/SETUP.md) para instrucciones detalladas.

## 📚 Documentación

- [ARCHITECTURE.md](docs/ARCHITECTURE.md) - Arquitectura y diseño del sistema
- [SETUP.md](docs/SETUP.md) - Guía de instalación y configuración
- [MIGRATION_GUIDE.md](docs/MIGRATION_GUIDE.md) - Mapeo Desktop → Mobile

## ✨ Funcionalidades

- ✅ Autenticación Supabase (email + contraseña)
- ✅ Pantalla “Hoja de Ruta” con acciones principales
- ✅ Navegación inferior (Hoja de Ruta / Ajustes)
- ✅ Ajustes
  - Modo oscuro
  - Configuración de divisas (EUR/USD/GBP/JPY/CHF/CAD/AUD)
  - Estado de conexiones (Supabase, Holded Solucions, Holded Menjador)
  - Datos de la aplicación (versión, contacto)
  - Verificar actualización en GitHub y abrir releases
- ✅ Gestión de Hojas de Ruta (UI base – acciones)
- ✅ Checklist interactivo
- ✅ Gestión de personal
- ✅ Firma digital
- ✅ Sincronización en tiempo real con Desktop
- ✅ Soporte offline (próximamente)

## 🛠️ Desarrollo

### Estructura del Proyecto

```
lib/
├── config/          # Configuración (Supabase, Holded, GitHub)
│   ├── supabase_config.dart
│   └── external_services_config.dart
├── models/          # Modelos de datos
├── services/        # Servicios (lógica de negocio, Holded)
│   ├── auth_service.dart
│   ├── holded_client.dart
│   └── holded_service.dart
├── screens/         # Pantallas (Login, Ruta, Ajustes, Onboarding)
│   ├── auth/login_screen.dart
│   ├── ruta/ruta_screen.dart
│   ├── settings/settings_screen.dart
│   └── onboarding/onboarding_screen.dart
├── widgets/         # Widgets reutilizables
├── theme/           # Control de tema (ThemeController)
└── utils/           # Utilidades

assets/
├── images/
└── icons/
```

### Comandos Útiles

```bash
# Desarrollo
flutter run

# Tests
flutter test

# Build
flutter build apk        # Android
flutter build ios        # iOS
```

## 📋 Estado del Proyecto

### Fase Actual: UI base + Integraciones

- [x] Repositorio creado
- [x] Scripts SQL copiados
- [x] Documentación inicial
- [x] Configuración de Supabase (inicialización en app)
- [x] Login + AuthGate + Onboarding
- [x] Pantallas base (Hoja de Ruta, Ajustes)
- [x] Bottom navigation
- [x] Estado de conexiones (Supabase + Holded)
- [x] Verificación de actualización vía GitHub
- [ ] Servicios de negocio (datos reales Hoja de Ruta)
- [ ] Integración completa con Supabase/Reactividad en pantallas

Ver [ARCHITECTURE.md](docs/ARCHITECTURE.md) para el plan completo.

## 🔐 Seguridad

- Las credenciales de Supabase NO deben committearse
- Usar variables de entorno en producción
- Verificar políticas RLS en Supabase
- Las claves de Holded deberían guardarse de forma segura (storage seguro / backend),
  no en el cliente en producción. En desarrollo puedes usar `lib/config/external_services_config.dart`
  o `--dart-define`.

## ⚙️ Configuración rápida (opcional – sin editar código)

```bash
# Supabase
flutter run \
  --dart-define=SUPABASE_URL=https://<tu-proyecto>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<tu_anon_key>

# GitHub releases (para Verificar actualización)
flutter run \
  --dart-define=GITHUB_REPO_OWNER=<owner> \
  --dart-define=GITHUB_REPO_NAME=<repo>

# Holded (comprobación de estado / llamadas)
flutter run \
  --dart-define=HOLDED_API_KEY_SOLUCIONS=<key_solucions> \
  --dart-define=HOLDED_API_KEY_MENJAR=<key_menjar>
```

## 📝 Licencia

MIT

## 👥 Contribuidores

- Desarrollo: Marc Fernández Messa
- Desktop App: Brian Bautista

---

**Versión**: 0.1.0 (Desarrollo inicial)
**Última actualización**: 2025-11-11

