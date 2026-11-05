class CategoryModel {
  final String id;
  final String title;
  final String imageUrl;
  final String? description;
  final bool isActive;
  final int sortOrder;

  const CategoryModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.description,
    this.isActive = true,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': title,
      'title': title,
      'image_url': imageUrl,
      'imageUrl': imageUrl,
      'description': description,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String? ?? '',
      title: (json['name'] ?? json['title'] ?? '') as String,
      imageUrl: (json['image_url'] ?? json['imageUrl'] ?? '') as String,
      description: json['description'] as String?,
      isActive: (json['is_active'] ?? true) as bool,
      sortOrder: (json['sort_order'] ?? 0) as int,
    );
  }
}
