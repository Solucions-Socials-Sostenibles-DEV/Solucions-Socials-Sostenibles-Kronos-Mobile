class Validators {
  Validators._();

  static String? requiredField(String? value, {String message = 'Campo obligatorio'}) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? email(String? value, {String message = 'Email inválido'}) {
    if (value == null || value.trim().isEmpty) return message;
    final RegExp regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(value.trim())) return message;
    return null;
  }
}


