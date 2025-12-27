// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dineflow_manager/features/auth/screens/signup_screen.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build a minimal MaterialApp wrapping the dashboard.
    // (Avoids Firebase initialization from main.dart during tests.)
    await tester.pumpWidget(const MaterialApp(home: SignupScreen()));

    // Verify that the app builds without crashing.
    // You can check for a specific widget that exists in your initial screen.
    // For example, if your app starts with a Scaffold, we can find it.
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Create Your Account'), findsOneWidget);
  });
}
