# Release Notes v1.0.2

## 🚀 Nuevas Funcionalidades

### Edición de Histórico de Rutas
- **Acceso al Histórico**: Ahora es posible abrir y editar hojas de ruta antiguas desde la pantalla de "Histórico".
- **Modo Edición**: Al abrir una hoja histórica, la pantalla muestra un indicador "Editando Histórico" y un botón de cierre (X) para volver fácilmente.
- **Seguridad de Datos**: La edición de hojas antiguas NO afecta a la hoja de ruta "actual" del resto de usuarios (se ha mejorado la lógica de ordenación por fecha de servicio).

### Gestión de Checklist
- **Permisos por Rol**:
  - **Usuarios**: Solo pueden MARCAR casillas (completar tareas). No pueden desmarcar.
  - **Gestión / Jefes / Admin**: Tienen control total para marcar y desmarcar.
- **Orden Estable**: Se ha corregido el comportamiento donde las tareas cambiaban de posición al ser marcadas. Ahora mantienen un orden fijo.

## 🔒 Seguridad y Mejoras Técnicas

- **Variables de Entorno**: Se ha implementado el uso de un archivo `.env` para manejar las claves de API de Supabase de forma segura, evitando que se expongan en el código fuente.
- **Corrección de Errores**: Solucionado un error de compilación en iOS relacionado con constructores constantes en la pantalla de ruta.

## 📦 Detalles de la Versión
- **Versión**: 1.0.2
- **Build Number**: 3
