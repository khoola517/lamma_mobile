class ServiceItemModel {
  final String id;
  final String title;
  final String category;
  final String? categoryId;
  final String? providerId;
  final String location;
  final num price;
  final String priceUnit;
  final double rating;
  final int reviewsCount;
  final String imageUrl;
  final List<String> images;
  final String description;
  final String? capacity;
  final List<String> features;
  final List<String> occasions;
  final List<Map<String, String>> workingHours;
  final bool isFavorite;
  final String? phone;
  final String? address;
  final String status;

  const ServiceItemModel({
    required this.id,
    required this.title,
    required this.category,
    this.categoryId,
    this.providerId,
    required this.location,
    required this.price,
    this.priceUnit = 'ر.ي',
    required this.rating,
    this.reviewsCount = 0,
    required this.imageUrl,
    this.images = const [],
    this.description = '',
    this.capacity,
    this.features = const [],
    this.occasions = const [],
    this.workingHours = const [],
    this.isFavorite = false,
    this.phone,
    this.address,
    this.status = 'active',
  });

  String get formattedPrice {
    final formattedNum = price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return '$formattedNum $priceUnit';
  }

  /// إرجاع قائمة كافة الصور المتاحة للخدمة (الصورة الرئيسية + صور المعرض)
  List<String> get allImages {
    final list = <String>[];
    if (imageUrl.trim().isNotEmpty) {
      list.add(imageUrl.trim());
    }
    for (final img in images) {
      final trimmed = img.trim();
      if (trimmed.isNotEmpty && !list.contains(trimmed)) {
        list.add(trimmed);
      }
    }
    return list;
  }

  ServiceItemModel copyWith({
    String? id,
    String? title,
    String? category,
    String? categoryId,
    String? providerId,
    String? location,
    num? price,
    String? priceUnit,
    double? rating,
    int? reviewsCount,
    String? imageUrl,
    List<String>? images,
    String? description,
    String? capacity,
    List<String>? features,
    List<String>? occasions,
    List<Map<String, String>>? workingHours,
    bool? isFavorite,
    String? phone,
    String? address,
    String? status,
  }) {
    return ServiceItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      providerId: providerId ?? this.providerId,
      location: location ?? this.location,
      price: price ?? this.price,
      priceUnit: priceUnit ?? this.priceUnit,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      description: description ?? this.description,
      capacity: capacity ?? this.capacity,
      features: features ?? this.features,
      occasions: occasions ?? this.occasions,
      workingHours: workingHours ?? this.workingHours,
      isFavorite: isFavorite ?? this.isFavorite,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'name': title,
      'category': category,
      'category_id': categoryId,
      'provider_id': providerId,
      'location': location,
      'price': price,
      'priceUnit': priceUnit,
      'currency': priceUnit,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'reviews_count': reviewsCount,
      'imageUrl': imageUrl,
      'image_url': imageUrl,
      'images': images,
      'description': description,
      'capacity': capacity,
      'features': features,
      'occasions': occasions,
      'working_hours': workingHours,
      'isFavorite': isFavorite,
      'phone': phone,
      'address': address,
      'status': status,
    };
  }

  factory ServiceItemModel.fromJson(Map<String, dynamic> json) {
    // Handling category mapping from direct join or string
    String resolvedCategory = 'عام';
    if (json['categories'] is Map && json['categories']['name'] != null) {
      resolvedCategory = json['categories']['name'] as String;
    } else if (json['category'] != null) {
      resolvedCategory = json['category'] as String;
    }

    // Handling images list from join or json
    List<String> resolvedImages = [];
    if (json['service_images'] is List) {
      resolvedImages = (json['service_images'] as List)
          .map((img) => (img is Map ? img['image_url'] : img.toString()) as String)
          .where((url) => url.trim().isNotEmpty)
          .toList();
    } else if (json['images'] is List) {
      resolvedImages = (json['images'] as List)
          .map((e) => e.toString().trim())
          .where((url) => url.isNotEmpty)
          .toList();
    }

    final mainImage = (json['image_url'] ?? json['imageUrl'] ?? '') as String;
    if (mainImage.trim().isNotEmpty && !resolvedImages.contains(mainImage.trim())) {
      resolvedImages.insert(0, mainImage.trim());
    }

    // Capacity as string or int
    String? resolvedCapacity;
    if (json['capacity'] != null) {
      final cap = json['capacity'];
      resolvedCapacity = cap is int ? '$cap' : cap.toString().replaceAll('تتسع لـ ', '').replaceAll(' شخص', '').trim();
    }

    // Features
    List<String> resolvedFeatures = [];
    if (json['features'] is List) {
      resolvedFeatures = (json['features'] as List).map((e) => e.toString()).toList();
    }

    // Occasions from Supabase
    List<String> resolvedOccasions = [];
    if (json['occasions'] is List) {
      resolvedOccasions = (json['occasions'] as List).map((e) => e.toString()).toList();
    }

    // Working Hours from Supabase
    List<Map<String, String>> resolvedWorkingHours = [];
    if (json['working_hours'] is List) {
      resolvedWorkingHours = (json['working_hours'] as List).map((item) {
        if (item is Map) {
          return {
            'day': (item['day'] ?? '').toString(),
            'status': (item['status'] ?? '').toString(),
            'time': (item['time'] ?? '').toString(),
          };
        }
        return <String, String>{};
      }).where((m) => m.isNotEmpty).toList();
    }

    // Provider profile details (address / phone)
    String? resolvedAddress = json['address'] as String?;
    String? resolvedPhone = json['phone'] as String?;
    if (json['provider_profiles'] is Map) {
      final profile = json['provider_profiles'] as Map<String, dynamic>;
      resolvedAddress ??= profile['address'] as String?;
      resolvedPhone ??= profile['phone'] as String?;
    }

    return ServiceItemModel(
      id: json['id'] as String? ?? '',
      title: (json['name'] ?? json['title'] ?? '') as String,
      category: resolvedCategory,
      categoryId: json['category_id'] as String?,
      providerId: json['provider_id'] as String?,
      location: (json['location'] ?? '') as String,
      price: (json['price'] as num?) ?? 0,
      priceUnit: (json['currency'] ?? json['priceUnit'] ?? 'ر.ي') as String,
      rating: ((json['rating'] ?? 0.0) as num).toDouble(),
      reviewsCount: ((json['reviews_count'] ?? json['reviewsCount'] ?? 0) as num).toInt(),
      imageUrl: (json['image_url'] ?? json['imageUrl'] ?? '') as String,
      images: resolvedImages,
      description: (json['description'] ?? '') as String,
      capacity: resolvedCapacity,
      features: resolvedFeatures,
      occasions: resolvedOccasions,
      workingHours: resolvedWorkingHours,
      isFavorite: (json['isFavorite'] ?? false) as bool,
      phone: resolvedPhone,
      address: resolvedAddress,
      status: (json['status'] ?? 'active') as String,
    );
  }
}
