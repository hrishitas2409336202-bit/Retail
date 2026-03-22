class Product {
  final String id;
  final String name;
  final String category;
  double price;
  int stock;
  final int threshold;
  final String emoji;
  String? expires;
  final String shelf;
  final String supplierId;
  final String? barcode;
  final String? imageUrl;
  final String? unit;
  final String? description;
  String? mfgDate;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    required this.threshold,
    required this.emoji,
    this.expires,
    required this.shelf,
    required this.supplierId,
    this.barcode,
    this.imageUrl,
    this.unit,
    this.description,
    this.mfgDate,
  });

  factory Product.fromJson(Map<dynamic, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      stock: (json['stock'] ?? 0) as int,
      threshold: (json['threshold'] ?? 0) as int,
      emoji: json['emoji']?.toString() ?? '📦',
      expires: json['expires']?.toString(),
      shelf: json['shelf']?.toString() ?? '?',
      supplierId: json['supplierId']?.toString() ?? 'SUP001',
      barcode: json['barcode']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      unit: json['unit']?.toString(),
      description: json['description']?.toString(),
      mfgDate: json['mfgDate']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'stock': stock,
      'threshold': threshold,
      'emoji': emoji,
      'expires': expires,
      'shelf': shelf,
      'supplierId': supplierId,
      'barcode': barcode,
      'imageUrl': imageUrl,
      'unit': unit,
      'description': description,
      'mfgDate': mfgDate,
    };
  }
}

