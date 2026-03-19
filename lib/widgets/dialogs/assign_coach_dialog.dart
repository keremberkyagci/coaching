import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../providers/providers.dart';

class AssignCoachDialog extends ConsumerStatefulWidget {
  final UserModel user;
  final bool isFromRegistration;

  const AssignCoachDialog({super.key, required this.user, this.isFromRegistration = false});

  @override
  ConsumerState<AssignCoachDialog> createState() => _AssignCoachDialogState();
}

class _AssignCoachDialogState extends ConsumerState<AssignCoachDialog> {
  final TextEditingController _coachIdController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _coachIdController.dispose();
    super.dispose();
  }

  Future<void> _assignCoach() async {
    final coachId = _coachIdController.text.trim();
    if (coachId.isEmpty) {
      setState(() => _errorText = 'Lütfen bir Koç ID girin.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref
          .read(userRepositoryProvider)
          .assignCoachToStudent(widget.user.id, coachId);
      ref.invalidate(currentUserProvider); // Güncel veriyi çek

      navigator.pop();
      messenger.showSnackBar(const SnackBar(
        content: Text('Koç ile başarıyla eşleşildi!'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Koç ile Eşleş'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Eşleşmek istediğiniz koçun Kullanıcı ID sini girin.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _coachIdController,
            decoration: InputDecoration(
              labelText: 'Koç ID',
              errorText: _errorText,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.isFromRegistration ? 'Hayır, tek çalışıyorum' : 'İptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _assignCoach,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Eşleş'),
        ),
      ],
    );
  }
}
