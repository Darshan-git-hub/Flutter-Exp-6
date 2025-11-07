import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'databasehelper.dart';
import 'product.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kIsWeb) {
    // Initialize for web
    databaseFactory = databaseFactoryFfiWeb;
  }
  
  // Test database connection
  bool isConnected = await DatabaseHelper.instance.isDatabaseConnected();
  print('Is database connected? ${isConnected ? 'Yes' : 'No'}');
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  List<Product> _products = [];
  @override
  void initState() {
    super.initState();
    _showAllProducts();
  }

  Future<void> _showAllProducts() async {
    final products = await DatabaseHelper.instance.readAllProducts();
    setState(() {
      _products = products;
    });
  }

  double getTotalStockValue() {
    return _products.fold(
      0,
      (sum, product) => sum + (product.quantity * product.price),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Product Inventory Tracker",
      home: Scaffold(
        backgroundColor: const Color.fromARGB(255, 243, 242, 225),
        appBar: AppBar(
          title: const Text("Product Inventory Tracker"),
          backgroundColor: const Color.fromARGB(255, 255, 175, 2),
        ),
        body: Container(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                      labelText: "Enter product name",
                      border: OutlineInputBorder()),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter the product name";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: "Enter product quantity",
                      border: OutlineInputBorder()),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter the product quantity";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: "Enter product price",
                      border: OutlineInputBorder()),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter the product price";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                Builder(
                  builder: (context) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 255, 132, 31),
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          String name = _nameController.text;
                          int quanity = int.parse(_quantityController.text);
                          double price = double.parse(_priceController.text);
                          Product product = Product(
                              name: name, quantity: quanity, price: price);
                          await DatabaseHelper.instance.insertProduct(product);
                          await _showAllProducts();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Product Details Saved")),
                          );
                          _nameController.clear();
                          _quantityController.clear();
                          _priceController.clear();
                        }
                      },
                      child: const Text("Add Product"),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _products.isEmpty
                      ? const Center(child: Text("No products found"))
                      : ListView.builder(
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            final product = _products[index];
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(product.name[0]),
                                backgroundColor: product.quantity < 5
                                    ? Colors.red
                                    : Colors.blue,
                              ),
                              title: Text(product.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      "Quantity: ${product.quantity}, Price: ${product.price}"),
                                  if (product.quantity < 5)
                                    const Text("Low Stock!",
                                        style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Total Stock Value: ${getTotalStockValue()}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
