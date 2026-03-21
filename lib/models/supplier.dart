class Supplier {
  final String id;
  final String name;
  final String category;
  final String emoji;
  final String status;
  final String monthly;
  final String ontime;
  final String rating;
  final String color;
  final String phone;    // WhatsApp-enabled phone (with country code, e.g. 919876543210)
  final String email;    // Supplier email address
  final String minOrder; // Minimum order quantity
  final String businessName;

  Supplier({
    required this.id,
    required this.name,
    required this.category,
    required this.emoji,
    required this.status,
    required this.monthly,
    required this.ontime,
    required this.rating,
    required this.color,
    this.phone = '',
    this.email = '',
    this.minOrder = '50',
    this.businessName = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'emoji': emoji,
    'status': status,
    'monthly': monthly,
    'ontime': ontime,
    'rating': rating,
    'color': color,
    'phone': phone,
    'email': email,
    'minOrder': minOrder,
    'businessName': businessName,
  };

  factory Supplier.fromJson(Map<dynamic, dynamic> json) => Supplier(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    category: json['category']?.toString() ?? '',
    emoji: json['emoji']?.toString() ?? '🏢',
    status: json['status']?.toString() ?? 'Active',
    monthly: json['monthly']?.toString() ?? '',
    ontime: json['ontime']?.toString() ?? '100%',
    rating: json['rating']?.toString() ?? '5.0',
    color: json['color']?.toString() ?? '6C63FF',
    phone: json['phone']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    minOrder: json['minOrder']?.toString() ?? '50',
    businessName: json['businessName']?.toString() ?? '',
  );
}

