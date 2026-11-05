import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../home/data/models/category_model.dart';
import '../models/smart_plan_models.dart';
import '../../domain/repositories/smart_planning_repository.dart';

class SupabaseSmartPlanningRepository implements SmartPlanningRepository {
  final SupabaseClient _client;

  SupabaseSmartPlanningRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  @override
  Future<List<CategoryModel>> getCategories() async {
    final res = await _client
        .from('categories')
        .select('*')
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    return (res as List)
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SmartPlanResult> generatePlan(SmartPlanRequest request) async {
    final user = _client.auth.currentUser;
    final customerId = user?.id;

    // 1. استخراج معرفات التصنيفات المطلوبة من Supabase
    final categoriesRes = await _client
        .from('categories')
        .select('id, name')
        .eq('is_active', true);

    List<String> categoryIds = [];
    final allCats = categoriesRes as List;
    for (final cat in allCats) {
      final catId = cat['id'] as String;
      final catName = cat['name'] as String;
      if (request.requestedServices.isEmpty ||
          request.requestedServices.contains(catId) ||
          request.requestedServices
              .any((s) => catName.contains(s) || s.contains(catName))) {
        categoryIds.add(catId);
      }
    }

    if (categoryIds.isEmpty && allCats.isNotEmpty) {
      categoryIds = allCats.map((c) => c['id'] as String).toList();
    }

    // 2. استدعاء دالة قاعدة البيانات generate_smart_package في Supabase (Read-Only)
    final dynamic rpcResponse = await _client.rpc(
      'generate_smart_package',
      params: {
        'p_customer_id': customerId,
        'p_event_type': request.eventType,
        'p_budget': request.budget,
        'p_guest_count': request.guestsCount,
        'p_category_ids': categoryIds,
        'p_event_date': request.eventDate.toIso8601String().split('T')[0],
        'p_time_slot': 'evening',
      },
    );

    final Map<String, dynamic> data =
        rpcResponse is Map<String, dynamic> ? rpcResponse : {};

    if (data['success'] != true) {
      final msg = data['message'] as String? ??
          'تعذر إنشاء الباقة الذكية للميزانية أو التاريخ المحدد.';
      throw Exception(msg);
    }

    final currency = (data['currency'] as String?) ?? 'ر.ي';
    final rawPackages = data['packages'] as List? ?? [];

    if (rawPackages.isEmpty) {
      throw Exception('لم يتم العثور على خدمات متاحة كافية لتكوين الباقات.');
    }

    final List<PackageOption> packages = [];
    final Map<String, List<CustomizableServiceItem>> packageServicesMap = {};

    for (final pkg in rawPackages) {
      final pkgMap = pkg as Map<String, dynamic>;
      final pkgId = pkgMap['id'] as String;
      final pkgName = pkgMap['name'] as String;
      final pkgPrice = (pkgMap['price'] as num?) ?? 0;
      final pkgSavingsText = (pkgMap['savingsText'] as String?) ?? '';
      final isFeatured = (pkgMap['isFeatured'] as bool?) ?? false;
      final badge = pkgMap['badge'] as String?;
      final rawServices = pkgMap['services'] as List? ?? [];

      final List<CustomizableServiceItem> serviceItems = [];
      for (final s in rawServices) {
        final sMap = s as Map<String, dynamic>;
        serviceItems.add(
          CustomizableServiceItem(
            id: sMap['id'] as String,
            name: (sMap['name'] as String?) ?? 'خدمة مناسبات',
            vendor: (sMap['vendor'] as String?) ?? 'مقدم خدمة معتمد',
            details: (sMap['details'] as String?) ?? 'خدمة متكاملة للمناسبة',
            price: (sMap['price'] as num?) ?? 0,
            isIncluded: (sMap['isIncluded'] as bool?) ?? true,
            imageUrl: sMap['imageUrl'] as String?,
            categoryId: sMap['categoryId'] as String?,
          ),
        );
      }

      packageServicesMap[pkgId] = serviceItems;
      packages.add(
        PackageOption(
          id: pkgId,
          name: pkgName,
          price: pkgPrice,
          servicesCount: serviceItems.length,
          savingsText: pkgSavingsText,
          isFeatured: isFeatured,
          badge: badge,
          currency: currency,
        ),
      );
    }

    // نحدد الباقة الافتراضية للعرض في تفاصيل الميزانية
    final defaultPackage = packages.firstWhere(
      (p) => p.isFeatured,
      orElse: () => packages.first,
    );
    final defaultServices = packageServicesMap[defaultPackage.id] ?? [];

    final budgetItems = defaultServices
        .map((s) => BudgetItem(
              name: s.name,
              amount: s.price,
              iconName: 'celebration',
            ))
        .toList();

    return SmartPlanResult(
      request: request,
      estimatedTotal: defaultPackage.price,
      savingsNote: defaultPackage.savingsText.isNotEmpty
          ? defaultPackage.savingsText
          : 'تم توزيع الخطة بذكاء وفق الميزانية المحددة',
      budgetDistribution: budgetItems,
      packages: packages,
      customizableServices: defaultServices,
      packageServicesMap: packageServicesMap,
      currency: currency,
    );
  }

  @override
  Future<String> saveSelectedPackage({
    required SmartPlanRequest request,
    required PackageOption package,
    required List<CustomizableServiceItem> services,
    String? existingPackageId,
    String? customerId,
  }) async {
    final user = _client.auth.currentUser;
    final cId = customerId ?? user?.id;

    if (cId == null) {
      throw Exception('يجب تسجيل الدخول لحفظ الباقة المختارة مع تفاصيلها.');
    }

    final included = services.where((s) => s.isIncluded).toList();
    if (included.isEmpty) {
      throw Exception('يرجى تحديد خدمة واحدة على الأقل في الباقة.');
    }

    num total = 0;
    for (final s in included) {
      total += s.price;
    }
    final effectiveTotal = total > 0 ? total : package.price;

    // 1. محاولة استدعاء دالة RPC save_selected_package أولاً
    try {
      final dynamic rpcRes = await _client.rpc(
        'save_selected_package',
        params: {
          'p_customer_id': cId,
          'p_package_id':
              (existingPackageId != null && _isUuid(existingPackageId))
                  ? existingPackageId
                  : null,
          'p_name': package.name,
          'p_event_type': request.eventType,
          'p_budget': request.budget,
          'p_guest_count': request.guestsCount,
          'p_estimated_total': effectiveTotal,
          'p_currency': package.currency,
          'p_services': included
              .map((s) => {
                    'id': s.id,
                    'name': s.name,
                    'price': s.price,
                    'vendor': s.vendor,
                    'details': s.details,
                    'category_id': s.categoryId,
                  })
              .toList(),
        },
      );

      if (rpcRes is Map<String, dynamic> && rpcRes['success'] == true) {
        return rpcRes['package_id'] as String;
      }
    } catch (_) {
      // إذا لم تكن الدالة منشورة في السيرفر ننتقل مباشرة للتعامل مع الجداول
    }

    // 2. المسار الاحتياطي: إدراج أو تحديث الجداول packages و package_items مباشرة وفق سياسات RLS
    String packageId;
    final bool isExistingValid =
        existingPackageId != null && _isUuid(existingPackageId);

    if (isExistingValid) {
      await _client.from('packages').update({
        'name': package.name,
        'event_type': request.eventType,
        'budget': request.budget,
        'guest_count': request.guestsCount,
        'estimated_total': effectiveTotal,
        'currency': package.currency,
        'status': 'selected',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', existingPackageId).eq('customer_id', cId);

      packageId = existingPackageId;
      await _client
          .from('package_items')
          .delete()
          .eq('package_id', packageId);
    } else {
      final inserted = await _client.from('packages').insert({
        'customer_id': cId,
        'name': package.name,
        'event_type': request.eventType,
        'budget': request.budget,
        'guest_count': request.guestsCount,
        'estimated_total': effectiveTotal,
        'currency': package.currency,
        'status': 'selected',
        'generation_method': 'automatic',
      }).select('id').single();

      packageId = inserted['id'] as String;
    }

    // إدراج عناصر الباقة مع تفاصيل الأسعار
    final itemsToInsert = included.where((s) => _isUuid(s.id)).map((s) => {
          'package_id': packageId,
          'service_id': s.id,
          'quantity': 1,
          'unit_price': s.price,
          'subtotal': s.price,
        }).toList();

    if (itemsToInsert.isNotEmpty) {
      await _client.from('package_items').insert(itemsToInsert);
    }

    return packageId;
  }

  bool _isUuid(String str) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(str);
  }
}


