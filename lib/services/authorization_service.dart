// ============================================================
// lib/services/authorization_service.dart — Özellik yetki kontrolü
//
// Kullanıcının belirli bir özelliğe (Feature) erişip erişemeyeceğini kontrol eder.
// Şu an tüm featurelar için 'true' döner (yetki sistemi henüz geliştirilmemiş).
//
// Feature enum değerleri:
//   - createPlan                 : Plan oluşturma
//   - viewReports                : Raporları görüntüleme
//   - manageUnlimitedStudents    : Limitsiz öğrenci yönetimi (premium)
//
// Gelecekte SubscriptionTier kontrolü buraya eklenebilir:
//   if (user.subscriptionTier == SubscriptionTier.free && feature == ...) return false;
// ============================================================

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
