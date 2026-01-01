import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:focus_app_v2_final/models/plan_model.dart';
import 'package:focus_app_v2_final/providers/providers.dart';

class StudySessionInputScreen extends ConsumerStatefulWidget {
  const StudySessionInputScreen({super.key});

  @override
  ConsumerState<StudySessionInputScreen> createState() =>
      _StudySessionInputScreenState();
}

class _StudySessionInputScreenState
    extends ConsumerState<StudySessionInputScreen> {
  final _formKey = GlobalKey<FormState>();

  final List<String> _subjects = [
    'Türkçe',
    'Matematik',
    'Fizik',
    'Kimya',
    'Biyoloji',
    'Din Kültürü',
    'Coğrafya',
    'Tarih',
    'Felsefe'
  ];

  String? _selectedSubject;
  String _topic = '';
  int _durationMinutes = 60;
  bool _isLoading = false;

  void _saveSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hata: Kullanıcı oturumu bulunamadı.')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });

      final newPlan = PlanModel(
        studentId: user.uid,
        date: DateTime.now(),
        lessonName: _selectedSubject!,
        topicName: _topic,
        isCompleted: true,
        createdBy: 'student',
        createdAt: Timestamp.now(),
        activityType: ActivityType.study,
        lessonId: '', // Bu ekranda belirli bir lessonId olmadığı için boş bırakılabilir
        details: StudyDetails(durationMinutes: _durationMinutes),
      );

      try {
        await ref.read(planRepositoryProvider).addPlan(newPlan);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Çalışma kaydı başarıyla eklendi!')),
        );
        Navigator.of(context).pop();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kayıt hatası: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Yeni Çalışma Oturumu'),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildSubjectDropdown(),
              const SizedBox(height: 20),
              _buildTopicInput(),
              const SizedBox(height: 20),
              _buildDurationSlider(),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text('Kaydet ve Bitir',
                        style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Ders Seçin',
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black, width: 2)),
      ),
      initialValue: _selectedSubject,
      items: _subjects.map((String subject) {
        return DropdownMenuItem<String>(
          value: subject,
          child: Text(subject),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedSubject = newValue;
        });
      },
      validator: (value) => value == null ? 'Lütfen bir ders seçin.' : null,
      onSaved: (value) => _selectedSubject = value,
    );
  }

  Widget _buildTopicInput() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Çalışılan Konu Adı',
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black, width: 2)),
      ),
      onSaved: (value) => _topic = value!,
      validator: (value) =>
          value == null || value.isEmpty ? 'Lütfen bir konu adı girin.' : null,
    );
  }

  Widget _buildDurationSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Süre: $_durationMinutes Dakika (${(_durationMinutes / 60).toStringAsFixed(1)} Saat)',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Slider(
          value: _durationMinutes.toDouble(),
          min: 15,
          max: 240,
          divisions: (240 - 15) ~/ 15,
          activeColor: Colors.black,
          inactiveColor: Colors.grey.shade300,
          label: '$_durationMinutes dk',
          onChanged: (double value) {
            setState(() {
              _durationMinutes = value.toInt();
            });
          },
        ),
      ],
    );
  }
}
