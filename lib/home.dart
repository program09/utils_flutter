import 'dart:async';
import 'package:flutter/material.dart';
import 'package:orm/example/models/users.model.dart';
import 'package:orm/example/repository/user_repository.dart';
import 'package:orm/example/repository/role_repository.dart';
import 'package:orm/utils/alerts.dart';
import 'package:orm/utils/event_bridge.dart';
import 'package:orm/utils/events.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UserRepository _userRepo = UserRepository();
  List<User> _users = [];
  bool _isLoading = true;

  StreamSubscription? _eventsSub;
  StreamSubscription? _bridgeSub;

  @override
  void initState() {
    super.initState();
    _loadUsers();

    // Escuchar eventos internos
    _eventsSub = Events.listener('syncCompleted', (data) {
      if (!mounted) return;
      _loadUsers();
      Alerts.success(context, data['message'] ?? 'Sincronización lista');
    });

    // Escuchar eventos del background
    _bridgeSub = EventBridge.listener('syncCompleted', (data) {
      if (!mounted) return;
      _loadUsers();
      Alerts.info(context, 'Datos actualizados desde Background');
    });
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _userRepo.getAll();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) Alerts.error(context, 'Error cargando usuarios: $e');
    }
  }

  Future<void> _addOrUpdateUser({User? user}) async {
    final isEditing = user != null;
    final nameController = TextEditingController(text: user?.name);
    final ageController = TextEditingController(text: user?.age.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Editar Usuario' : 'Nuevo Usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: ageController,
              decoration: const InputDecoration(labelText: 'Edad'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text;
              final age = int.tryParse(ageController.text) ?? 0;

              if (name.isEmpty) return;

              final newUser = User(
                id: isEditing ? user.id : DateTime.now().millisecondsSinceEpoch,
                name: name,
                age: age,
              );

              if (isEditing) {
                await _userRepo.update(newUser, id: user.id);
                Alerts.success(context, 'Usuario actualizado');
              } else {
                await _userRepo.insert(newUser);
                Alerts.success(context, 'Usuario creado');
              }

              if (mounted) Navigator.pop(context);
              _loadUsers();
            },
            child: Text(isEditing ? 'Actualizar' : 'Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _manageRoles(User user) async {
    final roleRepo = RoleRepository();
    final allRoles = await roleRepo.getAll();
    final userRoles = await roleRepo.getRolesByUser(user.id);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Roles de ${user.name}'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: allRoles.length,
                  itemBuilder: (context, index) {
                    final role = allRoles[index];
                    final isAssigned = userRoles.any((r) => r.id == role.id);

                    return CheckboxListTile(
                      title: Text(role.name),
                      value: isAssigned,
                      onChanged: (val) async {
                        if (val == true) {
                          await roleRepo.assignToUser(user.id, role.id!);
                        } else {
                          await roleRepo.removeFromUser(user.id, role.id!);
                        }

                        // Recargar roles del usuario
                        final updated = await roleRepo.getRolesByUser(user.id);
                        setDialogState(() {
                          userRoles.clear();
                          userRoles.addAll(updated);
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteUser(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar'),
        content: Text('¿Borrar a ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, borrar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _userRepo.delete(user.id);
      Alerts.warning(context, 'Usuario eliminado');
      _loadUsers();
    }
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    _bridgeSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios ORM'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUsers),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
          ? const Center(child: Text('No hay usuarios registrados.'))
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(user.age.toString())),
                  title: Text(user.name),
                  subtitle: Text('ID: ${user.id}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.security, color: Colors.purple),
                        onPressed: () => _manageRoles(user),
                        tooltip: 'Asignar Roles',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _addOrUpdateUser(user: user),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteUser(user),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrUpdateUser(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
