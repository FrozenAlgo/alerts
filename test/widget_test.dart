import 'package:alerts/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppTheme colors are defined', () {
    expect(AppTheme.kPrimaryCyan, isNotNull);
    expect(AppTheme.kDarkSlate, isNotNull);
    expect(AppTheme.kGlassBase, isNotNull);
  });

  test('AppTheme glass decoration has border radius', () {
    expect(AppTheme.kGlassDecoration.borderRadius, isNotNull);
  });
}
