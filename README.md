# 📱 SSS Kronos Mobile

Aplicación móvil Flutter para la gestión de **Hojas de Ruta** del sistema SSS Kronos.

> ✅ **Versión 1.0 - Lista para Producción**  
> 📥 **[Descargar APK](#-descargar-e-instalar-la-app)** _(pendiente de publicar)_ | 📖 **[Manual de Usuario](https://docs.google.com/document/d/1VyEojHDf-NtNp4Ufff_hr-TpM_tW7enjEtEMNN7hdHk/edit?usp=sharing)**

---

## 📑 Índice

- [🎯 Descripción](#-descripción)
- [📥 Descargar e Instalar](#-descargar-e-instalar-la-app)
- [📚 Documentación](#-documentación)
- [✨ Funcionalidades](#-funcionalidades)
- [🚀 Inicio Rápido (Desarrolladores)](#-inicio-rápido)
- [🔧 Generar y Publicar APK](#-para-administradores-generar-y-publicar-el-apk)
- [📋 Estado del Proyecto](#-estado-del-proyecto)

---

## 🎯 Descripción

Aplicación Flutter (iOS/Android) para consultar y operar con las Hojas de Ruta, sincronizada en tiempo real con la app Desktop (Supabase).

**Características principales:**
- ✨ Gestión completa de hojas de ruta en tiempo real
- 👥 Sistema de permisos por roles (Admin, Gestión, Jefe)
- ✅ Checklist de servicio con categorías y prioridades
- 📝 Confirmación digital con firma
- 📊 Histórico de hojas de ruta
- 🌓 Modo oscuro
- 📱 Optimizada para dispositivos móviles

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

### Para Usuarios

- **[Manual de Usuario](https://docs.google.com/document/d/1VyEojHDf-NtNp4Ufff_hr-TpM_tW7enjEtEMNN7hdHk/edit?usp=sharing)** - Guía completa de uso de la aplicación

### Para Desarrolladores

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

### ✅ Versión 1.0 - Lista para Producción

La aplicación está **lista para ser desplegada** en producción. Todas las funcionalidades principales han sido implementadas y probadas.

#### Funcionalidades Completadas

- [x] Autenticación y Onboarding
- [x] Hoja de Ruta: Notas, Horarios, Checklist, Material, Menús, Bebidas
- [x] Confirmación (firma) y bloqueo de ediciones
- [x] Histórico (excluye hoja más reciente)
- [x] Modo oscuro revisado (Ruta, Ajustes, Usuario)
- [x] Ajustes y Perfil de usuario
- [x] Sistema de permisos por roles (admin, management, manager)
- [x] Sincronización en tiempo real con Desktop
- [x] Mensajes de estado cuando no hay datos cargados
- [x] Documentación técnica completa

Ver [ARCHITECTURE.md](docs/ARCHITECTURE.md) para detalles técnicos.

## 📦 Descargar e Instalar la App

### 📥 Descarga la última versión

**APK para Android:**  
> 🔗 **[Descargar APK aquí]** _(pendiente de publicar)_

La aplicación se distribuye mediante archivo APK para dispositivos Android. Una vez generada, el enlace estará disponible aquí.

---

### 📱 Guía de Instalación para Usuarios

#### 1️⃣ Descargar la app
- Descarga el archivo APK desde el enlace de arriba usando tu móvil Android.
- También puedes acceder a la sección **[Releases](../../releases)** de este repositorio y descargar el archivo `app-release.apk` de la versión más reciente.

#### 2️⃣ Permitir la instalación (solo la primera vez)
- En tu móvil Android ve a: **Ajustes → Seguridad/Privacidad → Instalar apps desconocidas**.
- Elige el navegador o gestor de archivos que uses (Chrome, Archivos, Drive…) y activa **"Permitir"**.

#### 3️⃣ Instalar la app
- Toca el archivo APK descargado y pulsa **"Instalar"**.
- Si aparece un aviso de Play Protect, pulsa **"Más detalles" → "Instalar de todos modos"**.

#### 4️⃣ Abrir e iniciar sesión
- Abre **"SSS Kronos Mobile"**.
- Inicia sesión con tu usuario y contraseña proporcionados por el administrador.
- Si es tu primera vez, completa el tutorial inicial; tu progreso quedará guardado automáticamente.

#### 5️⃣ Actualizar a nuevas versiones
- Repite este proceso descargando el APK de la última versión publicada.
- La app te notificará cuando haya actualizaciones disponibles.

---

### 🆘 Ayuda Rápida

| Problema | Solución |
|----------|----------|
| "App no instalada" | Libera espacio, desinstala una versión anterior o reinicia el dispositivo |
| "No encuentro el archivo" | Revisa la carpeta **Descargas** o abre el gestor de archivos |
| Dispositivo no compatible | Se requiere **Android 8.0 o superior** (arm64) |
| No puedo iniciar sesión | Contacta con el administrador para verificar tus credenciales |

---

### 📖 Manual de Usuario

Para aprender a usar todas las funcionalidades de la app, consulta el **[Manual de Usuario completo](https://docs.google.com/document/d/1VyEojHDf-NtNp4Ufff_hr-TpM_tW7enjEtEMNN7hdHk/edit?usp=sharing)**.

## 🔧 Para Administradores: Generar y Publicar el APK

### 1️⃣ Generar el APK de Release

```bash
cd solucions_socials_kronos_mobile
flutter clean
flutter pub get
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://<tu-proyecto>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<tu_anon_key> \
  --dart-define=GITHUB_REPO_OWNER=<owner> \
  --dart-define=GITHUB_REPO_NAME=<repo>
```

El APK se generará en: `build/app/outputs/flutter-apk/app-release.apk`

### 2️⃣ Publicar en GitHub Releases

1. Ve a la sección **[Releases](../../releases)** del repositorio
2. Haz clic en **"Create a new release"**
3. Configura el release:
   - **Tag**: `v1.0.0` (o la versión correspondiente)
   - **Título**: `SSS Kronos Mobile v1.0.0`
   - **Descripción**: Incluye el changelog con los cambios principales
4. Arrastra el archivo `app-release.apk` a la sección de assets
5. Marca como "Latest release" si es la versión estable más reciente
6. Haz clic en **"Publish release"**

### 3️⃣ Actualizar el README

Después de publicar el release, actualiza el enlace de descarga en este README:

```markdown
**APK para Android:**  
> 🔗 **[Descargar SSS Kronos Mobile v1.0.0](../../releases/download/v1.0.0/app-release.apk)**
```

### 🤖 Opcional: Automatización con GitHub Actions

Puedes crear un workflow que genere y publique automáticamente el APK:

- Crea `.github/workflows/release.yml`
- Configura los secrets en GitHub: `SUPABASE_URL`, `SUPABASE_ANON_KEY`
- El workflow se activará al crear un nuevo tag `v*`
- Compilará el APK y lo adjuntará automáticamente al release

Ver documentación de GitHub Actions para más detalles.

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

**Versión**: 1.0.0 - Lista para Producción  
**Última actualización**: 25 de noviembre de 2025

**Recursos adicionales:**
- 📖 [Manual de Usuario](https://docs.google.com/document/d/1VyEojHDf-NtNp4Ufff_hr-TpM_tW7enjEtEMNN7hdHk/edit?usp=sharing)
- 📥 [Descargas](../../releases)
- 🐛 [Reportar un problema](../../issues)

Desarrollado por **Marc Fernández Messa**, basado en la aplicación Desktop desarrollada por **Brian Bautista** para **Solucions Socials Sostenibles**.

