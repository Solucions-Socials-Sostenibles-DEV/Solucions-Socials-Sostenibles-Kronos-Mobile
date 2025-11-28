class Validators {
  Validators._();

  static String? requiredField(
    String? value, {
    String message = 'Campo obligatorio',
  }) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? email(String? value, {String message = 'Email inválido'}) {
    if (value == null || value.trim().isEmpty) return message;
    final RegExp regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(value.trim())) return message;
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (value.length < 8) {
      return 'Mínimo 8 caracteres';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Debe contener al menos una mayúscula';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Debe contener al menos un número';
    }
    return null; // válida
  }
}
