import 'package:flutter/material.dart';
import 'package:orm/example/models/role.model.dart';
import 'package:orm/example/repository/role_repository.dart';
import 'package:orm/utils/alerts.dart';

class RoleListScreen extends StatefulWidget {
  const RoleListScreen({super.key});

  @override
  State<RoleListScreen> createState() => _RoleListScreenState();
}

class _RoleListScreenState extends State<RoleListScreen> {
  final _repo = RoleRepository();
  List<Role> _roles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await _repo.getAll();
    setState(() {
      _roles = data;
      _isLoading = false;
    });
  }

  Future<void> _addOrEdit({Role? role}) async {
    final controller = TextEditingController(text: role?.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(role == null ? 'Nuevo Rol' : 'Editar Rol'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nombre del Rol'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              final newRole = Role(
                id: role?.id ?? DateTime.now().millisecondsSinceEpoch,
                name: controller.text,
              );

              if (role == null) {
                await _repo.insert(newRole);
              } else {
                await _repo.update(newRole, id: role.id);
              }

              if (mounted) Navigator.pop(context);
              _load();
              Alerts.success(context, 'Rol guardado');
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Roles')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _roles.length,
              itemBuilder: (context, index) {
                final role = _roles[index];
                return ListTile(
                  leading: const Icon(
                    Icons.verified_user,
                    color: Colors.purple,
                  ),
                  title: Text(role.name),
                  subtitle: Text('ID: ${role.id}'),
                  onTap: () => _addOrEdit(role: role),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await _repo.delete(role.id);
                      _load();
                      Alerts.warning(context, 'Rol eliminado');
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEdit(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
