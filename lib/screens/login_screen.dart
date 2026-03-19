// ============================================================
// lib/screens/login_screen.dart — Giriş ekranı
//
// Kullanıcının e-posta ve şifre ile sisteme giriş yapmasını sağlar.
// Giriş başarılıysa AuthWrapper otomatik olarak ilgili Dashboard'a yönlendirir.
//
// Bileşenler:
//   - _formKey          : Form doğrulama için GlobalKey
//   - _emailController  : E-posta giriş alanı
//   - _passwordController: Şifre giriş alanı
//   - _signIn()         : AuthService.signInWithEmailAndPassword() çağırır
//   - Kayıt linki       : RegistrationScreen'e yönlendirir
//
// Hata yönetimi: FirebaseAuthException yakalanır, SnackBar ile gösterilir.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/providers.dart';
import 'registration_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final authService = ref.read(authServiceProvider);
        await authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } on FirebaseAuthException catch (e) {
        final errorMessage = e.message ?? 'Bir hata oluştu.';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Giriş Başarısız: $errorMessage')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giriş Yap'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'FOCUS',
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'E-posta Adresi'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => (value == null || !value.contains('@')) ? 'Geçerli bir e-posta girin.' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Şifre'),
                  obscureText: true,
                  validator: (value) => (value == null || value.length < 6) ? 'Şifre en az 6 karakter olmalı.' : null,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  child: _isLoading ? const CircularProgressIndicator() : const Text('Giriş Yap'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                  ),
                  child: const Text('Hesabın yok mu? Kayıt ol.'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}