import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_counseling_app/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CampusCounsellingApp());

    // You can add some basic widget existence checks here
    expect(find.byType(MaterialApp), findsOneWidget);
    // Add more tests depending on your app's initial UI
  });
}
