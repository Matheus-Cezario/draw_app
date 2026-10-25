import 'package:draw_app/core/billing/plan_limits.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('free plan keeps up to $freeDrawingLimit drawings', () {
    expect(canCreateDrawing(isPremium: false, drawingCount: 0), isTrue);
    expect(canCreateDrawing(isPremium: false, drawingCount: 2), isTrue);
    expect(canCreateDrawing(isPremium: false, drawingCount: 3), isFalse);
    expect(canCreateDrawing(isPremium: false, drawingCount: 10), isFalse);
  });

  test('subscribers have no drawing limit', () {
    expect(canCreateDrawing(isPremium: true, drawingCount: 500), isTrue);
  });

  test('only subscribers export PNG', () {
    expect(canExportPng(isPremium: false), isFalse);
    expect(canExportPng(isPremium: true), isTrue);
  });
}
