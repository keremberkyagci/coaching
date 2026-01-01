import '../models/user_model.dart';

enum Feature {
  createPlan,
  viewReports,
  manageUnlimitedStudents,
}

class AuthorizationService {
  bool canAccessFeature(Feature feature, UserModel user) {
    return true;
  }
}
