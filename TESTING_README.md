# 🧪 Testing - SSS Kronos Mobile

## 🚀 Inicio Rápido

### Ejecutar Todos los Tests

```bash
cd solucions_socials_kronos_mobile

# Opción 1: Usando el script
chmod +x run_tests.sh
./run_tests.sh

# Opción 2: Comando directo
flutter test
```

---

## 📋 Tests Disponibles

### ✅ Tests Unitarios

| Archivo | Qué Testea | Tests |
|---------|------------|-------|
| `test/utils/validators_test.dart` | Validaciones de formularios | 11 tests |
| `test/utils/date_formatter_test.dart` | Formateo de fechas y horas | 11 tests |
| `test/utils/roles_test.dart` | Utilidades de roles de usuario | 19 tests |
| `test/config/config_test.dart` | Configuración de servicios | 8 tests |

**Total: ~49 tests unitarios** ✅

---

## 🎯 Comandos Útiles

### Ejecutar tests específicos

```bash
# Solo validadores
flutter test test/utils/validators_test.dart

# Solo formateo de fechas
flutter test test/utils/date_formatter_test.dart

# Solo roles
flutter test test/utils/roles_test.dart

# Solo configuración
flutter test test/config/config_test.dart
```

### Tests con más información

```bash
# Ver cada test individualmente
flutter test --reporter expanded

# O usando el script
./run_tests.sh -v
```

### Tests en modo watch

```bash
# Los tests se reejecutarán automáticamente al guardar
flutter test --watch

# O usando el script
./run_tests.sh -w
```

### Generar reporte de cobertura

```bash
# Generar cobertura
flutter test --coverage

# O usando el script
./run_tests.sh -c

# Ver reporte HTML (requiere lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 📖 Guía Completa de Testing

Para una guía detallada con tests manuales, checklist y solución de problemas:

👉 **[Ver TESTING_GUIDE.md](../TESTING_GUIDE.md)**

Incluye:
- 🤖 Tests automatizados (esta guía)
- 🖐️ Tests manuales paso a paso
- ✅ Checklist de verificación
- 🐛 Solución de problemas

---

## 🎨 Opciones del Script

El script `run_tests.sh` acepta varias opciones:

```bash
# Ayuda
./run_tests.sh -h

# Modo verbose (ver cada test)
./run_tests.sh -v

# Con cobertura de código
./run_tests.sh -c

# Modo watch (auto-reejecutar)
./run_tests.sh -w

# Solo tests unitarios
./run_tests.sh -u
```

---

## 📊 Interpretando Resultados

### ✅ Tests Exitosos

```
00:03 +49: All tests passed!
✅ ¡Todos los tests pasaron exitosamente!
🎉 La aplicación está lista para usar
```

### ❌ Tests Fallidos

```
00:02 +45 -1: test/utils/validators_test.dart: devuelve error cuando el email es null [E]
  Expected: 'Email inválido'
    Actual: null
```

Si ves esto:
1. Lee el mensaje de error
2. Identifica qué test falló
3. Revisa el código correspondiente
4. Corrige el problema
5. Vuelve a ejecutar los tests

---

## 🔧 Solución de Problemas

### ❌ Error: "Comando no encontrado: flutter"

**Solución:**
```bash
# Verifica que Flutter está instalado
flutter --version

# Si no está, instala Flutter SDK
# https://flutter.dev/docs/get-started/install
```

### ❌ Error: "Permission denied: ./run_tests.sh"

**Solución:**
```bash
# Dale permisos de ejecución al script
chmod +x run_tests.sh
```

### ❌ Tests fallan con errores de dependencias

**Solución:**
```bash
# Limpia y reinstala dependencias
flutter clean
flutter pub get
flutter test
```

---

## 🎯 Antes de Cada Release

Ejecuta este checklist:

```bash
# 1. Ejecuta todos los tests
./run_tests.sh

# 2. Verifica cobertura
./run_tests.sh -c

# 3. Si todo está verde ✅, procede con la release
```

---

## 📝 Agregar Nuevos Tests

### 1. Crea el archivo de test

```bash
# Estructura recomendada
test/
├── utils/
│   └── mi_utilidad_test.dart
├── services/
│   └── mi_servicio_test.dart
└── widgets/
    └── mi_widget_test.dart
```

### 2. Estructura básica de un test

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:solucions_socials_kronos_mobile/mi_archivo.dart';

void main() {
  group('MiClase Tests', () {
    test('descripción de lo que testea', () {
      // Arrange (preparar)
      final int input = 5;
      
      // Act (ejecutar)
      final int result = miFunction(input);
      
      // Assert (verificar)
      expect(result, equals(10));
    });
  });
}
```

### 3. Ejecuta el nuevo test

```bash
flutter test test/utils/mi_utilidad_test.dart
```

---

## 🔗 Enlaces Útiles

- 📖 [Guía Completa de Testing](../TESTING_GUIDE.md)
- 📚 [Documentación de Flutter Testing](https://flutter.dev/docs/testing)
- 🐛 [Reportar Bugs](https://github.com/Marcausente/Solucions-Socials-Sostenibles-Kronos-Mobile/issues)

---

## 🎉 ¡Listo!

Ahora tienes todo lo necesario para testear la aplicación. 

**Recuerda:** Los tests son tu red de seguridad. Ejecútalos frecuentemente para asegurar que todo funciona correctamente.

```bash
# Ejecuta los tests
./run_tests.sh

# Si todo está verde ✅
# ¡La app está lista! 🎉
```

