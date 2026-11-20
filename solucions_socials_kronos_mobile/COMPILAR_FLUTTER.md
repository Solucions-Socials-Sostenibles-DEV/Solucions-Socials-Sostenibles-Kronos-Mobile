# Cómo ejecutar Kronos Mobile

1. Instala una versión de Flutter cuyo Dart SDK cumpla `^3.9.2` (Dart 3.9.2 o superior dentro de la versión mayor 3).
2. Abre una terminal en `solucions_socials_kronos_mobile/`.
3. Edita `assets/.env` y configura las credenciales reales de tu proyecto Supabase:
   - `SUPABASE_URL=https://<tu-proyecto>.supabase.co`
   - `SUPABASE_ANON_KEY=<tu-clave-anon-publica>`
4. Ejecuta:

   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

La carga de variables de entorno apunta a `assets/.env`, que es el archivo declarado en `pubspec.yaml`.
Si las credenciales siguen siendo de ejemplo, la aplicación mostrará una pantalla de configuración en lugar de cerrarse al iniciar.

Nota: no se ha podido ejecutar `flutter analyze` ni `flutter run` en este entorno porque el SDK de Flutter/Dart no está instalado aquí.
