import '../../../home/data/models/category_model.dart';
import '../../data/models/smart_plan_models.dart';

abstract class SmartPlanningRepository {
  Future<List<CategoryModel>> getCategories();
  Future<SmartPlanResult> generatePlan(SmartPlanRequest request);
  Future<String> saveSelectedPackage({
    required SmartPlanRequest request,
    required PackageOption package,
    required List<CustomizableServiceItem> services,
    String? existingPackageId,
    String? customerId,
  });
}
