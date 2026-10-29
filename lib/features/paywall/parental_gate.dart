import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/ui/app_colors.dart';
import '../../core/ui/kid_ui.dart';

/// A sum or a subtraction with two-digit numbers: easy for a grown-up, hard
/// for a small child. Shown before anything that spends money.
class ParentalQuestion {
  ParentalQuestion._(this.a, this.b, this.plus);

  factory ParentalQuestion.random([Random? random]) {
    final r = random ?? Random();
    final plus = r.nextBool();
    final a = 21 + r.nextInt(59); // 21..79
    final b = 11 + r.nextInt(plus ? 19 : a - 11); // never negative
    return ParentalQuestion._(a, b, plus);
  }

  final int a;
  final int b;
  final bool plus;

  int get answer => plus ? a + b : a - b;
  String get text => '$a ${plus ? '+' : '−'} $b = ?';

  bool check(String input) => int.tryParse(input.trim()) == answer;
}

/// Asks a grown-up to solve a [ParentalQuestion]. True when answered right.
Future<bool> showParentalGate(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _ParentalGateDialog(),
  );
  return ok ?? false;
}

class _ParentalGateDialog extends StatefulWidget {
  const _ParentalGateDialog();

  @override
  State<_ParentalGateDialog> createState() => _ParentalGateDialogState();
}

class _ParentalGateDialogState extends State<_ParentalGateDialog> {
  var _question = ParentalQuestion.random();
  final _answer = TextEditingController();
  bool _wrong = false;

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  void _submit() {
    if (_question.check(_answer.text)) {
      Navigator.pop(context, true);
      return;
    }
    // A new question each time, so it cannot be guessed by trying numbers.
    setState(() {
      _wrong = true;
      _question = ParentalQuestion.random();
      _answer.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cream,
      title: Text('Ask a grown-up', style: kidText(22, weight: 700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('To continue, solve:', style: kidText(16, weight: 500)),
          const SizedBox(height: 10),
          Text(_question.text, style: kidText(32, weight: 700)),
          const SizedBox(height: 12),
          TextField(
            controller: _answer,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: kidText(24, weight: 700),
            decoration: const InputDecoration(hintText: 'Answer'),
            onSubmitted: (_) => _submit(),
          ),
          if (_wrong) ...[
            const SizedBox(height: 8),
            Text('Not quite. Try this one!',
                style: kidText(15, color: AppColors.danger)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Continue')),
      ],
    );
  }
}
