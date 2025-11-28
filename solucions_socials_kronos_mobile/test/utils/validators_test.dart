import 'package:flutter_test/flutter_test.dart';
import 'package:solucions_socials_kronos_mobile/utils/validators.dart';

void main() {
  group('Validators Tests', () {
    group('requiredField', () {
      test('devuelve error cuando el valor es null', () {
        final String? result = Validators.requiredField(null);
        expect(result, equals('Campo obligatorio'));
      });

      test('devuelve error cuando el valor está vacío', () {
        final String? result = Validators.requiredField('');
        expect(result, equals('Campo obligatorio'));
      });

      test('devuelve error cuando el valor solo tiene espacios', () {
        final String? result = Validators.requiredField('   ');
        expect(result, equals('Campo obligatorio'));
      });

      test('devuelve null cuando el valor es válido', () {
        final String? result = Validators.requiredField('Texto válido');
        expect(result, isNull);
      });

      test('respeta el mensaje personalizado', () {
        final String? result = Validators.requiredField(
          null,
          message: 'Este campo es requerido',
        );
        expect(result, equals('Este campo es requerido'));
      });
    });

    group('email', () {
      test('devuelve error cuando el email es null', () {
        final String? result = Validators.email(null);
        expect(result, equals('Email inválido'));
      });

      test('devuelve error cuando el email está vacío', () {
        final String? result = Validators.email('');
        expect(result, equals('Email inválido'));
      });

      test('devuelve error cuando el email no tiene @', () {
        final String? result = Validators.email('usuario.com');
        expect(result, equals('Email inválido'));
      });

      test('devuelve error cuando el email no tiene dominio', () {
        final String? result = Validators.email('usuario@');
        expect(result, equals('Email inválido'));
      });

      test('devuelve error cuando el email no tiene extensión', () {
        final String? result = Validators.email('usuario@dominio');
        expect(result, equals('Email inválido'));
      });

      test('devuelve null cuando el email es válido', () {
        final String? result = Validators.email('usuario@dominio.com');
        expect(result, isNull);
      });

      test('acepta emails con subdominios', () {
        final String? result = Validators.email('usuario@mail.dominio.com');
        expect(result, isNull);
      });

      test('acepta emails con puntos en el nombre', () {
        final String? result = Validators.email('nombre.apellido@dominio.com');
        expect(result, isNull);
      });

      test('trimea espacios antes de validar', () {
        final String? result = Validators.email('  usuario@dominio.com  ');
        expect(result, isNull);
      });

      test('respeta el mensaje personalizado', () {
        final String? result = Validators.email(
          'invalido',
          message: 'Formato de correo incorrecto',
        );
        expect(result, equals('Formato de correo incorrecto'));
      });
    });

    group('password', () {
      test('devuelve error cuando la contraseña es null', () {
        final String? result = Validators.password(null);
        expect(result, equals('La contraseña es obligatoria'));
      });

      test('devuelve error cuando la contraseña está vacía', () {
        final String? result = Validators.password('');
        expect(result, equals('La contraseña es obligatoria'));
      });

      test('devuelve error cuando tiene menos de 8 caracteres', () {
        final String? result = Validators.password('Pass1');
        expect(result, equals('Mínimo 8 caracteres'));
      });

      test('devuelve error cuando no tiene mayúscula', () {
        final String? result = Validators.password('password123');
        expect(result, equals('Debe contener al menos una mayúscula'));
      });

      test('devuelve error cuando no tiene número', () {
        final String? result = Validators.password('Password');
        expect(result, equals('Debe contener al menos un número'));
      });

      test('devuelve null cuando la contraseña es válida', () {
        final String? result = Validators.password('Password123');
        expect(result, isNull);
      });

      test('acepta contraseñas con caracteres especiales', () {
        final String? result = Validators.password('Pass@word123');
        expect(result, isNull);
      });

      test('acepta contraseñas largas válidas', () {
        final String? result = Validators.password('MiContraseña123Segura');
        expect(result, isNull);
      });

      test('valida exactamente 8 caracteres con requisitos', () {
        final String? result = Validators.password('Pass1234');
        expect(result, isNull);
      });

      test('falla con 8 caracteres pero sin mayúscula', () {
        final String? result = Validators.password('password1');
        expect(result, equals('Debe contener al menos una mayúscula'));
      });

      test('falla con 8 caracteres pero sin número', () {
        final String? result = Validators.password('Password');
        expect(result, equals('Debe contener al menos un número'));
      });
    });
  });
}
