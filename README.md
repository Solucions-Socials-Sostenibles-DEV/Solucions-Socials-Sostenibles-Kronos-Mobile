# 📱 SSS Kronos Mobile

Aplicación móvil Flutter para la gestión de **Hojas de Ruta** del sistema SSS Kronos.

## 🎯 Descripción

Aplicación Flutter (iOS/Android) para consultar y operar con las Hojas de Ruta, sincronizada en tiempo real con la app Desktop (Supabase).

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
# Opción A (archivo ejemplo): copia lib/config/supabase_config.example.dart a supabase_config.dart y rellena
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
- ✅ Onboarding para nuevos usuarios
  - Tutorial multi‑paso y confirmación final guardando `onboarding_completed` en Supabase
- ✅ Hoja de Ruta (pantalla principal)
  - Notas importantes: solo jefes/administradores pueden añadir y eliminar
  - Horarios: muestra montaje, welcome, desayuno, comida y recogida
  - Checklist de servicio:
    - Categorías: General, Equipamiento, Menús, Bebidas
    - En “General”: sub‑secciones Pre‑Evento, Durante el evento, Post‑Evento
    - Checkbox por ítem, con asignación de responsable y prioridad (visual discreta)
    - Visible para todos; consistente con Desktop
  - Equipamientos y Material: listado sin checkboxes, tipografía mayor
  - Menús: secciones Welcome, PAUSA CAFE, COMIDA y REFRESCOS (datos desde BD; el parser local se eliminó)
  - Bebidas: sección específica
  - Orden bajo checklist: Material → Menús → Bebidas
  - Confirmar lista y material: firma con nombre; guarda `firma_info` y `firma_responsable`, bloqueando ediciones
  - Histórico: lista todas las hojas menos la más reciente; estado vacío elegante; botón atrás en AppBar
- ✅ Acciones deshabilitadas cuando la hoja está verificada (badge “Verificado por …”)
- ✅ Sin “Eliminar” en acciones principales de lista
- ✅ Modo oscuro mejorado
  - Fondo consistente y AppBar degradado en pantallas de Ruta, Ajustes y Usuario
- ✅ Ajustes
  - Ver estado de conexiones y datos de la app
  - Modo oscuro
- ✅ Usuario
  - Perfil y ajustes básicos con soporte de tema oscuro
- 🔁 Sincronización con Desktop vía Supabase
- 🧩 Nota: la vista “Ver datos del empleado” ha sido retirada en móvil (no se muestra ficha detallada)

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
│   ├── hoja_ruta_service.dart
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

### Fase actual: Lista para QA/Testing

- [x] Autenticación y Onboarding
- [x] Hoja de Ruta: Notas, Horarios, Checklist, Material, Menús, Bebidas
- [x] Confirmación (firma) y bloqueo de ediciones
- [x] Histórico (excluye hoja más reciente)
- [x] Modo oscuro revisado (Ruta, Ajustes, Usuario)
- [x] Ajustes y Perfil de usuario
- [x] Eliminadas funciones no requeridas (parser CSV local, des‑verificar, ficha empleado)
- [x] Documentación actualizada y guía de instalación vía APK

Ver [ARCHITECTURE.md](docs/ARCHITECTURE.md) para detalles técnicos.

## 📦 Instalación de la app en Android (APK desde GitHub Releases)

Guía para usuarios y testers que van a instalar la app.

1) Descargar la app
- Entra en la página de “Releases” del proyecto en GitHub.
- Abre la versión más reciente (arriba de la lista).
- Descarga el archivo APK adjunto (por ejemplo, `app-release.apk`).

2) Permitir la instalación (solo la primera vez)
- En tu móvil Android ve a: Ajustes → Seguridad/Privacidad → Instalar apps desconocidas.
- Elige el navegador o gestor de archivos que uses (Chrome, Archivos, Drive…) y activa “Permitir”.

3) Instalar la app
- Toca el archivo APK descargado y pulsa “Instalar”.
- Si aparece un aviso de Play Protect, pulsa “Más detalles” → “Instalar de todos modos”.

4) Abrir e iniciar sesión
- Abre “SSS Kronos Mobile”.
- Inicia sesión con tu usuario y contraseña.
- Si es tu primera vez, completa el tutorial inicial; quedará guardado automáticamente.

5) Actualizar a nuevas versiones
- Repite este proceso descargando el APK de la última versión publicada en “Releases”.

Ayuda rápida
- “App no instalada”: libera espacio, desinstala una versión anterior o reinicia el dispositivo.
- “No encuentro el archivo”: revisa la carpeta Descargas o abre el gestor de archivos.
- Dispositivo no compatible: se requiere Android 8.0 o superior y, en la mayoría de casos, arquitectura arm64.

## ⬆️ Para administradores: publicar el APK en GitHub Releases (manual)

1) Generar build de release
```bash
cd solucions_socials_kronos_mobile
flutter clean
flutter pub get
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://<tu>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<tu_anon_key> \
  --dart-define=GITHUB_REPO_OWNER=<owner> \
  --dart-define=GITHUB_REPO_NAME=<repo>
```
- La APK se genera en: `build/app/outputs/flutter-apk/app-release.apk`

2) Crear un Release en GitHub
- Título: vX.Y.Z
- Notas: cambios relevantes (changelog resumido)
- Adjunta `app-release.apk` como asset.
- Publica el release.

Sugerencia (opcional): Automatizar con GitHub Actions
- Workflow que haga `flutter build apk --release` con caché y suba el artifact al release.
- Requiere secrets con `SUPABASE_URL` y `SUPABASE_ANON_KEY`.

## 🔐 Seguridad

- Las credenciales de Supabase NO deben committearse
- Usar variables de entorno en producción
- Verificar políticas RLS en Supabase
- Las claves de terceros (p.ej. Holded) deben guardarse de forma segura (backend/secret storage).
- En desarrollo se pueden usar `--dart-define` o archivos locales no versionados.

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

# Opcional: otros servicios internos
# flutter run --dart-define=HOLDED_API_KEY_SOLUCIONS=<key> --dart-define=HOLDED_API_KEY_MENJAR=<key>
```

## 📝 Licencia

MIT

## 👥 Contribuidores

- Desarrollo: Marc Fernández Messa
- Desktop App: Brian Bautista

---

**Versión**: 1.0.0 (Preparada para testing)
**Última actualización**: 2025-11-24

Desarrollado por Marc Fernández Messa, utilizando la APP Desktop desarrollada por Brian Bautista para Solucions Socials

