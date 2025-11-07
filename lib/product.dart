class Product {
  int? id;

  String name;

  int quantity;

  double price;

  Product(
      {this.id,
      required this.name,
      required this.quantity,
      required this.price});

  factory Product.fromRow(Map<String, dynamic> row) {
    return Product(
        id: row['id'],
        name: row['name'],
        quantity: row['quantity'],
        price: row['price']);
  }
}
