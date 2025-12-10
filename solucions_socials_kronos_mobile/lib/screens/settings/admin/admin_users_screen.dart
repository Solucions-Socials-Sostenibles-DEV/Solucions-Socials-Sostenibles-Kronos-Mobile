import 'package:flutter/material.dart';
import '../../../services/admin_service.dart';
import '../../../utils/roles.dart';
import 'admin_user_edit_dialog.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _users = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _filteredUsers = <Map<String, dynamic>>[];
  bool _loading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final List<Map<String, dynamic>> data = await _adminService.getUsers();
      if (mounted) {
        setState(() {
          _users = data;
          _filterUsers();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar usuarios: $e')),
        );
      }
    }
  }

  void _filterUsers() {
    if (_searchQuery.isEmpty) {
      _filteredUsers = List.from(_users);
    } else {
      _filteredUsers = _users.where((user) {
        final name = (user['name'] as String? ?? '').toLowerCase();
        final email = (user['email'] as String? ?? '').toLowerCase(); // Si el email está en user_profiles (a veces no está sincronizado)
        final role = (user['role'] as String? ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || role.contains(query);
      }).toList();
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filterUsers();
    });
  }

  Future<void> _editUser(Map<String, dynamic> user) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AdminUserEditDialog(
        userId: user['id'],
        currentName: user['name'] ?? '',
        currentRole: user['role'] ?? '',
      ),
    );

    if (result == true) {
      _loadUsers();
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Seguro que quieres eliminar al usuario "${user['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _adminService.deleteUser(user['id']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario eliminado')),
          );
          _loadUsers();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF4CAF51);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1216) : const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? <Color>[const Color(0xFF0D1014), const Color(0xFF161A1F)]
                  : <Color>[primary, const Color(0xFF3C8E41)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white, 
          fontSize: 20, 
          fontWeight: FontWeight.bold
        ),
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar usuario...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark ? const Color(0xFF1F2227) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          // Lista
          Expanded(
            child: _loading 
              ? const Center(child: CircularProgressIndicator()) 
              : _filteredUsers.isEmpty
                ? Center(
                    child: Text(
                      _users.isEmpty ? 'No hay usuarios' : 'No se encontraron resultados',
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      final roleCanonical = RoleUtils.toCanonical(user['role']);
                      final roleLabel = RoleUtils.label(roleCanonical);
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        color: isDark ? const Color(0xFF1F2227) : Colors.white,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: primary.withOpacity(0.2),
                            child: Text(
                              (user['name'] as String? ?? '?').substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            user['name'] ?? 'Sin nombre',
                            style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                          ),
                          subtitle: Text(
                            roleLabel,
                            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editUser(user),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteUser(user),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
