
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sebutpro_my/main.dart';

void main() {
  testWidgets('SebutPro MY app loads successfully',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SebutProApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets);
  });
}
