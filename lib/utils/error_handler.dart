import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

class ErrorHandler {
  /// Firebase hatalarını veya genel hataları yakalayarak kullanıcı dostu bir mesaj gösterir.
  static void showSnackBar(BuildContext context, dynamic error) {
    if (!context.mounted) return;

    String errorMessage = 'Bilinmeyen bir hata oluştu.';

    if (error is FirebaseException) {
      switch (error.code) {
        case 'network-request-failed':
          errorMessage = 'İnternet bağlantınızı kontrol edin.';
          break;
        case 'user-not-found':
          errorMessage = 'Kullanıcı bulunamadı.';
          break;
        case 'wrong-password':
          errorMessage = 'Hatalı şifre girdiniz.';
          break;
        case 'email-already-in-use':
          errorMessage = 'Bu e-posta adresi zaten kullanımda.';
          break;
        default:
          errorMessage = 'Bir sorun oluştu: ${error.message}';
      }
    } else {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
