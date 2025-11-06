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

- Flutter SDK 3.0+
- Cuenta de Supabase configurada

### Instalación

```bash
# Clonar repositorio
git clone <repo-url>
cd Kronos_Mobile

# Instalar dependencias
flutter pub get

# Configurar Supabase (ver SETUP.md)
# Copiar credenciales a lib/config/supabase_config.dart

# Ejecutar
flutter run
```

Ver [SETUP.md](docs/SETUP.md) para instrucciones detalladas.

## 📚 Documentación

- [ARCHITECTURE.md](docs/ARCHITECTURE.md) - Arquitectura y diseño del sistema
- [SETUP.md](docs/SETUP.md) - Guía de instalación y configuración
- [MIGRATION_GUIDE.md](docs/MIGRATION_GUIDE.md) - Mapeo Desktop → Mobile

## ✨ Funcionalidades

- ✅ Gestión de Hojas de Ruta
- ✅ Checklist interactivo
- ✅ Gestión de personal
- ✅ Firma digital
- ✅ Sincronización en tiempo real con Desktop
- ✅ Soporte offline (próximamente)

## 🛠️ Desarrollo

### Estructura del Proyecto

```
lib/
├── config/          # Configuración (Supabase, etc.)
├── models/          # Modelos de datos
├── services/        # Servicios (lógica de negocio)
├── screens/         # Pantallas
├── widgets/         # Widgets reutilizables
└── utils/           # Utilidades
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

### Fase Actual: Setup Inicial

- [x] Repositorio creado
- [x] Scripts SQL copiados
- [x] Documentación inicial
- [ ] Configuración de Supabase
- [ ] Implementación de servicios
- [ ] Desarrollo de pantallas

Ver [ARCHITECTURE.md](docs/ARCHITECTURE.md) para el plan completo.

## 🔐 Seguridad

- Las credenciales de Supabase NO deben committearse
- Usar variables de entorno en producción
- Verificar políticas RLS en Supabase

## 📝 Licencia

MIT

## 👥 Contribuidores

- Desarrollo: [Tu nombre]
- Desktop App: Brian Bautista

---

**Versión**: 0.1.0 (Desarrollo inicial)
**Última actualización**: 2025-11-06

