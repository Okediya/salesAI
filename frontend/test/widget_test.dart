import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_ai_frontend/main.dart';

void main() {
  testWidgets('SalesAiApp smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SalesAiApp());
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(SalesAiApp), findsOneWidget);
  });
}
