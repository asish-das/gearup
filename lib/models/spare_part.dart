
class SparePart {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final int stock;
  final String? serviceCenterId;

  SparePart({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.stock,
    this.serviceCenterId,
  });

  factory SparePart.fromMap(Map<String, dynamic> data, String id) {
    return SparePart(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      category: data['category'] ?? 'General',
      stock: data['stock'] ?? 0,
      serviceCenterId: data['serviceCenterId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'stock': stock,
      'serviceCenterId': serviceCenterId,
    };
  }
}
