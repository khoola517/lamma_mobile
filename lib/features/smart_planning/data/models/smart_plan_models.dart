class SmartPlanRequest {
  final String eventType;
  final int guestsCount;
  final num budget;
  final String location;
  final DateTime eventDate;
  final List<String> requestedServices;

  const SmartPlanRequest({
    this.eventType = 'حفلة تخرج',
    this.guestsCount = 50,
    this.budget = 500000,
    this.location = 'المكلا',
    required this.eventDate,
    this.requestedServices = const [],
  });

  SmartPlanRequest copyWith({
    String? eventType,
    int? guestsCount,
    num? budget,
    String? location,
    DateTime? eventDate,
    List<String>? requestedServices,
  }) {
    return SmartPlanRequest(
      eventType: eventType ?? this.eventType,
      guestsCount: guestsCount ?? this.guestsCount,
      budget: budget ?? this.budget,
      location: location ?? this.location,
      eventDate: eventDate ?? this.eventDate,
      requestedServices: requestedServices ?? this.requestedServices,
    );
  }
}

class BudgetItem {
  final String name;
  final num amount;
  final String iconName;

  const BudgetItem({
    required this.name,
    required this.amount,
    required this.iconName,
  });
}

class PackageOption {
  final String id;
  final String name;
  final num price;
  final int servicesCount;
  final String savingsText;
  final bool isFeatured;
  final String? badge;
  final String currency;

  const PackageOption({
    required this.id,
    required this.name,
    required this.price,
    required this.servicesCount,
    required this.savingsText,
    this.isFeatured = false,
    this.badge,
    this.currency = 'ر.ي',
  });
}

class CustomizableServiceItem {
  final String id;
  final String name;
  final String vendor;
  final String details;
  final num price;
  final bool isIncluded;
  final String? imageUrl;
  final String? iconName;
  final String? categoryId;

  const CustomizableServiceItem({
    required this.id,
    required this.name,
    required this.vendor,
    required this.details,
    required this.price,
    this.isIncluded = true,
    this.imageUrl,
    this.iconName,
    this.categoryId,
  });

  CustomizableServiceItem copyWith({
    String? id,
    String? name,
    String? vendor,
    String? details,
    num? price,
    bool? isIncluded,
    String? imageUrl,
    String? iconName,
    String? categoryId,
  }) {
    return CustomizableServiceItem(
      id: id ?? this.id,
      name: name ?? this.name,
      vendor: vendor ?? this.vendor,
      details: details ?? this.details,
      price: price ?? this.price,
      isIncluded: isIncluded ?? this.isIncluded,
      imageUrl: imageUrl ?? this.imageUrl,
      iconName: iconName ?? this.iconName,
      categoryId: categoryId ?? this.categoryId,
    );
  }
}

class SmartPlanResult {
  final SmartPlanRequest request;
  final num estimatedTotal;
  final String savingsNote;
  final List<BudgetItem> budgetDistribution;
  final List<PackageOption> packages;
  final List<CustomizableServiceItem> customizableServices;
  final Map<String, List<CustomizableServiceItem>> packageServicesMap;
  final String currency;

  const SmartPlanResult({
    required this.request,
    required this.estimatedTotal,
    required this.savingsNote,
    required this.budgetDistribution,
    required this.packages,
    required this.customizableServices,
    this.packageServicesMap = const {},
    this.currency = 'ر.ي',
  });
}

