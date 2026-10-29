import 'dart:math';

import 'package:draw_app/features/paywall/parental_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('questions use two-digit numbers and never go below zero', () {
    final random = Random(1);
    for (var i = 0; i < 2000; i++) {
      final q = ParentalQuestion.random(random);
      expect(q.a, inInclusiveRange(21, 79));
      expect(q.b, inInclusiveRange(11, 78));
      expect(q.answer, greaterThanOrEqualTo(0));
      expect(q.answer, q.plus ? q.a + q.b : q.a - q.b);
    }
  });

  test('only the right answer passes', () {
    final q = ParentalQuestion.random(Random(7));
    expect(q.check('${q.answer}'), isTrue);
    expect(q.check(' ${q.answer} '), isTrue);
    expect(q.check('${q.answer + 1}'), isFalse);
    expect(q.check(''), isFalse);
  });
}
