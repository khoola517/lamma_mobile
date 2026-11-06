import '../../../../core/services/supabase_realtime_service.dart';
import '../../data/models/complaint_model.dart';
import '../../data/models/complaint_category_model.dart';

abstract class SupportRepository {
  Future<List<ComplaintCategoryModel>> getCategories();
  Future<List<ComplaintModel>> getMyComplaints();
  Future<void> submitComplaint({
    String? bookingId,
    String? categoryId,
    required String subject,
    required String category,
    required String description,
  });

  RealtimeSubscriptionToken subscribeToUserComplaints({
    required String userId,
    required void Function() onData,
    void Function()? onResync,
  });

  RealtimeSubscriptionToken subscribeToComplaintCategories({
    required void Function() onData,
    void Function()? onResync,
  });
}
