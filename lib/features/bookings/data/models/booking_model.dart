enum BookingStatus {
  pending,
  partiallyAccepted,
  confirmed,
  attentionNeeded,
  inProgress,
  completed,
  cancelled,
}

class BookingItemModel {
  final String id;
  final String bookingId;
  final String serviceId;
  final String? serviceName;
  final String? serviceImageUrl;
  final String? category;
  final String? vendorName;
  final int quantity;
  final num unitPrice;
  final num subtotal;
  final String itemStatus;
  final String? rejectionReason;

  const BookingItemModel({
    required this.id,
    required this.bookingId,
    required this.serviceId,
    this.serviceName,
    this.serviceImageUrl,
    this.category,
    this.vendorName,
    this.quantity = 1,
    required this.unitPrice,
    required this.subtotal,
    this.itemStatus = 'pending',
    this.rejectionReason,
  });

  factory BookingItemModel.fromJson(Map<String, dynamic> json) {
    String? sName;
    String? sImage;
    String? sCategory;
    String? sVendor;

    if (json['services'] is Map) {
      final s = json['services'] as Map;
      sName = s['name'] as String?;
      sImage = s['image_url'] as String? ?? s['imageUrl'] as String?;
      if (s['categories'] is Map && s['categories']['name'] != null) {
        sCategory = s['categories']['name'] as String?;
      }
      if (s['provider_profiles'] is Map &&
          s['provider_profiles']['business_name'] != null) {
        sVendor = s['provider_profiles']['business_name'] as String?;
      }
    }

    // Direct fallbacks if fields are flattened
    sName ??= json['service_name'] as String?;
    sImage ??= (json['service_image_url'] ??
        json['service_image'] ??
        json['image_url'] ??
        json['imageUrl']) as String?;

    return BookingItemModel(
      id: json['id'] as String? ?? '',
      bookingId: json['booking_id'] as String? ?? '',
      serviceId: json['service_id'] as String? ?? '',
      serviceName: sName,
      serviceImageUrl: sImage,
      category: sCategory,
      vendorName: sVendor,
      quantity: (json['quantity'] as int?) ?? 1,
      unitPrice: (json['unit_price'] as num?) ?? 0,
      subtotal: (json['subtotal'] as num?) ?? 0,
      itemStatus: (json['item_status'] as String?) ?? 'pending',
      rejectionReason: json['rejection_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'service_id': serviceId,
      if (serviceName != null) 'service_name': serviceName,
      if (serviceImageUrl != null) 'service_image_url': serviceImageUrl,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
      'item_status': itemStatus,
      'rejection_reason': rejectionReason,
    };
  }
}

class BookingModel {
  final String id;
  final String bookingCode;
  final String title;
  final String category;
  final String vendorName;
  final String imageUrl;
  final DateTime bookingDate;
  final String timeSlot;
  final BookingStatus status;
  final num price;
  final String priceUnit;
  final String? notes;
  final int progressStep;
  final List<BookingItemModel> items;

  const BookingModel({
    required this.id,
    required this.bookingCode,
    required this.title,
    required this.category,
    required this.vendorName,
    required this.imageUrl,
    required this.bookingDate,
    required this.timeSlot,
    required this.status,
    required this.price,
    this.priceUnit = 'ر.ي',
    this.notes,
    this.progressStep = 1,
    this.items = const [],
  });

  String get statusArabic {
    switch (status) {
      case BookingStatus.pending:
        return 'قيد الانتظار';
      case BookingStatus.partiallyAccepted:
        return 'مقبول جزئياً';
      case BookingStatus.confirmed:
        return 'مؤكد';
      case BookingStatus.attentionNeeded:
        return 'يتطلب إجراء';
      case BookingStatus.inProgress:
        return 'قيد التنفيذ';
      case BookingStatus.completed:
        return 'مكتمل';
      case BookingStatus.cancelled:
        return 'ملغي';
    }
  }

  static BookingStatus parseStatus(String? s) {
    switch (s) {
      case 'partially_accepted':
        return BookingStatus.partiallyAccepted;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'attention_needed':
        return BookingStatus.attentionNeeded;
      case 'in_progress':
        return BookingStatus.inProgress;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'pending':
      default:
        return BookingStatus.pending;
    }
  }

  static int calculateStep(BookingStatus s) {
    switch (s) {
      case BookingStatus.pending:
        return 1;
      case BookingStatus.partiallyAccepted:
        return 2;
      case BookingStatus.confirmed:
      case BookingStatus.inProgress:
        return 3;
      case BookingStatus.completed:
        return 4;
      case BookingStatus.attentionNeeded:
      case BookingStatus.cancelled:
        return 1;
    }
  }

  BookingModel copyWith({
    String? id,
    String? bookingCode,
    String? title,
    String? category,
    String? vendorName,
    String? imageUrl,
    DateTime? bookingDate,
    String? timeSlot,
    BookingStatus? status,
    num? price,
    String? priceUnit,
    String? notes,
    int? progressStep,
    List<BookingItemModel>? items,
  }) {
    return BookingModel(
      id: id ?? this.id,
      bookingCode: bookingCode ?? this.bookingCode,
      title: title ?? this.title,
      category: category ?? this.category,
      vendorName: vendorName ?? this.vendorName,
      imageUrl: imageUrl ?? this.imageUrl,
      bookingDate: bookingDate ?? this.bookingDate,
      timeSlot: timeSlot ?? this.timeSlot,
      status: status ?? this.status,
      price: price ?? this.price,
      priceUnit: priceUnit ?? this.priceUnit,
      notes: notes ?? this.notes,
      progressStep: progressStep ?? this.progressStep,
      items: items ?? this.items,
    );
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final parsedStatus = parseStatus(json['status'] as String?);

    List<BookingItemModel> parsedItems = [];
    if (json['booking_items'] is List) {
      parsedItems = (json['booking_items'] as List)
          .map((item) => BookingItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    // Default values
    String defaultTitle = (json['event_type'] ?? 'حجز مناسبة') as String;
    String defaultCategory = 'خدمة خاصة';
    String defaultVendor = 'منصة خِدمتي';
    String defaultImage =
        'https://images.unsplash.com/photo-1519741497674-611481863552?auto=format&fit=crop&w=600&q=80';

    // 1. Direct joined service (if bookings joined with services)
    if (json['services'] is Map) {
      final s = json['services'] as Map;
      if (s['name'] != null && (s['name'] as String).trim().isNotEmpty) {
        defaultTitle = (s['name'] as String).trim();
      }
      final sImg = s['image_url'] ?? s['imageUrl'];
      if (sImg is String && sImg.trim().isNotEmpty) {
        defaultImage = sImg.trim();
      }
      if (s['categories'] is Map && s['categories']['name'] != null) {
        defaultCategory = (s['categories']['name'] as String).trim();
      }
      if (s['provider_profiles'] is Map &&
          s['provider_profiles']['business_name'] != null) {
        defaultVendor = (s['provider_profiles']['business_name'] as String).trim();
      }
    }

    // 2. Extract service image, title, category, and vendor from parsed items
    if (parsedItems.isNotEmpty) {
      for (final it in parsedItems) {
        if (it.serviceName != null && it.serviceName!.trim().isNotEmpty) {
          defaultTitle = it.serviceName!.trim();
          break;
        }
      }
      for (final it in parsedItems) {
        if (it.serviceImageUrl != null && it.serviceImageUrl!.trim().isNotEmpty) {
          defaultImage = it.serviceImageUrl!.trim();
          break;
        }
      }
      for (final it in parsedItems) {
        if (it.category != null && it.category!.trim().isNotEmpty) {
          defaultCategory = it.category!.trim();
          break;
        }
      }
      for (final it in parsedItems) {
        if (it.vendorName != null && it.vendorName!.trim().isNotEmpty) {
          defaultVendor = it.vendorName!.trim();
          break;
        }
      }
    }

    // 3. Fallback to explicit image_url on root if present and not empty
    final explicitImage = json['image_url'] ?? json['imageUrl'] ?? json['service_image'];
    final finalImageUrl = (explicitImage is String && explicitImage.trim().isNotEmpty)
        ? explicitImage.trim()
        : defaultImage;

    return BookingModel(
      id: json['id'] as String? ?? '',
      bookingCode: json['booking_code'] as String? ?? 'KH-84920',
      title: (json['title'] ?? defaultTitle) as String,
      category: (json['category'] ?? defaultCategory) as String,
      vendorName: (json['vendor_name'] ?? defaultVendor) as String,
      imageUrl: finalImageUrl,
      bookingDate: json['event_date'] != null
          ? DateTime.tryParse(json['event_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      timeSlot: (json['time_slot'] ?? 'الفترة المسائية') as String,
      status: parsedStatus,
      price: (json['total_amount'] ?? json['price'] ?? 0) as num,
      priceUnit: (json['currency'] ?? json['priceUnit'] ?? 'ر.ي') as String,
      notes: json['notes'] as String?,
      progressStep: calculateStep(parsedStatus),
      items: parsedItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_code': bookingCode,
      'title': title,
      'category': category,
      'vendor_name': vendorName,
      'image_url': imageUrl,
      'event_date': bookingDate.toIso8601String().split('T')[0],
      'time_slot': timeSlot,
      'status': status.name,
      'total_amount': price,
      'notes': notes,
    };
  }
}
