// ============================================================
// lib/main.dart — Uygulamanın giriş noktası
//
// Burada şu işlemler yapılır:
//   1. Firebase başlatılır (await Firebase.initializeApp)
//   2. Türkçe tarih formatı yüklenir (initializeDateFormatting)
//   3. Riverpod için ProviderScope sarmalayıcısı başlatılır
//   4. AuthWrapper, Firebase Auth durumunu dinleyerek kullanıcıyı
//      doğru ekrana yönlendirir:
//        - Koç   → CoachDashboardScreen
//        - Öğrenci → StudentDashboardScreen
//        - Giriş yapılmamış → LoginScreen
// ============================================================

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'models/user_model.dart';
import 'providers/providers.dart';
import 'screens/coach_dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/student_dashboard_screen.dart';

/// Uygulamanın başladığı nokta.
/// async olması zorunlu çünkü Firebase init beklenmesi gerekiyor.
void main() async {
  // Flutter engine tam hazır olmadan önce widget işlemlerine izin verilmez.
  WidgetsFlutterBinding.ensureInitialized();
  
  // HATA AYIKLAMA 1: Firebase'in başlatılmasını kontrol et
  try {
    debugPrint("--- 1. Firebase.initializeApp() ÇAĞRILIYOR ---");
    await Firebase.initializeApp(
      // firebase_options.dart dosyasından platform'a göre seçilen ayarlar
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("--- 2. Firebase.initializeApp() BAŞARILI ---");
  } catch (e) {
    debugPrint("--- HATA: Firebase.initializeApp() BAŞARISIZ: $e ---");
  }

  // Türkçe tarih ve saat formatlarını yükle (takvim, saat gösterimi vb.)
  await initializeDateFormatting('tr_TR', null);
  
  // HATA AYIKLAMA 2: runApp'in çağrıldığını kontrol et
  debugPrint("--- 3. runApp() ÇAĞRILIYOR ---");
  runApp(
    // ProviderScope: Riverpod provider'larının tüm uygulamayı kapsayabilmesi için zorunlu sarmalayıcı
    const ProviderScope(
      child: FocusApp(),
    ),
  );
}

/// Kök uygulama widget'ı.
/// MaterialApp burada tanımlanır, tema, dil ve rota ayarları yapılır.
class FocusApp extends StatelessWidget {
  const FocusApp({super.key});

  @override
  Widget build(BuildContext context) {
    // HATA AYIKLAMA 3: MaterialApp'in build edildiğini kontrol et
    debugPrint("--- 4. FocusApp (MaterialApp) BUILD EDİLİYOR ---");
    return MaterialApp(
      title: 'FOCUS Koçluk Sistemi',
      debugShowCheckedModeBanner: false, // Sağ üstteki "DEBUG" şeridini kaldırır
      home: const AuthWrapper(), // İlk ekran: Auth durumunu kontrol eder
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,   // Material widget'lar için Türkçe metinler
        GlobalWidgetsLocalizations.delegate,    // Temel widget metinleri için Türkçe
        GlobalCupertinoLocalizations.delegate,  // iOS tarzı widget'lar için Türkçe
      ],
      supportedLocales: const [
        Locale('tr', 'TR'), // Desteklenen dil: Türkçe
      ],
      locale: const Locale('tr', 'TR'), // Varsayılan dili Türkçe olarak ayarla
      theme: ThemeData(
        primarySwatch: Colors.grey,          // Ana renk paleti
        scaffoldBackgroundColor: Colors.white, // Tüm ekranların arka plan rengi
        // Google Fonts ile Nunito yazı tipini kullan
        textTheme: GoogleFonts.nunitoTextTheme(
          Theme.of(context).textTheme,
        ),
        // AppBar boyunca beyaz, gölgesiz ve siyah yazı/ikon kullan
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 20),
          iconTheme: IconThemeData(color: Colors.black),
        ),
      ),
    );
  }
}

/// Kimlik doğrulama durumuna göre hangi ekranın gösterileceğine karar veren widget.
/// currentUserProvider'ı dinleyerek kullanıcı oturumu anlık takip edilir.
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // HATA AYIKLAMA 4: AuthWrapper'ın build edildiğini ve provider'ı dinlediğini kontrol et
    debugPrint("--- 5. AuthWrapper BUILD EDİLİYOR ve currentUserProvider dinleniyor ---");
    // currentUserProvider: Firebase Auth + Firestore'daki kullanıcı verisini birleştirir
    final userAsyncValue = ref.watch(currentUserProvider);

    // HATA AYIKLAMA 5: Provider'ın durumunu kontrol et
    debugPrint("--- 6. currentUserProvider durumu: loading=${userAsyncValue.isLoading}, hasValue=${userAsyncValue.hasValue}, hasError=${userAsyncValue.hasError} ---");

    // AsyncValue.when() ile 3 olası durum yönetilir: data / loading / error
    return userAsyncValue.when(
      data: (userModel) {
        debugPrint("--- 7. DATA GELDİ: userModel null mı? ${userModel == null} ---");
        if (userModel != null) {
          // Kullanıcı tipine göre doğru dashboard'a yönlendir
          if (userModel.userType == UserType.coach) {
            return const CoachDashboardScreen(); // Koç paneline git
          }
          return const StudentDashboardScreen(); // Öğrenci paneline git
        }
        return const LoginScreen(); // Giriş yapılmamış → Login ekranı
      },
      loading: () {
        // Firebase Auth ve Firestore'dan veri henüz gelmediyse yükleniyor göster
        debugPrint("--- 7. LOADING... (Yükleniyor) ---");
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: Colors.black),
          ),
        );
      },
      error: (error, stackTrace) {
        // Hata durumunda güvenli bir şekilde login ekranına yönlendir
        debugPrint("--- 7. HATA OLUŞTU: $error ---");
        return const LoginScreen();
      },
    );
  }
}
