import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/product.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Product> products = [];

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    final data = await DbHelper.instance.getProducts();
    setState(() => products = data);
  }

  void showProductDialog({Product? product}) {
    final nameController = TextEditingController(text: product?.name ?? '');
    final priceController =
    TextEditingController(text: product?.price.toString() ?? '');
    final stockController =
    TextEditingController(text: product?.stock.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(product == null ? 'Add Product' : 'Edit Product'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final price = double.tryParse(priceController.text);
                final stock = int.tryParse(stockController.text);

                if (name.isEmpty || price == null || stock == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields correctly')),
                  );
                  return;
                }

                final newProduct = Product(
                  id: product?.id,
                  name: name,
                  price: price,
                  stock: stock,
                );

                if (product == null) {
                  await DbHelper.instance.addProduct(newProduct);
                } else {
                  await DbHelper.instance.updateProduct(newProduct);
                }

                if (!context.mounted) return;
                Navigator.pop(context);
                loadProducts();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteProduct(Product p) async {
    await DbHelper.instance.deleteProduct(p.id!);
    loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: products.isEmpty
          ? const Center(child: Text('No products yet. Tap + to add one.'))
          : ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final p = products[index];
          final lowStock = p.stock <= 5;
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(p.name),
              subtitle: Text(
                'Price: ${p.price}  |  Stock: ${p.stock}'
                    '${lowStock ? '  (LOW)' : ''}',
                style: TextStyle(color: lowStock ? Colors.red : null),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => showProductDialog(product: p),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteProduct(p),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showProductDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}