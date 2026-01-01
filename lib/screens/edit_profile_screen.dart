import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../providers/providers.dart';

// 1. State Sınıfı
@immutable
class EditProfileState {
  const EditProfileState({this.isLoading = false, this.error, this.isSuccess = false});

  final bool isLoading;
  final String? error;
  final bool isSuccess;

  EditProfileState copyWith({bool? isLoading, String? error, bool? isSuccess}) {
    return EditProfileState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

// 2. StateNotifier
class EditProfileNotifier extends StateNotifier<EditProfileState> {
  EditProfileNotifier(this._ref) : super(const EditProfileState());

  final Ref _ref;

  Future<void> saveProfile({
    required String userId,
    required UserType userType,
    required Map<String, dynamic> formData,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final Map<String, dynamic> updatedData = {
        'name': formData['name'],
      };

      if (userType == UserType.student) {
        updatedData['highSchool'] = formData['highSchool'];
        updatedData['targetMajor'] = formData['targetMajor'];
        updatedData['targetRank'] = formData['targetRank'];
      } else if (userType == UserType.coach) {
        updatedData['biography'] = formData['biography'];
        updatedData['yearsOfCoaching'] = int.tryParse(formData['yearsOfCoaching']) ?? 0;
      }

      await _ref.read(userRepositoryProvider).updateUserData(userId, updatedData);
      
      // Kullanıcı verisini yeniden getirmek için currentUserProvider'ı geçersiz kıl
      _ref.invalidate(currentUserProvider);

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// 3. Provider
final editProfileNotifierProvider =
    StateNotifierProvider<EditProfileNotifier, EditProfileState>((ref) {
  return EditProfileNotifier(ref);
});


// 4. Widget
class EditProfileScreen extends ConsumerStatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  EditProfileScreenState createState() => EditProfileScreenState();
}

class EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _highSchoolController;
  late TextEditingController _targetMajorController;
  late TextEditingController _targetRankController;
  late TextEditingController _biographyController;
  late TextEditingController _yearsOfCoachingController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _highSchoolController =
        TextEditingController(text: widget.user.highSchool ?? '');
    _targetMajorController =
        TextEditingController(text: widget.user.targetMajor ?? '');
    _targetRankController =
        TextEditingController(text: widget.user.targetRank ?? '');
    _biographyController =
        TextEditingController(text: widget.user.biography ?? '');
    _yearsOfCoachingController =
        TextEditingController(text: widget.user.yearsOfCoaching?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _highSchoolController.dispose();
    _targetMajorController.dispose();
    _targetRankController.dispose();
    _biographyController.dispose();
    _yearsOfCoachingController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final formData = {
        'name': _nameController.text.trim(),
        'highSchool': _highSchoolController.text.trim(),
        'targetMajor': _targetMajorController.text.trim(),
        'targetRank': _targetRankController.text.trim(),
        'biography': _biographyController.text.trim(),
        'yearsOfCoaching': _yearsOfCoachingController.text.trim(),
      };

      ref.read(editProfileNotifierProvider.notifier).saveProfile(
            userId: widget.user.id,
            userType: widget.user.userType,
            formData: formData,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Provider'ı dinleyerek UI tepkilerini yönet
    ref.listen<EditProfileState>(editProfileNotifierProvider, (previous, next) {
      if (next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profil başarıyla güncellendi!'),
          backgroundColor: Colors.green,
        ));
        Navigator.of(context).pop();
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Bir hata oluştu: ${next.error}'),
          backgroundColor: Colors.red,
        ));
      }
    });

    final state = ref.watch(editProfileNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: state.isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration:
                          const InputDecoration(labelText: 'İsim Soyisim'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'İsim alanı boş bırakılamaz.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    if (widget.user.userType == UserType.student) ...[
                      TextFormField(
                        controller: _highSchoolController,
                        decoration: const InputDecoration(
                            labelText: 'Öğrenim Gördüğü Lise'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _targetMajorController,
                        decoration:
                            const InputDecoration(labelText: 'İstediği Bölüm'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _targetRankController,
                        decoration: const InputDecoration(
                            labelText: 'İstediği Sıralama'),
                      ),
                    ] else if (widget.user.userType == UserType.coach) ...[
                      TextFormField(
                        controller: _biographyController,
                        decoration: const InputDecoration(
                            labelText: 'Hakkında (Biyografi)'),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _yearsOfCoachingController,
                        decoration: const InputDecoration(
                            labelText: 'Koçluk Deneyimi (Yıl)'),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: state.isLoading ? null : _saveProfile,
                      child: const Text('Değişiklikleri Kaydet'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
