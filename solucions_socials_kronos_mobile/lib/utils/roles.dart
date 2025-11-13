class RoleUtils {
  // Conjunto canónico
  static const List<String> canonical = <String>[
    'admin',
    'management',
    'manager',
    'user',
  ];

  // Mapea alias/etiquetas antiguas → canónico
  static String toCanonical(String? raw) {
    final String v = (raw ?? '').trim().toLowerCase();
    switch (v) {
      case 'admin':
      case 'administrador':
        return 'admin';
      case 'management':
      case 'gestion':
      case 'gestión':
        return 'management';
      case 'manager':
      case 'jefe':
      case 'supervisor':
        return 'manager';
      case 'user':
      case 'usuario':
      case 'empleado':
      default:
        return 'user';
    }
  }

  // Etiqueta de presentación
  static String label(String canonical) {
    switch (canonical) {
      case 'admin':
        return 'Administrador';
      case 'management':
        return 'Gestión';
      case 'manager':
        return 'Jefe';
      case 'user':
      default:
        return 'Usuario';
    }
  }
}
