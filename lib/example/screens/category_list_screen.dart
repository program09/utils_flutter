import 'package:flutter/material.dart';
import 'package:orm/example/models/category.model.dart';
import 'package:orm/example/repository/category_repository.dart';
import 'package:orm/example/screens/product_list_screen.dart';
import 'package:orm/utils/alerts.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  final _repo = CategoryRepository();
  List<Category> _categories = [];
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
      _categories = data;
      _isLoading = false;
    });
  }

  Future<void> _add() async {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Categoría'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              await _repo.insert(
                Category(
                  id: DateTime.now().millisecondsSinceEpoch,
                  name: controller.text,
                ),
              );
              if (mounted) Navigator.pop(context);
              _load();
              Alerts.success(context, 'Categoría creada');
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
      appBar: AppBar(title: const Text('Categorías')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return ListTile(
                  title: Text(cat.name),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductListScreen(category: cat),
                    ),
                  ),
                  onLongPress: () async {
                    await _repo.delete(cat.id);
                    _load();
                    Alerts.warning(context, 'Categoría eliminada');
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
    );
  }
}
