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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // HATA AYIKLAMA 1: Firebase'in başlatılmasını kontrol et
  try {
    debugPrint("--- 1. Firebase.initializeApp() ÇAĞRILIYOR ---");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("--- 2. Firebase.initializeApp() BAŞARILI ---");
  } catch (e) {
    debugPrint("--- HATA: Firebase.initializeApp() BAŞARISIZ: $e ---");
  }

  await initializeDateFormatting('tr_TR', null);
  
  // HATA AYIKLAMA 2: runApp'in çağrıldığını kontrol et
  debugPrint("--- 3. runApp() ÇAĞRILIYOR ---");
  runApp(
    const ProviderScope(
      child: FocusApp(),
    ),
  );
}

class FocusApp extends StatelessWidget {
  const FocusApp({super.key});

  @override
  Widget build(BuildContext context) {
    // HATA AYIKLAMA 3: MaterialApp'in build edildiğini kontrol et
    debugPrint("--- 4. FocusApp (MaterialApp) BUILD EDİLİYOR ---");
    return MaterialApp(
      title: 'FOCUS Koçluk Sistemi',
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
      // ... diğer MaterialApp ayarları
       localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
      ],
      locale: const Locale('tr', 'TR'),
      theme: ThemeData(
        primarySwatch: Colors.grey,
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.nunitoTextTheme(
          Theme.of(context).textTheme,
        ),
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

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // HATA AYIKLAMA 4: AuthWrapper'ın build edildiğini ve provider'ı dinlediğini kontrol et
    debugPrint("--- 5. AuthWrapper BUILD EDİLİYOR ve currentUserProvider dinleniyor ---");
    final userAsyncValue = ref.watch(currentUserProvider);

    // HATA AYIKLAMA 5: Provider'ın durumunu kontrol et
    debugPrint("--- 6. currentUserProvider durumu: loading=${userAsyncValue.isLoading}, hasValue=${userAsyncValue.hasValue}, hasError=${userAsyncValue.hasError} ---");

    return userAsyncValue.when(
      data: (userModel) {
        debugPrint("--- 7. DATA GELDİ: userModel null mı? ${userModel == null} ---");
        if (userModel != null) {
          if (userModel.userType == UserType.coach) {
            return const CoachDashboardScreen();
          }
          return const StudentDashboardScreen();
        }
        return const LoginScreen();
      },
      loading: () {
        debugPrint("--- 7. LOADING... (Yükleniyor) ---");
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: Colors.black),
          ),
        );
      },
      error: (error, stackTrace) {
        debugPrint("--- 7. HATA OLUŞTU: $error ---");
        return const LoginScreen();
      },
    );
  }
}
