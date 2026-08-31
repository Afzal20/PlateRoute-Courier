import 'package:flutter_test/flutter_test.dart';
import 'package:courier/data/repositories/earnings_calculator.dart';

void main() {
  test('EarningsCalculator instantiates', () {
    const calc = EarningsCalculator();
    expect(calc, isNotNull);
  });
}
