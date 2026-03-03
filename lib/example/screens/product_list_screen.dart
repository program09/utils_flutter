import 'package:flutter/material.dart';
import 'package:orm/example/models/category.model.dart';
import 'package:orm/example/models/product.model.dart';
import 'package:orm/example/repository/product_repository.dart';
import 'package:orm/utils/alerts.dart';

class ProductListScreen extends StatefulWidget {
  final Category category;
  const ProductListScreen({super.key, required this.category});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _repo = ProductRepository();
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await _repo.getByCategory(widget.category.id);
    setState(() {
      _products = data;
      _isLoading = false;
    });
  }

  Future<void> _add() async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nuevo Producto en ${widget.category.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: priceCtrl,
              decoration: const InputDecoration(labelText: 'Precio'),
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
              final name = nameCtrl.text;
              final price = double.tryParse(priceCtrl.text) ?? 0.0;
              if (name.isEmpty) return;

              await _repo.insert(
                Product(
                  id: DateTime.now().millisecondsSinceEpoch,
                  name: name,
                  price: price,
                  categoryId: widget.category.id,
                ),
              );

              if (mounted) Navigator.pop(context);
              _load();
              Alerts.success(context, 'Producto añadido');
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
      appBar: AppBar(title: Text('Productos: ${widget.category.name}')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final p = _products[index];
                return ListTile(
                  title: Text(p.name),
                  subtitle: Text('\$${p.price.toStringAsFixed(2)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.grey),
                    onPressed: () async {
                      await _repo.delete(p.id);
                      _load();
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add_shopping_cart),
      ),
    );
  }
}
