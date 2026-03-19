import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/plan_model.dart';
import '../../models/study_session_model.dart';
import '../../providers/providers.dart';

class TaskResultDialog extends ConsumerStatefulWidget {
  final PlanModel plan;

  const TaskResultDialog({
    super.key,
    required this.plan,
  });

  @override
  ConsumerState<TaskResultDialog> createState() => _TaskResultDialogState();
}

class _TaskResultDialogState extends ConsumerState<TaskResultDialog> {
  final _formKey = GlobalKey<FormState>();
  final _correctController = TextEditingController();
  final _wrongController = TextEditingController();
  final _blankController = TextEditingController();

  int _totalQuestions = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _calculateTotal();
    _correctController.addListener(_calculateTotal);
    _wrongController.addListener(_calculateTotal);
    _blankController.addListener(_calculateTotal);
  }

  void _calculateTotal() {
    final correct = int.tryParse(_correctController.text) ?? 0;
    final wrong = int.tryParse(_wrongController.text) ?? 0;
    final blank = int.tryParse(_blankController.text) ?? 0;
    
    setState(() {
      _totalQuestions = correct + wrong + blank;
    });
  }

  @override
  void dispose() {
    _correctController.removeListener(_calculateTotal);
    _wrongController.removeListener(_calculateTotal);
    _blankController.removeListener(_calculateTotal);
    _correctController.dispose();
    _wrongController.dispose();
    _blankController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      if (_totalQuestions == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Toplam soru sayısı 0 olamaz. Lütfen en az bir alan girin.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final firestore = ref.read(firebaseFirestoreProvider);
        
        // 1. StudySession oluştur
        final session = StudySessionModel(
          studentId: widget.plan.studentId,
          planId: widget.plan.id,
          subject: widget.plan.lessonName,
          topic: widget.plan.topicName,
          durationMinutes: 0,
          sessionDate: Timestamp.now(),
          sessionType: widget.plan.activityType,
          correct: int.tryParse(_correctController.text) ?? 0,
          wrong: int.tryParse(_wrongController.text) ?? 0,
          blank: int.tryParse(_blankController.text) ?? 0,
        );

        final sessionDoc = await firestore.collection("study_sessions").add(session.toMap());

        // 2. Plan update et (isCompleted = true ve sessionId ekle)
        await firestore.collection("plans").doc(widget.plan.id).update({
          'isCompleted': true,
          'sessionId': sessionDoc.id,
        });

        // 3. Provider'ları temizle/güncelle
        ref.invalidate(todaysPlansProvider(widget.plan.studentId));
        ref.invalidate(weekPlansProvider((studentId: widget.plan.studentId, weekDate: widget.plan.date)));

        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kaydedilirken hata oluştu: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.plan.lessonName} Sonuçlarını Gir'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNumberField(_correctController, 'Doğru Sayısı', Colors.green),
              const SizedBox(height: 12),
              _buildNumberField(_wrongController, 'Yanlış Sayısı', Colors.red),
              const SizedBox(height: 12),
              _buildNumberField(_blankController, 'Boş Sayısı', Colors.orange),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Toplam Soru:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '$_totalQuestions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 18,
                        color: _totalQuestions > 0 ? Colors.blue : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          child: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Kaydet'),
        ),
      ],
    );
  }

  Widget _buildNumberField(TextEditingController controller, String label, Color color) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      enabled: !_isLoading,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.edit, color: color),
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Zorunlu alan';
        final n = int.tryParse(value);
        if (n == null) return 'Sadece sayı girin';
        if (n < 0) return 'Negatif olamaz';
        return null;
      },
    );
  }
}
