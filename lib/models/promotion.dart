class Promotion {
  final String id;
  final String title;
  final String description;
  final String type; // 'discount', 'bundle', 'clearance'
  final List<String> applicableProductIds;
  final double discountPercent;
  final bool isActive;
  final String icon;

  Promotion({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.applicableProductIds,
    this.discountPercent = 0.0,
    this.isActive = false,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'type': type,
    'applicableProductIds': applicableProductIds,
    'discountPercent': discountPercent,
    'isActive': isActive,
    'icon': icon,
  };

  factory Promotion.fromJson(Map<dynamic, dynamic> json) => Promotion(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    type: json['type']?.toString() ?? 'discount',
    applicableProductIds: json['applicableProductIds'] != null 
        ? List<String>.from(json['applicableProductIds'].map((i) => i.toString()))
        : [],
    discountPercent: (json['discountPercent'] ?? 0.0).toDouble(),
    isActive: json['isActive'] ?? false,
    icon: json['icon']?.toString() ?? '🎁',
  );
}

