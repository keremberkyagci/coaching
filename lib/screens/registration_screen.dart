// ============================================================
// lib/screens/registration_screen.dart — Kayıt ekranı
//
// Yeni kullanıcı (öğrenci veya koç) kaydı yapar.
//
// Akış:
//   1. Form doldurulur (ad, e-posta, şifre, userType, examType)
//   2. _signUp() → Firebase Auth ile hesap oluştur
//   3. UserModel oluştur ve Firestore 'users' koleksiyonuna kaydet
//   4. Öğrenci ise → AssignCoachDialog aç (koç seçimi)
//   5. Kayıt tamamlanınca root'a pop yap → AuthWrapper ilgili sayfaya yönlendirir
//
// Öğrenciye özgü alanlar: examType (YKS/LGS), coachId (opsiyonel)
// Koç kaydı için examType ve coachId gerekmez.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../providers/providers.dart';
import '../widgets/dialogs/assign_coach_dialog.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _coachIdController = TextEditingController();
  
  UserType _selectedUserType = UserType.student;
  String _selectedExamType = 'YKS';
  bool _isLoading = false;

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final authService = ref.read(authServiceProvider);
        final userRepository = ref.read(userRepositoryProvider);

        final userCredential = await authService.signUpWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        final newUser = UserModel(
          id: userCredential.user!.uid,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          userType: _selectedUserType,
          examType: _selectedUserType == UserType.student ? _selectedExamType : null,
          coachConnection: _selectedUserType == UserType.student && _coachIdController.text.trim().isNotEmpty
              ? {'coachId': _coachIdController.text.trim(), 'status': 'pending'}
              : null,
        );

        await userRepository.addUser(newUser);

        if (_selectedUserType == UserType.student && mounted) {
          // Firebase'deki işlemler bittikten sonra dialog açıyoruz
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AssignCoachDialog(
              user: newUser,
              isFromRegistration: true,
            ),
          );
          if (mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        } else if (mounted) {
          // Koç ise de direkt root'a dön ki AuthWrapper üzerinden Dashboard'a insin
          Navigator.of(context).popUntil((route) => route.isFirst);
        }

      } on FirebaseAuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kayıt Başarısız: ${e.message}')),
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _coachIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayıt Ol'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // ... Diğer UI elemanları
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Ad Soyad'),
                validator: (value) => (value == null || value.isEmpty) ? 'İsim alanı boş bırakılamaz.' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'E-posta'),
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
              const SizedBox(height: 15),
              DropdownButtonFormField<UserType>(
                value: _selectedUserType,
                decoration: const InputDecoration(labelText: 'Kullanıcı Tipi'),
                items: const [
                  DropdownMenuItem(
                    value: UserType.student,
                    child: Text('Öğrenci'),
                  ),
                  DropdownMenuItem(
                    value: UserType.coach,
                    child: Text('Koç'),
                  ),
                ],
                onChanged: (UserType? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedUserType = newValue;
                    });
                  }
                },
              ),
              if (_selectedUserType == UserType.student) ...[
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: _selectedExamType,
                  decoration: const InputDecoration(labelText: 'Hazırlanılan Sınav'),
                  items: const [
                    DropdownMenuItem(
                      value: 'YKS',
                      child: Text('YKS'),
                    ),
                    DropdownMenuItem(
                      value: 'LGS',
                      child: Text('LGS'),
                    ),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedExamType = newValue;
                      });
                    }
                  },
                ),
              ],
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Hesap Oluştur'),
              ),
               TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Zaten hesabın var mı? Giriş Yap.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
