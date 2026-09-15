import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dailydrop/main.dart';

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  testWidgets('TextileDrop App smoke test', (WidgetTester tester) async {
    // Provide a large enough test viewport for dashboard layout
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TextileDropApp());
    await tester.pumpAndSettle();

    expect(find.text('Surat Silk Mills'), findsWidgets);
    expect(find.text('Daily Drops'), findsWidgets);
    expect(find.text('Dashboard'), findsWidgets);
  });
}
